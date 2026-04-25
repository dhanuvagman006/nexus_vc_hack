import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

/// Possible states of the connectivity radar.
enum RadarState { scanning, found, notFound, permissionDenied }

/// RadarService performs passive Nearby Connections discovery to detect
/// other BluePay users who are advertising (i.e., have ReceiveScreen open).
///
/// It does NOT call requestConnection() — radar is read-only discovery only.
class RadarService extends ChangeNotifier {
  // ── Public state ──────────────────────────────────────────────────────────
  RadarState _state = RadarState.notFound;
  RadarState get state => _state;

  int _nearbyCount = 0;
  int get nearbyCount => _nearbyCount;

  // ── Private internals ─────────────────────────────────────────────────────
  final Set<String> _foundEndpoints = {};
  Timer? _scanTimer;        // 5-second window timer
  Timer? _periodicTimer;    // 30-second auto-rescan timer

  /// Must match the serviceId used in receive_screen.dart and
  /// qr_scanner_screen.dart exactly.
  static const String _serviceId = 'com.example.bluepay';
  static const Strategy _strategy = Strategy.P2P_CLUSTER;

  // ── Scan lifecycle ────────────────────────────────────────────────────────

  /// Starts a single 5-second discovery scan cycle.
  /// If permissions are missing it sets [state] to [RadarState.permissionDenied].
  Future<void> startScan() async {
    // 1. Request / verify permissions
    final granted = await _ensurePermissions();
    if (!granted) {
      _state = RadarState.permissionDenied;
      notifyListeners();
      return;
    }

    // 2. Prepare
    _foundEndpoints.clear();
    _state = RadarState.scanning;
    notifyListeners();

    // 3. Start discovery (passive — no requestConnection)
    try {
      await Nearby().startDiscovery(
        'radar',                       // userName — not used for connections
        _strategy,
        onEndpointFound: (String id, String endpointName, String serviceId) {
          _foundEndpoints.add(id);
        },
        onEndpointLost: (String? id) {
          if (id != null) _foundEndpoints.remove(id);
        },
        serviceId: _serviceId,
      );
    } on PlatformException catch (_) {
      // "Already discovering" — stop first, then retry once
      try {
        await Nearby().stopDiscovery();
        await Nearby().startDiscovery(
          'radar',
          _strategy,
          onEndpointFound: (String id, String endpointName, String serviceId) {
            _foundEndpoints.add(id);
          },
          onEndpointLost: (String? id) {
            if (id != null) _foundEndpoints.remove(id);
          },
          serviceId: _serviceId,
        );
      } catch (e) {
        // Give up — treat as not-found
        debugPrint('[RadarService] Discovery retry failed: $e');
        _state = RadarState.notFound;
        notifyListeners();
        return;
      }
    }

    // 4. After 5 seconds: stop discovery and evaluate
    _scanTimer?.cancel();
    _scanTimer = Timer(const Duration(seconds: 5), () async {
      try {
        await Nearby().stopDiscovery();
      } catch (_) {}

      _nearbyCount = _foundEndpoints.length;
      _state = _nearbyCount > 0 ? RadarState.found : RadarState.notFound;
      notifyListeners();
    });
  }

  /// Stops any active discovery and cancels timers.
  Future<void> stopScan() async {
    _scanTimer?.cancel();
    _scanTimer = null;
    _periodicTimer?.cancel();
    _periodicTimer = null;

    try {
      await Nearby().stopDiscovery();
    } catch (_) {}
  }

  /// Begin the auto-rescan loop (scan immediately, then every 30 s).
  void startAutoScan() {
    startScan(); // first scan right away
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      startScan();
    });
  }

  /// Cancel the auto-rescan loop and stop current scan.
  void stopAutoScan() {
    stopScan();
  }

  // ── Permissions ───────────────────────────────────────────────────────────

  /// Returns true if all required permissions are granted.
  Future<bool> _ensurePermissions() async {
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.location,
      Permission.nearbyWifiDevices,
    ].request();

    // If any is permanently denied we cannot proceed
    if (statuses.values.any((s) => s.isPermanentlyDenied)) {
      return false;
    }

    // Check the critical ones are granted
    final critical = [
      statuses[Permission.bluetoothScan],
      statuses[Permission.location],
    ];
    if (critical.any((s) => s == null || s.isDenied)) {
      return false;
    }

    return true;
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    stopScan();
    super.dispose();
  }
}
