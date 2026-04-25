import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'qr_scanner_screen.dart';
import 'receive_screen.dart';
import 'state/app_state.dart';
import 'profile_screen.dart';
import 'balance_card.dart';
import 'services/sms_queue_service.dart';

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
    return Consumer<SmsQueueService>(
      builder: (context, smsQ, _) {
        final pending = smsQ.pendingCount;

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

        return BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey,
          elevation: 20,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home, size: 28),
              label: 'Home',
            ),
            BottomNavigationBarItem(icon: dialpadIcon, label: 'Dialpad'),
            const BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined, size: 28),
              label: 'Wallet',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.history, size: 28),
              label: 'History',
            ),
          ],
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
                                  text: '${smsQ.pendingCount} SMS ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                                TextSpan(
                                  text: smsQ.isGsmAvailable
                                      ? 'sending now...'
                                      : 'queued · waiting for GSM signal',
                                ),
                              ],
                            ),
                          ),
                        ),
                        Icon(
                          smsQ.isGsmAvailable
                              ? Icons.signal_cellular_alt
                              : Icons.signal_cellular_off,
                          size: 16,
                          color: smsQ.isGsmAvailable
                              ? Colors.green
                              : Colors.grey,
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
            const Text(
              'Transactions',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
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
              child: CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF75B9FB),
                child: Text(
                  appState.currentUserName.isNotEmpty
                      ? appState.currentUserName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              appState.currentUserName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_outlined, size: 28),
                  onPressed: () {},
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
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
            title: 'Send Money',
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
            title: 'Receive Money',
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
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
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
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32.0),
            child: Center(
              child: Text(
                'No transactions yet.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.send_to_mobile, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text('Confirm Payment'),
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
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Transaction will be sent via GSM SMS to the backend.',
                style: TextStyle(fontSize: 12, color: Colors.blueAccent),
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
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _processUssdPayment(amount, receiverPhone, appState);
            },
            child: const Text('Send', style: TextStyle(color: Colors.white)),
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

    // Build JSON SMS body — Android relay app on 6360139965 receives this
    // and POSTs the same JSON to POST /relay on the backend.
    final txnId =
        'TXN${DateTime.now().millisecondsSinceEpoch}${(DateTime.now().microsecond % 9999).toString().padLeft(4, '0')}';
    final smsBody =
        '{"txn_id":"$txnId","senderId":"${appState.currentUserName.trim()}","receiverId":"$receiverPhone","amount":$amount}';

    // Deduct locally & record
    appState.sendMoney(amount, receiverPhone);

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
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
            bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
          ),
        ),
        child: Row(
          children: [
            _buildFlatKey(labels[0]),
            Container(width: 1, color: const Color(0xFFEEEEEE)),
            _buildFlatKey(labels[1]),
            Container(width: 1, color: const Color(0xFFEEEEEE)),
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
              fontSize: 34,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
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
            const SizedBox(height: 200),
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
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.blueAccent,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Type  *#amount#phonenumber#  to send money via GSM',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            // ── Dialpad Container ─────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Display Row ───────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 24), // Balance spacing
                        Expanded(
                          child: Text(
                            _input.isEmpty ? 'Enter number' : _input,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: _input.isEmpty
                                  ? Colors.grey[400]
                                  : Colors.black87,
                              letterSpacing: 2,
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
                                color: Colors.black54,
                                size: 24,
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 32), // Spacer when no input
                      ],
                    ),
                  ),
                  Container(height: 1, color: const Color(0xFFEEEEEE)),
                  // ── Keys grid ─────────────────────────────────────────────
                  SizedBox(
                    height: 380, // Increased size of keys
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
            const SizedBox(height: 48), // Bottom padding
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
        final totalSent = txns
            .where((t) => !t.isPositive)
            .fold(0.0, (sum, t) => sum + t.amount);
        final totalReceived = txns
            .where((t) => t.isPositive)
            .fold(0.0, (sum, t) => sum + t.amount);
        final pending = SmsQueueService.instance.pendingCount;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'Wallet',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Balance card ──────────────────────────────────────────
                const BalanceCard(),
                const SizedBox(height: 24),

                // ── Stats row ─────────────────────────────────────────────
                Row(
                  children: [
                    _StatCard(
                      label: 'Total Sent',
                      value: '₹${totalSent.toStringAsFixed(2)}',
                      icon: Icons.arrow_upward_rounded,
                      iconBg: Colors.red.shade50,
                      iconColor: Colors.redAccent,
                    ),
                    const SizedBox(width: 14),
                    _StatCard(
                      label: 'Total Received',
                      value: '₹${totalReceived.toStringAsFixed(2)}',
                      icon: Icons.arrow_downward_rounded,
                      iconBg: Colors.green.shade50,
                      iconColor: Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
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

                // ── Account Info ──────────────────────────────────────────
                const Text(
                  'Account Info',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  children: [
                    _InfoRow(
                      icon: Icons.person_outline,
                      label: 'Name',
                      value: appState.currentUserName,
                    ),
                    const Divider(height: 1),
                    _InfoRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: appState.userEmail.isNotEmpty
                          ? appState.userEmail
                          : '—',
                    ),
                    const Divider(height: 1),
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: appState.userPhone.isNotEmpty
                          ? appState.userPhone
                          : '—',
                    ),
                    const Divider(height: 1),
                    _InfoRow(
                      icon: Icons.tag_outlined,
                      label: 'Endpoint ID',
                      value: appState.myEndpointId,
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Quick actions ─────────────────────────────────────────
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _QuickAction(
                      icon: Icons.arrow_upward,
                      label: 'Send',
                      color: Colors.blueAccent,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const QRScannerScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _QuickAction(
                      icon: Icons.arrow_downward,
                      label: 'Receive',
                      color: Colors.green,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReceiveScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
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
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
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
          Icon(icon, size: 18, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
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
            title: const Text(
              'Transaction History',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          body: Column(
            children: [
              // ── Filter tabs ───────────────────────────────────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Row(
                  children: [
                    _FilterTab(
                      label: 'All',
                      active: _filter == 0,
                      onTap: () => setState(() => _filter = 0),
                    ),
                    const SizedBox(width: 8),
                    _FilterTab(
                      label: 'Sent',
                      active: _filter == 1,
                      onTap: () => setState(() => _filter = 1),
                    ),
                    const SizedBox(width: 8),
                    _FilterTab(
                      label: 'Received',
                      active: _filter == 2,
                      onTap: () => setState(() => _filter = 2),
                    ),
                    const Spacer(),
                    Text(
                      '${filtered.length} txn${filtered.length == 1 ? '' : 's'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _filter == 0
                ? 'No transactions yet'
                : _filter == 1
                ? 'No sent transactions'
                : 'No received transactions',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Transactions will appear here',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
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
          color: active ? Colors.blueAccent : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : Colors.grey[600],
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
    final color = isPositive ? Colors.green : Colors.redAccent;
    final icon = isPositive
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;
    final label = isPositive ? 'Received' : 'Sent';
    final date = tx.date;
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}  '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon bubble
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
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
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
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
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dateStr,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
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
              fontWeight: FontWeight.bold,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[200],
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
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isPositive ? Colors.green : Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }
}
