import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(context.l10n.tutorial),
        backgroundColor: const Color.fromARGB(255, 2, 136, 13),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.tutorialTitle,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.tutorialSubtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            _buildTutorialStep(
              icon: Icons.qr_code_scanner,
              title: context.l10n.tutorialStep1Title,
              description: context.l10n.tutorialStep1Desc,
            ),
            _buildTutorialStep(
              icon: Icons.send,
              title: context.l10n.tutorialStep2Title,
              description: context.l10n.tutorialStep2Desc,
            ),
            _buildTutorialStep(
              icon: Icons.qr_code,
              title: context.l10n.tutorialStep3Title,
              description: context.l10n.tutorialStep3Desc,
            ),
            _buildTutorialStep(
              icon: Icons.history,
              title: context.l10n.tutorialStep4Title,
              description: context.l10n.tutorialStep4Desc,
            ),
             _buildTutorialStep(
              icon: Icons.signal_cellular_alt_rounded,
              title: context.l10n.tutorialStep5Title,
              description: context.l10n.tutorialStep5Desc,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialStep({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1), // Light green tint
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Icon(icon, color: const Color.fromARGB(255, 2, 136, 13), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
