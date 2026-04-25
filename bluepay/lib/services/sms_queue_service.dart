import 'dart:async';
import 'dart:convert';
import 'package:background_sms/background_sms.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A single SMS transaction waiting to be sent.
class PendingSms {
  final String phoneNumber;
  final String body;

  PendingSms({required this.phoneNumber, required this.body});

  Map<String, dynamic> toJson() => {'phoneNumber': phoneNumber, 'body': body};

  factory PendingSms.fromJson(Map<String, dynamic> json) => PendingSms(
        phoneNumber: json['phoneNumber'] as String,
        body: json['body'] as String,
      );
}

/// Singleton SMS queue that correctly handles airplane mode.
///
/// WHY connectivity_plus alone is wrong:
///   - connectivity_plus reports ConnectivityResult.none when data is OFF but
///     GSM radio is ON (airplane mode OFF). SMS doesn't need mobile data.
///   - It only goes to 'mobile' when internet data is active.
///
/// FIX: Use a native method channel to read Settings.Global.AIRPLANE_MODE_ON.
///   - Airplane mode ON  → cannot send SMS (radio off) → queue it
///   - Airplane mode OFF → attempt SMS immediately (data doesn't matter)
///
/// Auto-flush triggers:
///   1. connectivity_plus: none → any transition (covers airplane off + data on)
///   2. 30-second periodic timer (safety net for data-off + GSM-on case)
class SmsQueueService extends ChangeNotifier {
  SmsQueueService._();
  static final SmsQueueService instance = SmsQueueService._();

  static const _kQueueKey  = 'sms_pending_queue';
  static const _smsNumber  = '6360139965';
  static const _systemChannel = MethodChannel('com.example.bluepay/system');

  final List<PendingSms> _queue = [];
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _retryTimer;
  bool _isAirplaneMode = false;
  bool _isFlushing     = false;

  // ── Public state ──────────────────────────────────────────────────────────

  /// True when the GSM radio is active (airplane mode is OFF).
  bool get hasSignal    => !_isAirplaneMode;

  /// Alias kept for UI compatibility.
  bool get isOnline     => !_isAirplaneMode;

  /// Number of SMS messages currently queued.
  int  get pendingCount => _queue.length;

  // ── Initialization ────────────────────────────────────────────────────────

  Future<void> init() async {
    await _loadQueue();

    _isAirplaneMode = await _checkAirplaneMode();
    debugPrint('[SmsQueue] Init — airplaneMode=$_isAirplaneMode  queued=${_queue.length}');

    // Listen for connectivity changes. When the status changes from none →
    // anything, airplane mode was likely just turned off. Re-check and flush.
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      final prev = _isAirplaneMode;
      _isAirplaneMode = await _checkAirplaneMode();

      debugPrint('[SmsQueue] Connectivity event → airplaneMode=$_isAirplaneMode '
          '(was $prev)  queued=${_queue.length}');
      notifyListeners();

      // Airplane mode turned off → flush queued messages
      if (prev && !_isAirplaneMode && _queue.isNotEmpty) {
        debugPrint('[SmsQueue] Airplane mode OFF — flushing ${_queue.length} queued SMS(es)');
        await flushQueue();
      }
    });

    // Periodic safety-net every 30 s:
    // Handles the case where airplane mode is already off at startup but
    // connectivity_plus doesn't fire a change event.
    _retryTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (_queue.isNotEmpty) {
        _isAirplaneMode = await _checkAirplaneMode();
        notifyListeners();
        if (!_isAirplaneMode) {
          debugPrint('[SmsQueue] Periodic retry — airplane off, flushing ${_queue.length}');
          await flushQueue();
        }
      }
    });

    // Flush on startup if airplane mode is already off
    if (!_isAirplaneMode && _queue.isNotEmpty) {
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
  /// - Airplane mode ON  → add to persistent queue without attempting send
  /// - Airplane mode OFF → attempt immediate send; queue on failure
  Future<void> enqueue({required String body}) async {
    final item = PendingSms(phoneNumber: _smsNumber, body: body);

    // Always re-check the actual airplane mode state right now
    _isAirplaneMode = await _checkAirplaneMode();
    notifyListeners();

    if (_isAirplaneMode) {
      debugPrint('[SmsQueue] Airplane mode ON — queuing SMS: $body');
      _queue.add(item);
      await _saveQueue();
      notifyListeners();
      return;
    }

    // GSM radio is on — try to send right now
    final sent = await _trySend(item);
    if (!sent) {
      debugPrint('[SmsQueue] Send failed — queuing for retry: $body');
      _queue.add(item);
      await _saveQueue();
      notifyListeners();
    }
  }

  /// Manually flush the queue (e.g. from a "Retry" button).
  Future<void> flushQueue() async {
    if (_isFlushing || _queue.isEmpty) return;

    _isAirplaneMode = await _checkAirplaneMode();
    if (_isAirplaneMode) {
      debugPrint('[SmsQueue] Flush skipped — still in airplane mode');
      notifyListeners();
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

  /// Read Settings.Global.AIRPLANE_MODE_ON via the native method channel.
  /// Falls back to false (assume not in airplane mode) on any error so that
  /// sending is not permanently blocked if the channel is unavailable.
  Future<bool> _checkAirplaneMode() async {
    try {
      final bool isOn =
          await _systemChannel.invokeMethod<bool>('isAirplaneModeOn') ?? false;
      return isOn;
    } catch (e) {
      debugPrint('[SmsQueue] Could not check airplane mode: $e');
      return false; // fail open — let send attempt happen
    }
  }

  /// Attempt to physically send one SMS via BackgroundSms.
  Future<bool> _trySend(PendingSms item) async {
    try {
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

      if (result == SmsStatus.sent) {
        debugPrint('[SmsQueue] SMS sent ✓ → ${item.body}');
        return true;
      } else {
        debugPrint('[SmsQueue] SMS send returned: $result for: ${item.body}');
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
