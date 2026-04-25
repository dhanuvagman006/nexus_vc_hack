import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'services/sms_queue_service.dart';
import 'success_animation.dart';
import 'l10n/app_localizations.dart';

class PaymentScreen extends StatefulWidget {
  final String endpointId;
  final String receiverPhone;   // receiver's phone number (from QR)
  final String receiverName;    // receiver's display name (from QR, may equal phone if name unknown)

  const PaymentScreen({super.key, required this.endpointId, required this.receiverPhone, this.receiverName = ''});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _amountController = TextEditingController();
  bool _isSending = false;

  void _sendMoney() async {
    final double? amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid amount')));
      return;
    }

    final appState = Provider.of<AppState>(context, listen: false);

    if (appState.balance < amount) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient balance')));
      return;
    }

    setState(() => _isSending = true);

    try {
      // Generate ID early so both parties use the exact same one
      final String txnId = 'TXN${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(0xFFFF).toRadixString(16).toUpperCase().padLeft(4, '0')}';

      // Build Payload with txn_id
      final Map<String, dynamic> data = {
        'txn_id': txnId,
        'amount': amount,
        'senderPhone': appState.userPhone,   // used as senderId on receive side
        'senderName': appState.currentUserName,
      };

      // Send to the directly connected receiver using Nearby Connections
      Nearby().sendBytesPayload(
        widget.endpointId,
        Uint8List.fromList(utf8.encode(json.encode(data))),
      );

      // Local State Deduction
      appState.sendMoney(amount, widget.receiverPhone, txnId: txnId);

      // Enqueue SMS — sent immediately if online, persisted if offline
      final String smsBody = '{"txn_id":"$txnId","senderId":"${appState.userPhone.trim()}","senderName":"${appState.currentUserName.trim()}","receiverId":"${widget.receiverPhone.trim()}","amount":$amount}';
      await SmsQueueService.instance.enqueue(body: smsBody);

      // Dialog & Return
      if (mounted) {
        showSuccessAnimation(context, () {
          Nearby().disconnectFromEndpoint(widget.endpointId);
          Navigator.pop(context); // Dismiss animation overlay
          Navigator.pop(context); // Go back home
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Transmission failed! Error: $e')));
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Money Offline')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.person, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
              '${context.l10n.paying} ${widget.receiverName.isNotEmpty ? widget.receiverName : widget.receiverPhone}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: context.l10n.amount,
                  prefixText: '₹ ',
                  prefixStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              _isSending
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _sendMoney,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        context.l10n.send,
                        style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
