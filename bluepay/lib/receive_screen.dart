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
            setState(() => connectionStatus = 'Connected securely!');
          }
        },
        onDisconnected: (String id) {},
        serviceId: "com.example.bluepay",
      );

      if (isAdv) {
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
          final String myName = appState.currentUserName.trim();
          final String smsBody = json.encode({
            "txn_id": txnId,
            "senderId": senderId.trim(),
            "senderName": senderName.trim(),
            "receiverId": myPhone,
            "receiverName": myName,
            "amount": amount
          });
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
    final myName = appState.currentUserName.isNotEmpty ? appState.currentUserName : 'BluePay User';

    // Design Tokens from previous mocks
    const Color colorPageBg = Color(0xFFF2F2F2);
    const Color colorCardBg = Color(0xFF1B4332);
    const Color colorHeadline = Color(0xFF7ED957);
    const Color colorBodyText = Colors.white;

    return Scaffold(
      backgroundColor: colorPageBg,
      appBar: AppBar(
        title: Text(context.l10n.receiveMoney, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            children: [
              // Premium Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorCardBg,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Text(
                      'RECEIVE PAYMENT',
                      style: TextStyle(
                        color: colorHeadline,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      myName,
                      style: const TextStyle(
                        color: colorBodyText,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      myPhone,
                      style: TextStyle(
                        color: colorBodyText.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // QR Container with Decorative Brackets
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // The Corner Brackets
                        Positioned.fill(
                          child: CustomPaint(painter: CornerBracketPainter(color: colorHeadline)),
                        ),
                        
                        // The QR Box
                        Container(
                          margin: const EdgeInsets.all(20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: QrImageView(
                            data: json.encode({
                              'phone': appState.userPhone,
                              'name': appState.currentUserName,
                            }),
                            version: QrVersions.auto,
                            size: 200.0,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.circle,
                              color: Colors.black,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.circle,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Scan this code to pay me offline',
                      style: TextStyle(
                        color: colorBodyText.withOpacity(0.6),
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              // Status Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isAdvertising)
                      const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
                      )
                    else
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      connectionStatus,
                      style: TextStyle(
                        fontSize: 14,
                        color: isAdvertising ? Colors.green.shade700 : Colors.blueAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CornerBracketPainter extends CustomPainter {
  final Color color;
  CornerBracketPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    const double len = 25;
    
    // Top Left
    canvas.drawLine(const Offset(0, 0), const Offset(len, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, len), paint);
    
    // Top Right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - len, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, len), paint);
    
    // Bottom Left
    canvas.drawLine(Offset(0, size.height), Offset(len, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - len), paint);
    
    // Bottom Right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - len, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - len), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
