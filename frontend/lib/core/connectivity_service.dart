import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamController<bool>? _connectionController;
  Stream<bool>? _connectionStream;
  bool _isConnected = true;

  Stream<bool> get connectionStream {
    _connectionController ??= StreamController<bool>.broadcast();
    _connectionStream ??= _connectionController!.stream;
    return _connectionStream!;
  }

  bool get isConnected => _isConnected;

  Future<void> initialize() async {
    // Check initial connection status
    final result = await _connectivity.checkConnectivity();
    _isConnected = _hasInternetConnection(result);
    _connectionController?.add(_isConnected);

    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((result) {
      final wasConnected = _isConnected;
      _isConnected = _hasInternetConnection(result);
      
      if (wasConnected != _isConnected) {
        debugPrint("🌐 Connectivity changed: ${_isConnected ? 'ONLINE' : 'OFFLINE'}");
        _connectionController?.add(_isConnected);
      }
    });
  }

  bool _hasInternetConnection(List<ConnectivityResult> result) {
    // Check if any connectivity result indicates internet access
    return result.any((r) => 
      r == ConnectivityResult.mobile ||
      r == ConnectivityResult.wifi ||
      r == ConnectivityResult.ethernet
    );
  }

  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _isConnected = _hasInternetConnection(result);
    return _isConnected;
  }

  void dispose() {
    _connectionController?.close();
    _connectionController = null;
    _connectionStream = null;
  }
}

