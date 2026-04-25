import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'state/app_state.dart';
import 'services/sms_queue_service.dart';
import 'success_animation.dart';
import 'l10n/app_localizations.dart';

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  final Strategy strategy = Strategy.P2P_CLUSTER;
  bool isAdvertising = false;
  String connectionStatus = 'Waiting for connections...';

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndStartAdvertising();
  }

  Future<void> _requestPermissionsAndStartAdvertising() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
      Permission.nearbyWifiDevices,
    ].request();

    if (statuses.values.any((status) => status.isDenied || status.isPermanentlyDenied)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissions required to receive money offline.')),
        );
      }
      return;
    }

    _startAdvertising();
  }

  Future<void> _startAdvertising() async {
    final appState = Provider.of<AppState>(context, listen: false);
    try {
      bool? isAdv = await Nearby().startAdvertising(
        appState.userPhone.isNotEmpty ? appState.userPhone : appState.currentUserName, // Advertise with phone number as the identity
        strategy,
        onConnectionInitiated: (String id, ConnectionInfo info) {
          if (!mounted) return;
          setState(() => connectionStatus = 'Connection requested from ${info.endpointName}...');
          Nearby().acceptConnection(
            id,
            onPayLoadRecieved: (String endpointId, Payload payload) {
              if (payload.type == PayloadType.BYTES && payload.bytes != null) {
                _handleIncomingPayment(String.fromCharCodes(payload.bytes!));
                Nearby().disconnectFromEndpoint(id);
              }
            },
            onPayloadTransferUpdate: (String endpointId, PayloadTransferUpdate payloadTransferUpdate) {},
          );
        },
        onConnectionResult: (String id, Status status) {
          if (!mounted) return;
          if (status == Status.CONNECTED) {
            setState(() => connectionStatus = 'Connected securely! Waiting for funds...');
          }
        },
        onDisconnected: (String id) {},
        serviceId: "com.example.bluepay",
      );

      if (isAdv ?? false) {
        setState(() => isAdvertising = true);
      }
    } catch (e) {
      if (mounted) {
        // Typically happens if already advertising etc
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not advertise: $e')));
      }
    }
  }

  void _handleIncomingPayment(String jsonString) async {
    if (!mounted) return;
    try {
      final decoded = json.decode(jsonString);
      final double? amount = double.tryParse(decoded['amount']?.toString() ?? '');
      final String senderId = decoded['senderPhone'] ?? 'Unknown';
      final String senderName = decoded['senderName'] ?? senderId;
      final String? txnId = decoded['txn_id'];

      if (amount != null && amount > 0) {
        final appState = Provider.of<AppState>(context, listen: false);

        // 1. Local Idempotency check 
        if (txnId != null && appState.transactions.any((t) => t.id == txnId)) {
          debugPrint('[Receive] Already processed txn $txnId. Skipping.');
          return;
        }

        // 2. Update global state
        appState.receiveMoney(amount, senderName, txnId: txnId);

        // 3. Redundant SMS Queue — if receiver gets signal first, bank is notified
        if (txnId != null) {
          final String myPhone = appState.userPhone.trim();
          final String smsBody = '{"txn_id":"$txnId","senderId":"${senderId.trim()}","senderName":"${senderName.trim()}","receiverId":"$myPhone","amount":$amount}';
          await SmsQueueService.instance.enqueue(body: smsBody);
        }

        // 4. Show Success dialog
        showSuccessAnimation(context, () {
          Navigator.pop(context); // Dismiss animation overlay
          Navigator.pop(context); // Go back home
        });
      }
    } catch (e) {
      debugPrint("Payload parse error: $e");
    }
  }

  @override
  void dispose() {
    Nearby().stopAdvertising();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final myPhone = appState.userPhone.isNotEmpty ? appState.userPhone : appState.currentUserName;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.receiveMoney)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              context.l10n.showThisQr,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              myPhone,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: QrImageView(
                data: myPhone,
                version: QrVersions.auto,
                size: 230.0,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              connectionStatus,
              style: const TextStyle(fontSize: 15, color: Colors.blueAccent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (!isAdvertising)
              Column(children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 8),
                Text('Starting Bluetooth...', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ]),
          ],
        ),
      ),
    );
  }
}
