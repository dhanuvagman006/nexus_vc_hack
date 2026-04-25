import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'state/app_state.dart';
import 'services/sms_queue_service.dart';
import 'services/sms_balance_service.dart';
import 'services/radar_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Start the SMS queue service — it will watch connectivity and flush pending SMS
  await SmsQueueService.instance.init();
  SmsBalanceService.instance.init(); // start listening for BPAY balance-update SMS

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        // Expose the already-initialized singleton so widgets can listen to it
        ChangeNotifierProvider<SmsQueueService>.value(value: SmsQueueService.instance),
        ChangeNotifierProvider(create: (_) => RadarService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Listen for BPAY balance-update SMS and sync AppState.
    // Stream callbacks are synchronous w.r.t. the event loop — not async gaps —
    // but we still guard with mounted for safety after widget removal.
    SmsBalanceService.instance.balanceUpdates.listen((update) {
      if (!mounted) return;

      // ignore: use_build_context_synchronously
      final appState = Provider.of<AppState>(context, listen: false);
      appState.syncBalance(update.newBalance);

      final label = update.type == 'S' ? 'Payment confirmed' : 'Money received';
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$label · ₹${update.amount.toStringAsFixed(2)} · '
            'Balance: ₹${update.newBalance.toStringAsFixed(2)}',
          ),
          backgroundColor: update.type == 'R' ? Colors.green : Colors.blueAccent,
          duration: const Duration(seconds: 4),
        ),
      );
    });
  }

  @override
  void dispose() {
    SmsBalanceService.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BluePay',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkRegistration();
  }

  Future<void> _checkRegistration() async {
    // Artificial delay to show the splash screen
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    final prefs = await SharedPreferences.getInstance();
    final userPin = prefs.getString('userPin');
    
    if (userPin == null || userPin.isEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const RegisterScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4FC3F7), Color(0xFF1565C0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/logo/logo.jpg',
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'BluePay',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Offline Rural Payments',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
