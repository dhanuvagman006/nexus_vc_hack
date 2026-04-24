import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Light background color
      bottomNavigationBar: _buildBottomNavigationBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildBalanceCard(),
              const SizedBox(height: 24),
              _buildActionButtons(),
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
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey,
          backgroundImage: NetworkImage(
              'https://randomuser.me/api/portraits/men/32.jpg'), // Placeholder
        ),
        const SizedBox(width: 12),
        const Text(
          'Alexey G.',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
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
        )
      ],
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF89E0B9), // Light green/mint
            Color(0xFF75B9FB), // Light blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF75B9FB).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.visibility_outlined,
                      color: Colors.black54, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Your balance:',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Text(
                      'USD',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, size: 16),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '\$175,963.56',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF222232),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_outlined, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            title: 'Send Money',
            icon: Icons.arrow_upward,
            iconColor: Colors.amber,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton(
            title: 'Receive Money',
            icon: Icons.arrow_downward,
            iconColor: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
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
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    return Column(
      children: [
        _buildTransactionItem(
          name: 'Chance Barnett',
          date: 'Today at 8:31',
          amount: '+\$175,963.56',
          isPositive: true,
          imageUrl: 'https://randomuser.me/api/portraits/men/44.jpg',
        ),
        _buildTransactionItem(
          name: 'Chance Barnett',
          date: 'Yesterday at 10:42',
          amount: '+\$37.88',
          isPositive: true,
          imageUrl: 'https://randomuser.me/api/portraits/men/44.jpg',
        ),
        _buildTransactionItem(
          name: 'Nick Lepestos',
          date: 'Today at 8:31',
          amount: '-\$37.88',
          isPositive: false,
          imageUrl: 'https://randomuser.me/api/portraits/men/46.jpg',
        ),
      ],
    );
  }

  Widget _buildTransactionItem({
    required String name,
    required String date,
    required String amount,
    required bool isPositive,
    required String imageUrl,
  }) {
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
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(imageUrl),
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
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 13,
                  ),
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

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      backgroundColor: Colors.white,
      elevation: 20,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home, color: Colors.blueAccent, size: 28),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.qr_code_scanner, color: Colors.grey, size: 28),
          label: 'Scan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet_outlined, color: Colors.grey, size: 28),
          label: 'Wallet',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history, color: Colors.grey, size: 28),
          label: 'History',
        ),
      ],
    );
  }
}
