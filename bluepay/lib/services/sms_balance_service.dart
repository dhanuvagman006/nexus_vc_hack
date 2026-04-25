import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Listens for incoming BPAY balance-update SMS messages sent by the relay app
/// and exposes the parsed result as a stream.
///
/// SMS format sent by relay app:
///   BPAY S {txn_id} {amount} {newBalance}   ← sent to the SENDER
///   BPAY R {txn_id} {amount} {newBalance}   ← sent to the RECEIVER
///
/// Example: "BPAY S TXN17430001234 500.00 850.00"
///
/// Usage:
///   SmsBalanceService.instance.balanceUpdates.listen((update) {
///     appState.syncBalance(update.newBalance);
///   });
class BpayBalanceUpdate {
  final String  type;       // 'S' = sender confirmation, 'R' = receiver credit
  final String  txnId;
  final double  amount;
  final double  newBalance;

  const BpayBalanceUpdate({
    required this.type,
    required this.txnId,
    required this.amount,
    required this.newBalance,
  });

  @override
  String toString() =>
      'BpayBalanceUpdate(type=$type txn=$txnId amt=$amount bal=$newBalance)';
}

class SmsBalanceService {
  SmsBalanceService._();
  static final SmsBalanceService instance = SmsBalanceService._();

  static const _eventChannel =
      EventChannel('com.example.bluepay/sms_events');

  StreamSubscription<dynamic>? _sub;
  final _controller = StreamController<BpayBalanceUpdate>.broadcast();

  /// Stream of parsed balance updates. Listen to this in your widget tree.
  Stream<BpayBalanceUpdate> get balanceUpdates => _controller.stream;

  /// Call once from main() to start listening for BPAY SMS events.
  void init() {
    _sub = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        final msg = event as String;
        debugPrint('[SmsBalanceService] Received event: $msg');
        final update = _parse(msg);
        if (update != null) {
          debugPrint('[SmsBalanceService] Parsed: $update');
          _controller.add(update);
        }
      },
      onError: (dynamic e) {
        debugPrint('[SmsBalanceService] EventChannel error: $e');
      },
    );
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }

  /// Parse "BPAY S TXN17430001234 500.00 850.00"
  ///                ↑type  ↑txnId    ↑amount ↑newBalance
  BpayBalanceUpdate? _parse(String msg) {
    try {
      final parts = msg.trim().split(RegExp(r'\s+'));
      if (parts.length < 5 || parts[0] != 'BPAY') return null;

      final type       = parts[1];  // S or R
      final txnId      = parts[2];
      final amount     = double.parse(parts[3]);
      final newBalance = double.parse(parts[4]);

      if (type != 'S' && type != 'R') return null;

      return BpayBalanceUpdate(
        type: type,
        txnId: txnId,
        amount: amount,
        newBalance: newBalance,
      );
    } catch (e) {
      debugPrint('[SmsBalanceService] Parse error for "$msg": $e');
      return null;
    }
  }
}
