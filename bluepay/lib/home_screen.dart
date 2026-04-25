import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'qr_scanner_screen.dart';
import 'receive_screen.dart';
import 'state/app_state.dart';
import 'profile_screen.dart';
import 'balance_card.dart';
import 'services/sms_queue_service.dart';
import 'services/radar_service.dart';
import 'l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeDashboard(),
    const DialpadScreen(),
    const _RadarScanScreen(),
    const WalletScreen(),
    const HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      bottomNavigationBar: _buildBottomNavigationBar(),
      body: IndexedStack(index: _currentIndex, children: _pages),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Consumer2<SmsQueueService, RadarService>(
      builder: (context, smsQ, radar, _) {
        final pending = smsQ.pendingCount;

        // Scan tab badge (green dot when nearby users found)
        Widget scanIcon = const Icon(Icons.sensors, size: 28);
        if (radar.state == RadarState.found) {
          scanIcon = Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.sensors, size: 28),
              Positioned(
                top: -2,
                right: -4,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          );
        }

        Widget dialpadIcon = const Icon(Icons.dialpad, size: 28);
        if (pending > 0) {
          dialpadIcon = Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.dialpad, size: 28),
              Positioned(
                top: -4,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  constraints: const BoxConstraints(
                    minWidth: 17,
                    minHeight: 17,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    pending > 9 ? '9+' : '$pending',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          );
        }

        return Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.black, width: 1.5)),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              final radar = context.read<RadarService>();
              if (index == 2 && _currentIndex != 2) {
                radar.startAutoScan();
              } else if (_currentIndex == 2 && index != 2) {
                radar.stopAutoScan();
              }
              setState(() => _currentIndex = index);
            },
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.black54,
            elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home, size: 28),
              label: context.l10n.home,
            ),
            BottomNavigationBarItem(icon: dialpadIcon, label: context.l10n.dialpad),
            BottomNavigationBarItem(
              icon: scanIcon,
              label: 'Scan',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.account_balance_wallet_outlined, size: 28),
              label: context.l10n.wallet,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.history, size: 28),
              label: context.l10n.history,
            ),
          ],
          ),
        );
      },
    );
  }
}

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            // ── Pending SMS banner (visible only when queue > 0) ──────
            Consumer<SmsQueueService>(
              builder: (context, smsQ, _) {
                if (smsQ.pendingCount == 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        // Pulsing hourglass icon
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.hourglass_top_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                              children: [
                                TextSpan(
                                  text: '${smsQ.pendingCount} ${context.l10n.pendingSms} ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                                TextSpan(
                                  text: smsQ.hasSignal
                                      ? context.l10n.sendingNow
                                      : context.l10n.queuedWaitingForGsm,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Icon(
                          smsQ.hasSignal
                              ? Icons.signal_cellular_alt
                              : Icons.signal_cellular_off,
                          size: 16,
                          color: smsQ.hasSignal ? Colors.green : Colors.grey,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const BalanceCard(),
            const SizedBox(height: 24),
            _buildActionButtons(context),
            const SizedBox(height: 32),
            Text(
              context.l10n.transactionHistory,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 28),
            _buildTransactionList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF75B9FB),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    appState.currentUserName.isNotEmpty
                        ? appState.currentUserName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              appState.currentUserName.isNotEmpty ? appState.currentUserName : 'User',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black),
            ),

          ],
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            title: context.l10n.sendMoney,
            icon: Icons.arrow_upward,
            iconColor: Colors.amber,
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QRScannerScreen(),
                ),
              );

              if (result != null && context.mounted) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Scanned QR Code'),
                    content: Text('Result: $result'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton(
            title: context.l10n.receiveMoney,
            icon: Icons.arrow_downward,
            iconColor: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReceiveScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black, width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: Icon(icon, color: Colors.black, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (appState.transactions.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: Center(
              child: Text(
                context.l10n.noTransactionsYet,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: appState.transactions.length,
          itemBuilder: (context, index) {
            final tx = appState.transactions[index];
            return TransactionItem(
              name: tx.counterpartName,
              date:
                  '${tx.date.day}/${tx.date.month}/${tx.date.year} at ${tx.date.hour}:${tx.date.minute.toString().padLeft(2, '0')}',
              amount:
                  '${tx.isPositive ? '+' : '-'}₹${tx.amount.toStringAsFixed(2)}',
              isPositive: tx.isPositive,
            );
          },
        );
      },
    );
  }
}

// ─── Radar Scan Screen ──────────────────────────────────────────────────────────
class _RadarScanScreen extends StatefulWidget {
  const _RadarScanScreen();

  @override
  State<_RadarScanScreen> createState() => _RadarScanScreenState();
}

class _RadarScanScreenState extends State<_RadarScanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RadarService>(
      builder: (context, radar, _) {
        final isScanning = radar.state == RadarState.scanning;
        final hasUsers = radar.state == RadarState.found;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            title: const Text(
              'Radar Scan',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.black),
                onPressed: () {
                  radar.startScan();
                },
              ),
            ],
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Radar Animation Area
              Center(
                child: SizedBox(
                  width: 280,
                  height: 280,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isScanning || hasUsers)
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return CustomPaint(
                              size: const Size(280, 280),
                              painter: _RadarScreenRingsPainter(
                                progress: _controller.value,
                                color: hasUsers ? Colors.green : const Color(0xFF4FC3F7),
                              ),
                            );
                          },
                        ),
                      // Center Avatar
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: hasUsers ? Colors.green : (isScanning ? const Color(0xFF4FC3F7) : Colors.grey),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (hasUsers ? Colors.green : (isScanning ? const Color(0xFF4FC3F7) : Colors.grey)).withOpacity(0.3),
                              blurRadius: 15,
                              spreadRadius: 5,
                            )
                          ],
                        ),
                        child: Icon(
                          hasUsers ? Icons.people : (isScanning ? Icons.wifi_tethering : Icons.wifi_off),
                          size: 40,
                          color: hasUsers ? Colors.green : (isScanning ? const Color(0xFF4FC3F7) : Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Status Text
              _buildStatusText(context, radar),
              const Spacer(),
              // Quick Actions Footer
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -5),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildFooterAction(
                        title: context.l10n.sendMoney,
                        icon: Icons.qr_code_scanner,
                        color: Colors.amber,
                        onTap: () {
                           Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const QRScannerScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildFooterAction(
                        title: context.l10n.receiveMoney,
                        icon: Icons.qr_code_2,
                        color: Colors.green,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ReceiveScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusText(BuildContext context, RadarService radar) {
    if (radar.state == RadarState.permissionDenied) {
      return Column(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 40),
          const SizedBox(height: 12),
          Text(
            context.l10n.radarPermissionNeeded,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => radar.startScan(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            child: const Text('Grant Permissions', style: TextStyle(color: Colors.white)),
          )
        ],
      );
    }

    if (radar.state == RadarState.found) {
      return Column(
        children: [
          Text(
            '${radar.nearbyCount} Users Found!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap Send Money below to scan their QR code.',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      );
    }

    if (radar.state == RadarState.scanning) {
      return Column(
        children: [
          Text(
            context.l10n.scanningNearby,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4FC3F7),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Searching for BluePay users nearby...',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      );
    }

    return Column(
      children: [
        Text(
          context.l10n.noUsersNearby,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Ask them to open the Receive screen.',
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildFooterAction({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: Icon(icon, color: Colors.black, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Radar Rings Painter ──────────────────────────────────────────────────────
class _RadarScreenRingsPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RadarScreenRingsPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 4; i++) {
      final stagger = (progress + i * 0.25) % 1.0;
      final radius = maxRadius * stagger;
      final opacity = (1.0 - stagger).clamp(0.0, 0.8);

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      canvas.drawCircle(center, radius, paint);
      
      // Also draw a filled circle with very low opacity
      final fillPaint = Paint()
        ..color = color.withOpacity(opacity * 0.1)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarScreenRingsPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

// ─── Dialpad Screen ──────────────────────────────────────────────────────────
class DialpadScreen extends StatefulWidget {
  const DialpadScreen({super.key});

  @override
  State<DialpadScreen> createState() => _DialpadScreenState();
}

class _DialpadScreenState extends State<DialpadScreen> {
  String _input = '';

  // Matches *#<amount>#<phonenumber># where amount is digits (optional decimal)
  static final _ussdPayRegex = RegExp(r'^\*#(\d+(?:\.\d+)?)#(\d+)#$');

  void _onKey(String key) {
    setState(() => _input += key);
    // Auto-detect USSD payment pattern after every keystroke
    final match = _ussdPayRegex.firstMatch(_input);
    if (match != null) {
      final amount = double.tryParse(match.group(1)!);
      final phone = match.group(2)!;
      if (amount != null && amount > 0) {
        // Slight delay so the user sees the final # appear before the dialog
        Future.delayed(const Duration(milliseconds: 120), () {
          if (mounted) _showConfirmDialog(amount, phone);
        });
      }
    }
  }

  void _onBackspace() {
    if (_input.isNotEmpty) {
      setState(() => _input = _input.substring(0, _input.length - 1));
    }
  }

  void _onClear() {
    setState(() => _input = '');
  }

  void _showConfirmDialog(double amount, String receiverPhone) {
    final appState = Provider.of<AppState>(context, listen: false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Colors.black, width: 1.5),
        ),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: const Icon(Icons.send_to_mobile, color: Colors.black, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'Confirm Payment',
              style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('From', appState.currentUserName),
            const SizedBox(height: 8),
            _infoRow('To (phone)', receiverPhone),
            const SizedBox(height: 8),
            _infoRow('Amount', '₹${amount.toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black26, width: 1),
              ),
              child: const Text(
                'Transaction will be sent via GSM SMS to the backend.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _onClear();
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _processUssdPayment(amount, receiverPhone, appState);
            },
            child: const Text('Send', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _processUssdPayment(
    double amount,
    String receiverPhone,
    AppState appState,
  ) async {
    if (appState.balance < amount) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Insufficient balance'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      _onClear();
      return;
    }

    final txnId =
        'TXN${DateTime.now().millisecondsSinceEpoch}${(DateTime.now().microsecond % 9999).toString().padLeft(4, '0')}';
    final smsBody =
        '{"txn_id":"$txnId","senderId":"${appState.userPhone.trim()}","receiverId":"$receiverPhone","amount":$amount}';

    // Deduct locally & record
    appState.sendMoney(amount, receiverPhone, txnId: txnId);

    // Queue / send JSON SMS to relay phone
    await SmsQueueService.instance.enqueue(body: smsBody);

    if (mounted) {
      _onClear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '₹${amount.toStringAsFixed(2)} sent to $receiverPhone via GSM',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.black),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildGridRow(List<String> labels) {
    return Expanded(
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.black12, width: 1),
          ),
        ),
        child: Row(
          children: [
            _buildFlatKey(labels[0]),
            Container(width: 1, color: Colors.black12),
            _buildFlatKey(labels[1]),
            Container(width: 1, color: Colors.black12),
            _buildFlatKey(labels[2]),
          ],
        ),
      ),
    );
  }

  Widget _buildFlatKey(String label) {
    return Expanded(
      child: InkWell(
        onTap: () => _onKey(label),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 64),
            // ── Hint banner ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        size: 14,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        context.l10n.hintDialpad,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // ── Dialpad Container ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.64,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.black, width: 1.4),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // ── Display Row ───────────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(width: 24), // Balance spacing
                            Expanded(
                              child: Text(
                                _input.isEmpty ? context.l10n.enterNumber : _input,
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: _input.isEmpty
                                      ? Colors.grey[400]
                                      : Colors.black,
                                  letterSpacing: 1.8,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_input.isNotEmpty)
                              GestureDetector(
                                onTap: _onBackspace,
                                onLongPress: _onClear,
                                child: const Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Icon(
                                    Icons.backspace_outlined,
                                    color: Colors.black,
                                    size: 22,
                                  ),
                                ),
                              )
                            else
                              const SizedBox(width: 32), // Spacer when no input
                          ],
                        ),
                      ),
                      Container(height: 1.2, color: Colors.black),
                      // ── Keys grid ─────────────────────────────────────────────
                      Expanded(
                        child: Column(
                          children: [
                            _buildGridRow(['1', '2', '3']),
                            _buildGridRow(['4', '5', '6']),
                            _buildGridRow(['7', '8', '9']),
                            _buildGridRow(['*', '0', '#']),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Wallet Screen ────────────────────────────────────────────────────────────
class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final txns = appState.transactions;
        final totalSent = txns.where((t) => !t.isPositive).fold(0.0, (sum, t) => sum + t.amount);
        final totalReceived = txns.where((t) => t.isPositive).fold(0.0, (sum, t) => sum + t.amount);
        final pending = SmsQueueService.instance.pendingCount;

        // Design Tokens
        const Color colorPageBg = Color(0xFFF2F2F2);
        const Color colorCardBg = Color(0xFF1B4332);
        const Color colorHeadline = Color(0xFF7ED957);

        return Scaffold(
          backgroundColor: colorPageBg,
          appBar: AppBar(
            backgroundColor: colorCardBg,
            elevation: 0,
            centerTitle: true,
            title: Text(
              context.l10n.wallet.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: colorHeadline,
                letterSpacing: 1.5,
                fontSize: 18,
              ),
            ),
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Premium Wallet Header
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: colorCardBg,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: Column(
                    children: [
                      const Text(
                        'AVAILABLE BALANCE',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '₹${appState.balance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          _WalletSummaryItem(
                            label: 'INCOME',
                            value: '₹${totalReceived.toStringAsFixed(2)}',
                            icon: Icons.add_circle_outline,
                            color: colorHeadline,
                          ),
                          Container(width: 1, height: 40, color: Colors.white12),
                          _WalletSummaryItem(
                            label: 'EXPENSE',
                            value: '₹${totalSent.toStringAsFixed(2)}',
                            icon: Icons.remove_circle_outline,
                            color: Colors.redAccent.shade100,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _StatCard(
                            label: 'Transactions',
                            value: txns.length.toString(),
                            icon: Icons.receipt_long_outlined,
                            iconBg: Colors.blue.shade50,
                            iconColor: Colors.blueAccent,
                          ),
                          const SizedBox(width: 14),
                          _StatCard(
                            label: 'SMS Pending',
                            value: pending.toString(),
                            icon: Icons.hourglass_top_rounded,
                            iconBg: Colors.orange.shade50,
                            iconColor: Colors.orange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Text(
                        context.l10n.accountInfo,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 12),
                      _InfoCard(
                        children: [
                          _InfoRow(icon: Icons.person_outline, label: context.l10n.name, value: appState.currentUserName),
                          const Divider(height: 1),
                          _InfoRow(icon: Icons.email_outlined, label: context.l10n.email, value: appState.userEmail.isNotEmpty ? appState.userEmail : '—'),
                          const Divider(height: 1),
                          _InfoRow(icon: Icons.phone_outlined, label: context.l10n.phone, value: appState.userPhone.isNotEmpty ? appState.userPhone : '—'),
                          const Divider(height: 1),
                          _InfoRow(icon: Icons.tag_outlined, label: context.l10n.endpointId, value: appState.myEndpointId),
                        ],
                      ),

                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF757575)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Icon(icon, size: 16, color: Colors.black),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Color(0xFF757575), fontSize: 13, fontWeight: FontWeight.w500)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}


// ─── History Screen ───────────────────────────────────────────────────────────
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // 0 = All, 1 = Sent, 2 = Received
  int _filter = 0;


  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final all = appState.transactions;
        final filtered = _filter == 0
            ? all
            : _filter == 1
            ? all.where((t) => !t.isPositive).toList()
            : all.where((t) => t.isPositive).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            title: Text(
              context.l10n.transactionHistory,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ),
          body: Column(
            children: [
              // ── Filter tabs ───────────────────────────────────────────
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.black12, width: 1)),
                ),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Row(
                  children: [
                    _FilterTab(
                      label: context.l10n.all,
                      active: _filter == 0,
                      onTap: () => setState(() => _filter = 0),
                    ),
                    const SizedBox(width: 8),
                    _FilterTab(
                      label: context.l10n.sent,
                      active: _filter == 1,
                      onTap: () => setState(() => _filter = 1),
                    ),
                    const SizedBox(width: 8),
                    _FilterTab(
                      label: context.l10n.received,
                      active: _filter == 2,
                      onTap: () => setState(() => _filter = 2),
                    ),
                    const Spacer(),
                    Text(
                      '${filtered.length} txn${filtered.length == 1 ? '' : 's'}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF757575), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              // ── List ──────────────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmpty()
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final tx = filtered[index];
                          return _TxnCard(tx: tx);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: const Icon(Icons.receipt_long_outlined, size: 40, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          Text(
            _filter == 0
                ? context.l10n.noTransactionsYet
                : _filter == 1
                ? context.l10n.noSentTransactions
                : context.l10n.noReceivedTransactions,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.transactionsWillAppearHere,
            style: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
          ),
        ],
      ),
    );
  }
}


class _FilterTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}

class _TxnCard extends StatelessWidget {
  final Transaction tx;
  const _TxnCard({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isPositive = tx.isPositive;
    final color = isPositive ? Colors.green : const Color(0xFFE53935);
    final icon = isPositive
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;
    final label = isPositive ? context.l10n.received : context.l10n.sent;
    final date = tx.date;
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}  '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Row(
        children: [
          // Icon bubble
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          // Name & date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.counterpartName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: color.withOpacity(0.4), width: 1),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dateStr,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF757575)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Amount
          Text(
            '${isPositive ? '+' : '-'}₹${tx.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionItem extends StatelessWidget {
  final String name;
  final String date;
  final String amount;
  final bool isPositive;

  const TransactionItem({
    super.key,
    required this.name,
    required this.date,
    required this.amount,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: const Icon(Icons.person, color: Colors.blueAccent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: isPositive ? Colors.green : const Color(0xFFE53935),
            ),
          ),
        ],
      ),
    );
  }
}
class _WalletSummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _WalletSummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageSwitcherRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: const Icon(Icons.language, color: Colors.black, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              context.l10n.changeLanguage,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
          Consumer<AppState>(
            builder: (context, appState, _) {
              return DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: appState.locale,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      appState.setLocale(newValue);
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'hi', child: Text('हिंदी')),
                    DropdownMenuItem(value: 'kn', child: Text('ಕನ್ನಡ')),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

