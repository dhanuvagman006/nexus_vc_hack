import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class Transaction {
  final String id;
  final String counterpartName;
  final double amount;
  final bool isPositive;
  final DateTime date;

  Transaction({
    required this.id,
    required this.counterpartName,
    required this.amount,
    required this.isPositive,
    required this.date,
  });

  /// Serialize to a JSON-compatible map
  Map<String, dynamic> toJson() => {
        'id': id,
        'counterpartName': counterpartName,
        'amount': amount,
        'isPositive': isPositive,
        'date': date.toIso8601String(),
      };

  /// Reconstruct from a JSON map
  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as String,
        counterpartName: json['counterpartName'] as String,
        amount: (json['amount'] as num).toDouble(),
        isPositive: json['isPositive'] as bool,
        date: DateTime.parse(json['date'] as String),
      );
}

class AppState extends ChangeNotifier {
  // ── in-memory state ──────────────────────────────────────────────────────
  String currentUserName = 'Alexey G.';
  String userEmail = 'alexey.g@example.com';
  String userPhone = '';
  String userAddress = '';
  String myEndpointId = '';
  String locale = 'en'; // default to English

  double balance = 1000.00;
  List<Transaction> transactions = [];

  // ── SharedPreferences keys ────────────────────────────────────────────────
  static const _kName = 'currentUserName';
  static const _kEmail = 'userEmail';
  static const _kPhone = 'userPhone';
  static const _kAddress = 'userAddress';
  static const _kEndpointId = 'myEndpointId';
  static const _kBalance = 'balance';
  static const _kTransactions = 'transactions';
  static const _kLocale = 'app_locale';

  AppState() {
    _loadAll();
  }

  // ── Load everything from disk on startup ──────────────────────────────────
  Future<void> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();

    currentUserName = prefs.getString(_kName) ?? 'Alexey G.';
    userEmail = prefs.getString(_kEmail) ?? 'alexey.g@example.com';
    userPhone = prefs.getString(_kPhone) ?? '';
    userAddress = prefs.getString(_kAddress) ?? '';
    locale = prefs.getString(_kLocale) ?? 'en';

    // Endpoint ID: generate once and persist so it stays stable across restarts
    final savedId = prefs.getString(_kEndpointId);
    if (savedId != null && savedId.isNotEmpty) {
      myEndpointId = savedId;
    } else {
      myEndpointId = (Random().nextInt(900000) + 100000).toString();
      await prefs.setString(_kEndpointId, myEndpointId);
    }

    balance = prefs.getDouble(_kBalance) ?? 1000.00;

    final raw = prefs.getString(_kTransactions);
    if (raw != null) {
      try {
        final List<dynamic> decoded = jsonDecode(raw);
        transactions =
            decoded.map((e) => Transaction.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {
        transactions = [];
      }
    }

    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Future<void> _saveBalanceAndTransactions(SharedPreferences prefs) async {
    await prefs.setDouble(_kBalance, balance);
    await prefs.setString(
      _kTransactions,
      jsonEncode(transactions.map((t) => t.toJson()).toList()),
    );
  }

  // ── Profile ───────────────────────────────────────────────────────────────
  Future<void> saveProfileData({
    required String name,
    required String email,
    required String phone,
  }) async {
    currentUserName = name;
    userEmail = email;
    userPhone = phone;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kName, currentUserName);
    await prefs.setString(_kEmail, userEmail);
    await prefs.setString(_kPhone, userPhone);

    notifyListeners();
  }

  Future<void> saveAddress(String address) async {
    userAddress = address;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAddress, userAddress);
    notifyListeners();
  }

  // ── Language ──────────────────────────────────────────────────────────────
  Future<void> setLocale(String newLocale) async {
    if (locale == newLocale) return;
    locale = newLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocale, locale);
    notifyListeners();
  }

  // ── Money operations ──────────────────────────────────────────────────────
  void receiveMoney(double amount, String counterpartId) {
    balance += amount;
    transactions.insert(
      0,
      Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        counterpartName: counterpartId,
        amount: amount,
        isPositive: true,
        date: DateTime.now(),
      ),
    );
    notifyListeners();
    _persistBalanceAndTransactions();
  }

  void sendMoney(double amount, String counterpartId) {
    if (balance >= amount) {
      balance -= amount;
      transactions.insert(
        0,
        Transaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          counterpartName: counterpartId,
          amount: amount,
          isPositive: false,
          date: DateTime.now(),
        ),
      );
      notifyListeners();
      _persistBalanceAndTransactions();
    }
  }

  /// Called when a BPAY balance-update SMS is received from the relay app.
  /// Overwrites local balance with the server-confirmed value and persists it.
  void syncBalance(double serverBalance) {
    balance = serverBalance;
    notifyListeners();
    _persistBalanceAndTransactions();
    debugPrint('[AppState] Balance synced from server: ₹$serverBalance');
  }

  /// Fire-and-forget save (runs async without blocking UI)
  void _persistBalanceAndTransactions() {
    SharedPreferences.getInstance().then((prefs) {
      _saveBalanceAndTransactions(prefs);
    });
  }
}