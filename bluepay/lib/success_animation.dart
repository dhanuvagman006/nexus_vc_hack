import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class TransactionSuccessAnimation extends StatefulWidget {
  final VoidCallback onComplete;
  
  const TransactionSuccessAnimation({super.key, required this.onComplete});

  @override
  State<TransactionSuccessAnimation> createState() => _TransactionSuccessAnimationState();
}

class _TransactionSuccessAnimationState extends State<TransactionSuccessAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  static const platform = MethodChannel('com.example.bluepay/audio');

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _playAnimationAndSound();
  }

  Future<void> _playAnimationAndSound() async {
    try {
      await platform.invokeMethod('playSuccessSound');
    } catch (e) {
      debugPrint("Failed to play sound: $e");
    }
    
    // Play animation
    _controller.forward();

    // Wait for 2 seconds then complete
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.85), // Dark overlay
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 140,
                height: 140,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.greenAccent,
                      blurRadius: 40,
                      spreadRadius: 10,
                    )
                  ],
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 140,
                ),
              ),
            ),
            const SizedBox(height: 32),
            FadeTransition(
              opacity: _controller,
              child: const Text(
                'Transaction Successful',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper to show the animation overlay
void showSuccessAnimation(BuildContext context, VoidCallback onComplete) {
  showGeneralDialog(
    context: context,
    pageBuilder: (context, animation, secondaryAnimation) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: TransactionSuccessAnimation(onComplete: onComplete),
      );
    },
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 300),
  );
}
