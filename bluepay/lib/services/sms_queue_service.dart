import 'dart:async';
import 'dart:convert';
import 'package:background_sms/background_sms.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A single SMS transaction waiting to be sent.
class PendingSms {
  final String phoneNumber;
  final String body;

  PendingSms({required this.phoneNumber, required this.body});

  Map<String, dynamic> toJson() => {
        'phoneNumber': phoneNumber,
        'body': body,
      };

  factory PendingSms.fromJson(Map<String, dynamic> json) => PendingSms(
        phoneNumber: json['phoneNumber'] as String,
        body: json['body'] as String,
      );
}

/// Singleton SMS queue that correctly handles airplane mode.
///
/// KEY INSIGHT: BackgroundSms.sendMessage() returns SmsStatus.sent even when
/// airplane mode is ON — Android accepts the SMS into its own outbox and
/// reports "sent" to the app. We CANNOT trust that return value.
///
/// Strategy:
///  1. Before every send attempt, check connectivity_plus.
///  2. If result is [none] (airplane mode / no radio) → skip send, add to queue.
///  3. If any signal is present → attempt the actual SMS send.
///  4. On connectivity change from none→signal, auto-flush the queue.
///  5. 30-second periodic timer as a safety net.
class SmsQueueService extends ChangeNotifier {
  SmsQueueService._();
  static final SmsQueueService instance = SmsQueueService._();

  static const _kQueueKey  = 'sms_pending_queue';
  static const _smsNumber  = '6360139965';

  final List<PendingSms> _queue = [];
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _retryTimer;
  bool _hasSignal  = false;  // any non-none connectivity
  bool _isFlushing = false;

  // ── Public state ──────────────────────────────────────────────────────────

  /// True when device is NOT in airplane mode (any radio signal detected).
  bool get hasSignal   => _hasSignal;

  /// True when device has internet (mobile data or WiFi).
  bool get isOnline    => _hasSignal; // kept for UI compatibility

  /// Number of SMS messages waiting to be sent.
  int  get pendingCount => _queue.length;

  // ── Initialization ────────────────────────────────────────────────────────

  Future<void> init() async {
    await _loadQueue();

    // Bootstrap current connectivity state
    final results = await Connectivity().checkConnectivity();
    _hasSignal = _anySignal(results);
    debugPrint('[SmsQueue] Init — signal=$_hasSignal  queued=${_queue.length}');

    // Listen for connectivity changes
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      final hadSignal = _hasSignal;
      _hasSignal = _anySignal(results);

      debugPrint('[SmsQueue] Connectivity changed → signal=$_hasSignal  '
          '(was $hadSignal)  queued=${_queue.length}');
      notifyListeners();

      // Gained signal → flush queue immediately
      if (!hadSignal && _hasSignal && _queue.isNotEmpty) {
        debugPrint('[SmsQueue] Signal regained — flushing ${_queue.length} queued SMS(es)');
        await flushQueue();
      }
    });

    // Periodic safety-net: retry every 30 s in case connectivity_plus
    // misses a state change (e.g. data-off but GSM radio on)
    _retryTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (_queue.isNotEmpty && _hasSignal) {
        debugPrint('[SmsQueue] Periodic retry — ${_queue.length} pending');
        await flushQueue();
      }
    });

    // Flush immediately if we already have signal and items in queue
    if (_hasSignal && _queue.isNotEmpty) {
      await flushQueue();
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Enqueue an SMS.
  ///
  /// - If we have NO signal (airplane mode) → adds directly to queue without
  ///   attempting a send. The OS-level SMS queue is unreliable when offline.
  /// - If we DO have signal → attempts to send immediately. On failure,
  ///   falls back to the persistent queue.
  Future<void> enqueue({required String body}) async {
    final item = PendingSms(phoneNumber: _smsNumber, body: body);

    // Re-check connectivity right now — state may have changed since init
    final results = await Connectivity().checkConnectivity();
    _hasSignal = _anySignal(results);

    if (!_hasSignal) {
      // Airplane mode (or fully offline) — go straight to queue
      debugPrint('[SmsQueue] No signal (airplane mode?) — queuing SMS: $body');
      _queue.add(item);
      await _saveQueue();
      notifyListeners();
      return;
    }

    // We have signal — try to send now
    final sent = await _trySend(item);
    if (!sent) {
      debugPrint('[SmsQueue] Send failed — queuing for retry: $body');
      _queue.add(item);
      await _saveQueue();
      notifyListeners();
    }
  }

  /// Manually trigger a queue flush (e.g. from a "Retry" button).
  Future<void> flushQueue() async {
    if (_isFlushing || _queue.isEmpty) return;

    // Check connectivity right now before flushing
    final results = await Connectivity().checkConnectivity();
    _hasSignal = _anySignal(results);

    if (!_hasSignal) {
      debugPrint('[SmsQueue] Flush requested but no signal — aborting');
      return;
    }

    _isFlushing = true;
    debugPrint('[SmsQueue] Flushing ${_queue.length} pending SMS(es)...');

    final failed = <PendingSms>[];
    for (final item in List<PendingSms>.from(_queue)) {
      final sent = await _trySend(item);
      if (!sent) failed.add(item);
    }

    _queue
      ..clear()
      ..addAll(failed);
    await _saveQueue();
    _isFlushing = false;
    notifyListeners();

    debugPrint('[SmsQueue] Flush done. Remaining: ${_queue.length}');
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  /// True when at least one result is NOT none/bluetooth.
  bool _anySignal(List<ConnectivityResult> results) => results.any(
        (r) => r != ConnectivityResult.none && r != ConnectivityResult.bluetooth,
      );

  /// Attempt to physically send one SMS via BackgroundSms.
  Future<bool> _trySend(PendingSms item) async {
    try {
      // Ensure SMS permission
      var status = await Permission.sms.status;
      if (!status.isGranted) status = await Permission.sms.request();
      if (!status.isGranted) {
        debugPrint('[SmsQueue] SMS permission denied');
        return false;
      }

      final result = await BackgroundSms.sendMessage(
        phoneNumber: item.phoneNumber,
        message: item.body,
      );

      // NOTE: result == SmsStatus.sent does NOT mean delivered when offline.
      // We only reach here when _hasSignal == true, so we can trust the result.
      if (result == SmsStatus.sent) {
        debugPrint('[SmsQueue] SMS sent ✓ → ${item.body}');
        return true;
      } else {
        debugPrint('[SmsQueue] SMS send returned non-sent status: $result');
        return false;
      }
    } catch (e) {
      debugPrint('[SmsQueue] Exception sending SMS: $e');
      return false;
    }
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  Future<void> _loadQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kQueueKey);
      if (raw != null) {
        final List<dynamic> decoded = jsonDecode(raw);
        _queue.addAll(
          decoded.map((e) => PendingSms.fromJson(e as Map<String, dynamic>)),
        );
        debugPrint('[SmsQueue] Loaded ${_queue.length} pending SMS(es) from disk');
      }
    } catch (e) {
      debugPrint('[SmsQueue] Failed to load queue: $e');
    }
  }

  Future<void> _saveQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kQueueKey,
        jsonEncode(_queue.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('[SmsQueue] Failed to save queue: $e');
    }
  }
}
