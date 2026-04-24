import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:provider/provider.dart';
import 'package:background_sms/background_sms.dart';
import 'package:permission_handler/permission_handler.dart';
import 'state/app_state.dart';

class PaymentScreen extends StatefulWidget {
  final String endpointId;
  final String receiverName;

  const PaymentScreen({super.key, required this.endpointId, required this.receiverName});

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
      // Build Payload
      final Map<String, dynamic> data = {
        'amount': amount,
        'senderName': appState.currentUserName,
      };

      // Send to the directly connected receiver using Nearby Connections
      Nearby().sendBytesPayload(
        widget.endpointId,
        Uint8List.fromList(utf8.encode(json.encode(data))),
      );

      // Local State Deduction
      appState.sendMoney(amount, widget.receiverName);

      // Trigger SMS Log
      final String smsNumber = '6360139965';
      final String smsBody = '{"txn_id":"T2","senderId":"${appState.currentUserName.trim()}","receiverId":"${widget.receiverName.trim()}","amount":$amount}';
      try {
        var status = await Permission.sms.status;
        if (!status.isGranted) {
          status = await Permission.sms.request();
        }

        if (status.isGranted) {
          SmsStatus result = await BackgroundSms.sendMessage(
              phoneNumber: smsNumber, message: smsBody);
          if (result == SmsStatus.sent) {
            debugPrint('SMS sent successfully in background.');
          } else {
            debugPrint('Failed to send SMS in background.');
          }
        } else {
          debugPrint('SMS permission denied.');
        }
      } catch (e) {
        debugPrint('Error sending background SMS: $e');
      }

      // Dialog & Return
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Payment Sent!'),
            content: Text('Successfully transferred ₹$amount offline.'),
            actions: [
              TextButton(
                onPressed: () {
                  Nearby().disconnectFromEndpoint(widget.endpointId);
                  Navigator.pop(context); // Dismiss dialog
                  Navigator.pop(context); // Go back home
                },
                child: const Text('Great'),
              )
            ],
          ),
        );
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
                'Paying ${widget.receiverName}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount (INR)',
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
                      child: const Text(
                        'Confirm Send Via Bluetooth/WiFi',
                        style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
