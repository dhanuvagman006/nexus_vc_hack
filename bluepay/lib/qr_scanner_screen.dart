import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'payment_screen.dart';
import 'state/app_state.dart';
import 'l10n/app_localizations.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  final Strategy strategy = Strategy.P2P_CLUSTER;

  String? scannedCode;
  bool isConnecting = false;
  String connectionStatus = '';

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
      Permission.nearbyWifiDevices,
    ].request();
  }

  Future<void> _connectToScannedCode(String code) async {
    setState(() {
      isConnecting = true;
      connectionStatus = 'Scanning nearby networks for $code...';
    });

    final appState = Provider.of<AppState>(context, listen: false);

    try {
      bool? isDiscovering = await Nearby().startDiscovery(
        appState.currentUserName, // our name
        strategy,
        onEndpointFound: (String id, String endpointName, String serviceId) {
          if (endpointName == code) {
            // Found the receiver we scanned!
            setState(() => connectionStatus = 'Receiver found. Negotiating connection...');
            Nearby().stopDiscovery();
            
            Nearby().requestConnection(
              appState.currentUserName,
              id,
              onConnectionInitiated: (String connId, ConnectionInfo info) {
                // Auto accept for local execution prototype
                Nearby().acceptConnection(
                  connId,
                  onPayLoadRecieved: (String endId, Payload payload) {},
                  onPayloadTransferUpdate: (String endId, PayloadTransferUpdate update) {},
                );
              },
              onConnectionResult: (String connId, Status status) {
                if (status == Status.CONNECTED) {
                  setState(() => connectionStatus = 'Connected securely!');
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentScreen(
                        endpointId: connId,
                        receiverPhone: code, // code is receiver's phone number from QR
                      ),
                    ),
                  );
                } else {
                  if (mounted) {
                    setState(() {
                      isConnecting = false;
                      scannedCode = null; // reset to allow re-scan
                    });
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection Rejected / Failed')));
                  }
                }
              },
              onDisconnected: (String id) {},
            );
          }
        },
        onEndpointLost: (String? id) {},
        serviceId: "com.example.bluepay",
      );

      if (!(isDiscovering ?? false)) {
        setState(() {
          isConnecting = false;
          scannedCode = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isConnecting = false;
          scannedCode = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Discovery failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.scanQrCode),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (BarcodeCapture capture) {
              if (scannedCode != null || isConnecting) return;

              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                setState(() => scannedCode = barcodes.first.rawValue);
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: scannedCode != null ? Colors.green : Colors.white,
                  width: 4.0,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isConnecting) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      connectionStatus,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                    )
                  ] else ...[
                    Text(
                      scannedCode != null
                          ? 'Found ID: $scannedCode'
                          : context.l10n.alignQrInsideFrame,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: scannedCode != null ? () => _connectToScannedCode(scannedCode!) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Connect via Bluetooth/WiFi',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    try { Nearby().stopDiscovery(); } catch (_) {}
    cameraController.dispose();
    super.dispose();
  }
}