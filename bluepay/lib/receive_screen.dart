import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'state/app_state.dart';
import 'success_animation.dart';

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
        appState.currentUserName, // Advertise with real name so sender can display it
        strategy,
        onConnectionInitiated: (String id, ConnectionInfo info) {
          setState(() => connectionStatus = 'Connection requested from ${info.endpointName}...');
          // Auto accept connection for local P2P prototype validation
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

  void _handleIncomingPayment(String jsonString) {
    if (!mounted) return;
    try {
      final decoded = json.decode(jsonString);
      final double? amount = double.tryParse(decoded['amount']?.toString() ?? '');
      final String senderName = decoded['senderName'] ?? 'Unknown Sender';

      if (amount != null && amount > 0) {
        // Update global state
        Provider.of<AppState>(context, listen: false).receiveMoney(amount, senderName);

        // Show Success dialog and return
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
    final myName = Provider.of<AppState>(context, listen: false).currentUserName;

    return Scaffold(
      appBar: AppBar(title: const Text('Receive Money Offline')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Show this QR to the sender',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
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
                data: myName, // Broadcast username so sender sees real name
                version: QrVersions.auto,
                size: 250.0,
              ),
            ),
            const SizedBox(height: 40),
            Text(
              connectionStatus,
              style: const TextStyle(fontSize: 16, color: Colors.blueAccent),
            ),
            const SizedBox(height: 20),
            if (!isAdvertising) const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
