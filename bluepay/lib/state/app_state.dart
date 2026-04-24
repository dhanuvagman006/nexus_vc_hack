import 'package:flutter/foundation.dart';
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
}

class AppState extends ChangeNotifier {
  // Demo baseline configuration
  String currentUserName = 'Alexey G.';
  String userEmail = 'alexey.g@example.com';
  String userPhone = '';
  String userAddress = '';
  String myEndpointId = (Random().nextInt(900000) + 100000).toString(); // e.g. "123456"

  double balance = 1000.00;
  List<Transaction> transactions = [];

  AppState() {
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    currentUserName = prefs.getString('currentUserName') ?? 'Alexey G.';
    userEmail = prefs.getString('userEmail') ?? 'alexey.g@example.com';
    userPhone = prefs.getString('userPhone') ?? '';
    userAddress = prefs.getString('userAddress') ?? '';
    notifyListeners();
  }

  Future<void> saveProfileData({
    required String name,
    required String email,
    required String phone,
  }) async {
    currentUserName = name;
    userEmail = email;
    userPhone = phone;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentUserName', currentUserName);
    await prefs.setString('userEmail', userEmail);
    await prefs.setString('userPhone', userPhone);
    
    notifyListeners();
  }

  Future<void> saveAddress(String address) async {
    userAddress = address;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userAddress', userAddress);
    notifyListeners();
  }

  void receiveMoney(double amount, String senderName) {
    balance += amount;
    transactions.insert(
      0,
      Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        counterpartName: senderName,
        amount: amount,
        isPositive: true,
        date: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void sendMoney(double amount, String receiverName) {
    if (balance >= amount) {
      balance -= amount;
      transactions.insert(
        0,
        Transaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          counterpartName: receiverName,
          amount: amount,
          isPositive: false,
          date: DateTime.now(),
        ),
      );
      notifyListeners();
    }
  }
}