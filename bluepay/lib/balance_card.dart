import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';

class BalanceCard extends StatefulWidget {
  const BalanceCard({super.key});

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  bool _isBalanceVisible = false;
  final TextEditingController _pinController = TextEditingController();

  void _checkPin() {
    if (_pinController.text == '1234') {
      setState(() {
        _isBalanceVisible = true;
      });
      _pinController.clear();
      Navigator.pop(context); // close dialog
    } else {
      // show error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect code'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showPinDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Enter Passcode'),
          content: TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter 4-digit code',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: Color(0xFF75B9FB), width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _pinController.clear();
                Navigator.pop(context);
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: _checkPin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF75B9FB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Verify',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Align(
            alignment: Alignment.topRight,
            child: Icon(
              Icons.account_balance_wallet,
              size: 48,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Consumer<AppState>(
            builder: (context, appState, child) {
              return Text(
                _isBalanceVisible
                    ? '₹${appState.balance.toStringAsFixed(2)}'
                    : '₹••••••••',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              if (_isBalanceVisible) {
                setState(() {
                  _isBalanceVisible = false;
                });
              } else {
                _showPinDialog();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF222232),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isBalanceVisible ? Icons.visibility_off_outlined : Icons.lock_open_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isBalanceVisible ? 'Hide balance' : 'Reveal the balance',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
