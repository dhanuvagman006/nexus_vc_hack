import 'package:flutter/foundation.dart';
import 'dart:math';

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
  String myEndpointId = (Random().nextInt(900000) + 100000).toString(); // e.g. "123456"

  double balance = 1000.00;
  List<Transaction> transactions = [];

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