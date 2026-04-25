import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'balance_card.dart';
import 'state/app_state.dart';
import 'edit_profile_screen.dart';
import 'address_management_screen.dart';
import 'help_support_screen.dart';
import 'tutorial_screen.dart';
import 'l10n/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();}
class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildDarkHeader(appState),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 24.0,
                  ),
                  child: Column(
                    children: [
                      const BalanceCard(),
                      const SizedBox(height: 24),
                      _buildOptionItem(
                        icon: Icons.person_outline,
                        title: context.l10n.editProfile,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfileScreen(),
                            ),
                          );
                        },
                      ),
                      _buildOptionItem(
                        icon: Icons.location_on_outlined,
                        title: context.l10n.addressManagement,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AddressManagementScreen(),
                            ),
                          );
                        },
                      ),
                      _buildOptionItem(
                        icon: Icons.menu_book_outlined,
                        title: context.l10n.tutorial,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TutorialScreen(),
                            ),
                          );
                        },
                      ),
                      _buildOptionItem(
                        icon: Icons.headset_mic_outlined,
                        title: context.l10n.helpAndSupport,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
                          );
                        },
                      ),
                      _buildOptionItem(
                        icon: Icons.language,
                        title: context.l10n.changeLanguage,
                        onTap: () => _showLanguageDialog(context),
                      ),
                      _buildOptionItem(
                        icon: Icons.logout,
                        title: context.l10n.logout,
                        isDestructive: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDarkHeader(AppState appState) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 2, 136, 13),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance spacing
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFF81C784),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 3),
              ),
              child: Center(
                child: Text(
                  appState.currentUserName.isNotEmpty
                      ? appState.currentUserName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              appState.currentUserName.isNotEmpty
                  ? appState.currentUserName
                  : 'User',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              appState.userEmail,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            if (appState.userPhone.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.phone_outlined,
                    size: 16,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    appState.userPhone,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ],
            if (appState.userAddress.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  appState.userAddress,
                  style: const TextStyle(fontSize: 14, color: Colors.white54),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDestructive ? const Color(0xFFE53935) : Colors.black,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDestructive
                    ? const Color(0xFFFFEBEE)
                    : const Color(0xFFE0E0E0),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDestructive ? const Color(0xFFE53935) : Colors.black,
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                color: isDestructive ? const Color(0xFFE53935) : Colors.black,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDestructive ? const Color(0xFFE53935) : Colors.black,
                ),
              ),
            ),
            if (!isDestructive)
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.black54,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.changeLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageTile(context, 'English', 'en'),
            _buildLanguageTile(context, 'हिंदी', 'hi'),
            _buildLanguageTile(context, 'ಕನ್ನಡ', 'kn'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageTile(BuildContext context, String label, String code) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final bool isSelected = appState.locale == code;
        return ListTile(
          title: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
          onTap: () {
            appState.setLocale(code);
            Navigator.pop(context);
          },
        );
      },
    );
  }
}
