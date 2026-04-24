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

/// Singleton service that:
///  - Accepts SMS jobs from anywhere in the app
///  - Immediately tries to send if internet is available
///  - Otherwise persists the job and retries when connectivity is restored
class SmsQueueService {
  SmsQueueService._();
  static final SmsQueueService instance = SmsQueueService._();

  static const _kQueueKey = 'sms_pending_queue';
  static const _smsNumber = '6360139965';

  final List<PendingSms> _queue = [];
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isOnline = false;
  bool _isFlushing = false;

  // ── Initialization ────────────────────────────────────────────────────────

  Future<void> init() async {
    await _loadQueue();

    // Seed current connectivity state
    final results = await Connectivity().checkConnectivity();
    _isOnline = _hasInternet(results);

    // Listen for connectivity changes
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      final wasOnline = _isOnline;
      _isOnline = _hasInternet(results);
      debugPrint('[SmsQueue] Connectivity changed → online=$_isOnline');

      if (!wasOnline && _isOnline) {
        // Just came back online — flush the queue
        await flushQueue();
      }
    });

    // Flush immediately if already online and queue has items
    if (_isOnline && _queue.isNotEmpty) {
      await flushQueue();
    }
  }

  void dispose() {
    _connectivitySub?.cancel();
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Enqueue an SMS. Tries to send immediately if online; otherwise saves for later.
  Future<void> enqueue({required String body}) async {
    final item = PendingSms(phoneNumber: _smsNumber, body: body);

    if (_isOnline) {
      final sent = await _trySend(item);
      if (!sent) {
        // Failed despite being online — add to queue for retry
        _queue.add(item);
        await _saveQueue();
      }
    } else {
      debugPrint('[SmsQueue] Offline — queuing SMS for later: $body');
      _queue.add(item);
      await _saveQueue();
    }
  }

  /// Current number of pending SMS messages.
  int get pendingCount => _queue.length;

  // ── Internal helpers ──────────────────────────────────────────────────────

  bool _hasInternet(List<ConnectivityResult> results) =>
      results.any((r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet);

  /// Drain the queue, sending every pending SMS.
  Future<void> flushQueue() async {
    if (_isFlushing || _queue.isEmpty) return;
    _isFlushing = true;
    debugPrint('[SmsQueue] Flushing ${_queue.length} pending SMS(es)...');

    final failed = <PendingSms>[];
    for (final item in List.from(_queue)) {
      final sent = await _trySend(item);
      if (!sent) failed.add(item);
    }

    _queue
      ..clear()
      ..addAll(failed);
    await _saveQueue();
    _isFlushing = false;

    debugPrint('[SmsQueue] Flush complete. Remaining: ${_queue.length}');
  }

  /// Attempt to send a single SMS. Returns true on success.
  Future<bool> _trySend(PendingSms item) async {
    try {
      var status = await Permission.sms.status;
      if (!status.isGranted) {
        status = await Permission.sms.request();
      }
      if (!status.isGranted) {
        debugPrint('[SmsQueue] SMS permission denied');
        return false;
      }

      final result = await BackgroundSms.sendMessage(
        phoneNumber: item.phoneNumber,
        message: item.body,
      );

      if (result == SmsStatus.sent) {
        debugPrint('[SmsQueue] SMS sent ✓  → ${item.body}');
        return true;
      } else {
        debugPrint('[SmsQueue] SMS delivery failed for: ${item.body}');
        return false;
      }
    } catch (e) {
      debugPrint('[SmsQueue] Error sending SMS: $e');
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
