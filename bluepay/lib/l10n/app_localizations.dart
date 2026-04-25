import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class AppLocalizations {
  final String locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    final locale = context.watch<AppState>().locale;
    return AppLocalizations(locale);
  }

  
  String get home => _localizedValues[locale]?['home'] ?? _localizedValues['en']!['home']!;
  String get dialpad => _localizedValues[locale]?['dialpad'] ?? _localizedValues['en']!['dialpad']!;
  String get wallet => _localizedValues[locale]?['wallet'] ?? _localizedValues['en']!['wallet']!;
  String get history => _localizedValues[locale]?['history'] ?? _localizedValues['en']!['history']!;
  
  String get sendMoney => _localizedValues[locale]?['sendMoney'] ?? _localizedValues['en']!['sendMoney']!;
  String get receiveMoney => _localizedValues[locale]?['receiveMoney'] ?? _localizedValues['en']!['receiveMoney']!;
  String get scanQrToPay => _localizedValues[locale]?['scanQrToPay'] ?? _localizedValues['en']!['scanQrToPay']!;
  
  String get accountInfo => _localizedValues[locale]?['accountInfo'] ?? _localizedValues['en']!['accountInfo']!;
  String get name => _localizedValues[locale]?['name'] ?? _localizedValues['en']!['name']!;
  String get phone => _localizedValues[locale]?['phone'] ?? _localizedValues['en']!['phone']!;
  String get email => _localizedValues[locale]?['email'] ?? _localizedValues['en']!['email']!;
  String get endpointId => _localizedValues[locale]?['endpointId'] ?? _localizedValues['en']!['endpointId']!;
  
  String get quickActions => _localizedValues[locale]?['quickActions'] ?? _localizedValues['en']!['quickActions']!;
  String get myQrCode => _localizedValues[locale]?['myQrCode'] ?? _localizedValues['en']!['myQrCode']!;
  String get changeLanguage => _localizedValues[locale]?['changeLanguage'] ?? _localizedValues['en']!['changeLanguage']!;
  String get language => _localizedValues[locale]?['language'] ?? _localizedValues['en']!['language']!;

  String get totalBalance => _localizedValues[locale]?['totalBalance'] ?? _localizedValues['en']!['totalBalance']!;
  String get transactionHistory => _localizedValues[locale]?['transactionHistory'] ?? _localizedValues['en']!['transactionHistory']!;
  String get all => _localizedValues[locale]?['all'] ?? _localizedValues['en']!['all']!;
  String get sent => _localizedValues[locale]?['sent'] ?? _localizedValues['en']!['sent']!;
  String get received => _localizedValues[locale]?['received'] ?? _localizedValues['en']!['received']!;
  String get noTransactionsYet => _localizedValues[locale]?['noTransactionsYet'] ?? _localizedValues['en']!['noTransactionsYet']!;
  String get noSentTransactions => _localizedValues[locale]?['noSentTransactions'] ?? _localizedValues['en']!['noSentTransactions']!;
  String get noReceivedTransactions => _localizedValues[locale]?['noReceivedTransactions'] ?? _localizedValues['en']!['noReceivedTransactions']!;
  String get transactionsWillAppearHere => _localizedValues[locale]?['transactionsWillAppearHere'] ?? _localizedValues['en']!['transactionsWillAppearHere']!;
  
  String get paying => _localizedValues[locale]?['paying'] ?? _localizedValues['en']!['paying']!;
  String get amount => _localizedValues[locale]?['amount'] ?? _localizedValues['en']!['amount']!;
  String get enterAmount => _localizedValues[locale]?['enterAmount'] ?? _localizedValues['en']!['enterAmount']!;
  String get send => _localizedValues[locale]?['send'] ?? _localizedValues['en']!['send']!;
  String get insufficientBalance => _localizedValues[locale]?['insufficientBalance'] ?? _localizedValues['en']!['insufficientBalance']!;
  
  String get waitingForSender => _localizedValues[locale]?['waitingForSender'] ?? _localizedValues['en']!['waitingForSender']!;
  String get ensureBluetoothWifiOn => _localizedValues[locale]?['ensureBluetoothWifiOn'] ?? _localizedValues['en']!['ensureBluetoothWifiOn']!;
  String get showThisQr => _localizedValues[locale]?['showThisQr'] ?? _localizedValues['en']!['showThisQr']!;

  String get scanQrCode => _localizedValues[locale]?['scanQrCode'] ?? _localizedValues['en']!['scanQrCode']!;
  String get alignQrInsideFrame => _localizedValues[locale]?['alignQrInsideFrame'] ?? _localizedValues['en']!['alignQrInsideFrame']!;

  String get editProfile => _localizedValues[locale]?['editProfile'] ?? _localizedValues['en']!['editProfile']!;
  String get addressManagement => _localizedValues[locale]?['addressManagement'] ?? _localizedValues['en']!['addressManagement']!;
  String get helpAndSupport => _localizedValues[locale]?['helpAndSupport'] ?? _localizedValues['en']!['helpAndSupport']!;
  String get logout => _localizedValues[locale]?['logout'] ?? _localizedValues['en']!['logout']!;
  String get save => _localizedValues[locale]?['save'] ?? _localizedValues['en']!['save']!;
  String get pendingSms => _localizedValues[locale]?['pendingSms'] ?? _localizedValues['en']!['pendingSms']!;
  String get sendingNow => _localizedValues[locale]?['sendingNow'] ?? _localizedValues['en']!['sendingNow']!;
  String get queuedWaitingForGsm => _localizedValues[locale]?['queuedWaitingForGsm'] ?? _localizedValues['en']!['queuedWaitingForGsm']!;
  String get hintDialpad => _localizedValues[locale]?['hintDialpad'] ?? _localizedValues['en']!['hintDialpad']!;
  String get clear => _localizedValues[locale]?['clear'] ?? _localizedValues['en']!['clear']!;
  String get enterNumber => _localizedValues[locale]?['enterNumber'] ?? _localizedValues['en']!['enterNumber']!;

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'home': 'Home',
      'dialpad': 'Dialpad',
      'wallet': 'Wallet',
      'history': 'History',
      'sendMoney': 'Send Money',
      'receiveMoney': 'Receive Money',
      'scanQrToPay': 'Scan QR to Pay',
      'accountInfo': 'Account Info',
      'name': 'Name',
      'phone': 'Phone',
      'email': 'Email',
      'endpointId': 'Endpoint ID',
      'quickActions': 'Quick Actions',
      'myQrCode': 'My QR Code',
      'changeLanguage': 'Change Language',
      'language': 'Language',
      'totalBalance': 'Total Balance',
      'transactionHistory': 'Transaction History',
      'all': 'All',
      'sent': 'Sent',
      'received': 'Received',
      'noTransactionsYet': 'No transactions yet.',
      'noSentTransactions': 'No sent transactions',
      'noReceivedTransactions': 'No received transactions',
      'transactionsWillAppearHere': 'Transactions will appear here',
      'paying': 'Paying',
      'amount': 'Amount',
      'enterAmount': 'Enter amount',
      'send': 'Send',
      'insufficientBalance': 'Insufficient Balance',
      'waitingForSender': 'Waiting for sender...',
      'ensureBluetoothWifiOn': 'Ensure Bluetooth and Wi-Fi are turned ON.',
      'showThisQr': 'Show this QR to the sender.',
      'scanQrCode': 'Scan QR Code',
      'alignQrInsideFrame': 'Align QR code inside the frame to scan.',
      'editProfile': 'Edit Profile',
      'addressManagement': 'Address Management',
      'helpAndSupport': 'Help & Support',
      'logout': 'Log out',
      'save': 'Save',
      'pendingSms': 'SMS',
      'sendingNow': 'sending now...',
      'queuedWaitingForGsm': 'queued · waiting for GSM signal',
      'hintDialpad': 'Use pattern *#amount#phonenumber# to send money via USSD/SMS fallback if offline.',
      'clear': 'Clear',
      'enterNumber': '*#amount#phonenumber#',
    },
    'hi': {
      'home': 'होम',
      'dialpad': 'डायलपैड',
      'wallet': 'वॉलेट',
      'history': 'इतिहास',
      'sendMoney': 'पैसे भेजें',
      'receiveMoney': 'पैसे प्राप्त करें',
      'scanQrToPay': 'स्कैन करके भुगतान करें',
      'accountInfo': 'खाता जानकारी',
      'name': 'नाम',
      'phone': 'फोन',
      'email': 'ईमेल',
      'endpointId': 'एंडपॉइंट आईडी',
      'quickActions': 'त्वरित कार्य',
      'myQrCode': 'मेरा क्यूआर कोड',
      'changeLanguage': 'भाषा बदलें',
      'language': 'भाषा',
      'totalBalance': 'कुल शेष',
      'transactionHistory': 'लेनदेन इतिहास',
      'all': 'सभी',
      'sent': 'भेजे गए',
      'received': 'प्राप्त',
      'noTransactionsYet': 'अभी तक कोई लेनदेन नहीं।',
      'noSentTransactions': 'कोई भेजे गए लेनदेन नहीं',
      'noReceivedTransactions': 'कोई प्राप्त लेनदेन नहीं',
      'transactionsWillAppearHere': 'लेनदेन यहां दिखाई देंगे',
      'paying': 'भुगतान कर रहे हैं',
      'amount': 'रकम',
      'enterAmount': 'रकम दर्ज करें',
      'send': 'भेजें',
      'insufficientBalance': 'अपर्याप्त शेष',
      'waitingForSender': 'भेजने वाले की प्रतीक्षा कर रहे हैं...',
      'ensureBluetoothWifiOn': 'सुनिश्चित करें कि ब्लूटूथ और वाई-फाई चालू हैं।',
      'showThisQr': 'भेजने वाले को यह क्यूआर दिखाएं।',
      'scanQrCode': 'क्यूआर कोड स्कैन करें',
      'alignQrInsideFrame': 'स्कैन करने के लिए क्यूआर कोड को फ्रेम के अंदर संरेखित करें।',
      'editProfile': 'प्रोफाइल संपादित करें',
      'addressManagement': 'पता प्रबंधन',
      'helpAndSupport': 'सहायता और समर्थन',
      'logout': 'लॉग आउट',
      'save': 'सहेजें',
      'pendingSms': 'एसएमएस',
      'sendingNow': 'अभी भेज रहा है...',
      'queuedWaitingForGsm': 'कतार में · नेटवर्क सिग्नल की प्रतीक्षा कर रहा है',
      'hintDialpad': 'यदि ऑफ़लाइन हैं तो USSD/SMS फ़ॉलबैक के माध्यम से पैसे भेजने के लिए मैन्युअल रूप से मोबाइल नंबर दर्ज करें।',
      'clear': 'साफ़ करें',
      'enterNumber': 'नंबर दर्ज करें',
    },
    'kn': {
      'home': 'ಮುಖಪುಟ',
      'dialpad': 'ಡಯಲ್ ಪ್ಯಾಡ್',
      'wallet': 'ವಾಲೆಟ್',
      'history': 'ಇತಿಹಾಸ',
      'sendMoney': 'ಹಣ ಕಳುಹಿಸಿ',
      'receiveMoney': 'ಹಣ ಸ್ವೀಕರಿಸಿ',
      'scanQrToPay': 'ಪಾವತಿಸಲು ಸ್ಕ್ಯಾನ್ ಮಾಡಿ',
      'accountInfo': 'ಖಾತೆ ಮಾಹಿತಿ',
      'name': 'ಹೆಸರು',
      'phone': 'ಫೋನ್',
      'email': 'ಇಮೇಲ್',
      'endpointId': 'ಎಂಡ್‌ಪಾಯಿಂಟ್ ಐಡಿ',
      'quickActions': 'ತ್ವರಿತ ಕ್ರಿಯೆಗಳು',
      'myQrCode': 'ನನ್ನ ಕ್ಯೂಆರ್ ಕೋಡ್',
      'changeLanguage': 'ಭಾಷೆ ಬದಲಾಯಿಸಿ',
      'language': 'ಭಾಷೆ',
      'totalBalance': 'ಒಟ್ಟು ಬ್ಯಾಲೆನ್ಸ್',
      'transactionHistory': 'ವಹಿವಾಟು ಇತಿಹಾಸ',
      'all': 'ಎಲ್ಲಾ',
      'sent': 'ಕಳುಹಿಸಲಾಗಿದೆ',
      'received': 'ಸ್ವೀಕರಿಸಲಾಗಿದೆ',
      'noTransactionsYet': 'ಇನ್ನೂ ಯಾವುದೇ ವಹಿವಾಟುಗಳಿಲ್ಲ.',
      'noSentTransactions': 'ಯಾವುದೇ ಕಳುಹಿಸಿದ ವಹಿವಾಟುಗಳಿಲ್ಲ',
      'noReceivedTransactions': 'ಯಾವುದೇ ಸ್ವೀಕರಿಸಿದ ವಹಿವಾಟುಗಳಿಲ್ಲ',
      'transactionsWillAppearHere': 'ವಹಿವಾಟುಗಳು ಇಲ್ಲಿ ಕಾಣಿಸಿಕೊಳ್ಳುತ್ತವೆ',
      'paying': 'ಪಾವತಿಸಲಾಗುತ್ತಿದೆ',
      'amount': 'ಮೊತ್ತ',
      'enterAmount': 'ಮೊತ್ತವನ್ನು ನಮೂದಿಸಿ',
      'send': 'ಕಳುಹಿಸಿ',
      'insufficientBalance': 'ಸಾಕಷ್ಟು ಬ್ಯಾಲೆನ್ಸ್ ಇಲ್ಲ',
      'waitingForSender': 'ಕಳುಹಿಸುವವರಿಗಾಗಿ ಕಾಯಲಾಗುತ್ತಿದೆ...',
      'ensureBluetoothWifiOn': 'ಬ್ಲೂಟೂತ್ ಮತ್ತು ವೈ-ಫೈ ಆನ್ ಆಗಿದೆಯೇ ಎಂದು ಖಚಿತಪಡಿಸಿಕೊಳ್ಳಿ.',
      'showThisQr': 'ಕಳುಹಿಸುವವರಿಗೆ ಈ ಕ್ಯೂಆರ್ ತೋರಿಸಿ.',
      'scanQrCode': 'ಕ್ಯೂಆರ್ ಕೋಡ್ ಸ್ಕ್ಯಾನ್ ಮಾಡಿ',
      'alignQrInsideFrame': 'ಸ್ಕ್ಯಾನ್ ಮಾಡಲು ಫ್ರೇಮ್ ಒಳಗೆ ಕ್ಯೂಆರ್ ಕೋಡ್ ಅನ್ನು ಹೊಂದಿಸಿ.',
      'editProfile': 'ಪ್ರೊಫೈಲ್ ಸಂಪಾದಿಸಿ',
      'addressManagement': 'ವಿಳಾಸ ನಿರ್ವಹಣೆ',
      'helpAndSupport': 'ಸಹಾಯ ಮತ್ತು ಬೆಂಬಲ',
      'logout': 'ಲಾಗ್ ಔಟ್',
      'save': 'ಉಳಿಸಿ',
      'pendingSms': 'ಎಸ್‌ಎಂಎಸ್',
      'sendingNow': 'ಈಗ ಕಳುಹಿಸಲಾಗುತ್ತಿದೆ...',
      'queuedWaitingForGsm': 'ಸರತಿಯಲ್ಲಿದೆ · ನೆಟ್‌ವರ್ಕ್ ಸಿಗ್ನಲ್‌ಗಾಗಿ ಕಾಯಲಾಗುತ್ತಿದೆ',
      'hintDialpad': 'ಆಫ್‌ಲೈನ್ ಆಗಿದ್ದರೆ USSD/SMS ಫಾಲ್‌ಬ್ಯಾಕ್ ಮೂಲಕ ಹಣವನ್ನು ಕಳುಹಿಸಲು ಮೊಬೈಲ್ ಸಂಖ್ಯೆಯನ್ನು ಹಸ್ತಚಾಲಿತವಾಗಿ ನಮೂದಿಸಿ.',
      'clear': 'ಅಳಿಸಿ',
      'enterNumber': 'ಸಂಖ್ಯೆಯನ್ನು ನಮೂದಿಸಿ',
    },
  };
}

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
