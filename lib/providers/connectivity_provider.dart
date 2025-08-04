import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/connectivity_service.dart';

class ConnectivityProvider extends ChangeNotifier {
  final ConnectivityService _connectivityService = ConnectivityService();
  
  // Current connectivity state
  bool _isConnected = true;
  bool _isChecking = false;
  String _connectionType = 'Unknown';
  DateTime? _lastDisconnectedAt;
  DateTime? _lastConnectedAt;
  
  // Stream subscription for connectivity changes
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _periodicCheckTimer;
  Timer? _reconnectionTimer;
  
  // Getters
  bool get isConnected => _isConnected;
  bool get isChecking => _isChecking;
  String get connectionType => _connectionType;
  DateTime? get lastDisconnectedAt => _lastDisconnectedAt;
  DateTime? get lastConnectedAt => _lastConnectedAt;
  
  // Configuration
  static const Duration _periodicCheckInterval = Duration(seconds: 30);
  static const Duration _reconnectionCheckInterval = Duration(seconds: 5);
  static const Duration _connectivityTestTimeout = Duration(seconds: 10);

  ConnectivityProvider() {
    _initializeConnectivityMonitoring();
  }

  /// Initialize connectivity monitoring with periodic checks
  void _initializeConnectivityMonitoring() {
    print('🌐 ConnectivityProvider: Initializing global connectivity monitoring');
    
    // Initial connectivity check
    _checkConnectivityState();
    
    // Listen to connectivity changes (network interface changes)
    _connectivitySubscription = _connectivityService.connectivityStream.listen(
      _onConnectivityChanged,
      onError: (error) {
        print('❌ ConnectivityProvider: Connectivity stream error: $error');
      },
    );
    
    // Start periodic connectivity checks (actual internet access)
    _startPeriodicConnectivityChecks();
  }

  /// Handle connectivity changes from the system
  void _onConnectivityChanged(List<ConnectivityResult> result) {
    print('📡 ConnectivityProvider: Network interface changed: $result');
    
    // Update connection type
    _updateConnectionType(result);
    
    // Check actual internet connectivity after a brief delay
    Timer(const Duration(milliseconds: 500), () {
      _checkConnectivityState();
    });
  }

  /// Update connection type based on connectivity result
  void _updateConnectionType(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi)) {
      _connectionType = 'WiFi';
    } else if (results.contains(ConnectivityResult.mobile)) {
      _connectionType = 'Mobile Data';
    } else if (results.contains(ConnectivityResult.ethernet)) {
      _connectionType = 'Ethernet';
    } else {
      _connectionType = 'No Connection';
    }
  }

  /// Start periodic connectivity checks to detect internet access issues
  void _startPeriodicConnectivityChecks() {
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = Timer.periodic(_periodicCheckInterval, (timer) {
      if (!_isChecking) {
        _checkConnectivityState();
      }
    });
    
    print('✅ ConnectivityProvider: Started periodic connectivity checks every ${_periodicCheckInterval.inSeconds}s');
  }

  /// Check current connectivity state
  Future<void> _checkConnectivityState() async {
    if (_isChecking) return; // Avoid overlapping checks
    
    _isChecking = true;
    notifyListeners();
    
    try {
      print('🔍 ConnectivityProvider: Checking connectivity state...');
      
      // Get detailed connectivity information
      final connectivityResult = await _connectivityService
          .checkConnectivityDetailed()
          .timeout(_connectivityTestTimeout);
      
      final bool wasConnected = _isConnected;
      _isConnected = connectivityResult.isFullyConnected;
      _connectionType = connectivityResult.connectivityType;
      
      // Handle state changes
      if (wasConnected && !_isConnected) {
        // Connection lost
        _lastDisconnectedAt = DateTime.now();
        _onConnectionLost();
        print('❌ ConnectivityProvider: Connection lost - ${connectivityResult.statusMessage}');
      } else if (!wasConnected && _isConnected) {
        // Connection restored
        _lastConnectedAt = DateTime.now();
        _onConnectionRestored();
        print('✅ ConnectivityProvider: Connection restored - ${connectivityResult.statusMessage}');
      } else if (_isConnected) {
        // Still connected
        _lastConnectedAt = DateTime.now();
        print('🟢 ConnectivityProvider: Connection stable - ${connectivityResult.statusMessage}');
      }
      
    } catch (e) {
      print('❌ ConnectivityProvider: Error checking connectivity: $e');
      // On error, assume disconnected
      if (_isConnected) {
        _isConnected = false;
        _lastDisconnectedAt = DateTime.now();
        _onConnectionLost();
      }
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  /// Handle connection lost event
  void _onConnectionLost() {
    // Stop periodic checks and start more frequent reconnection checks
    _periodicCheckTimer?.cancel();
    _startReconnectionChecks();
  }

  /// Handle connection restored event
  void _onConnectionRestored() {
    // Stop reconnection checks and resume normal periodic checks
    _reconnectionTimer?.cancel();
    _startPeriodicConnectivityChecks();
  }

  /// Start frequent checks when connection is lost
  void _startReconnectionChecks() {
    _reconnectionTimer?.cancel();
    _reconnectionTimer = Timer.periodic(_reconnectionCheckInterval, (timer) {
      if (!_isChecking) {
        _checkConnectivityState();
      }
    });
    
    print('🔄 ConnectivityProvider: Started reconnection checks every ${_reconnectionCheckInterval.inSeconds}s');
  }

  /// Manual connectivity check (called by user action like retry)
  Future<bool> checkConnectivityManually() async {
    print('🔄 ConnectivityProvider: Manual connectivity check requested');
    await _checkConnectivityState();
    return _isConnected;
  }

  /// Force a connectivity recheck
  Future<void> recheckConnectivity() async {
    await _checkConnectivityState();
  }

  /// Get connectivity status message
  String get statusMessage {
    if (_isChecking) {
      return 'Checking connection...';
    } else if (_isConnected) {
      return 'Connected via $_connectionType';
    } else {
      return 'No internet connection';
    }
  }

  /// Get time since last disconnection
  String? get timeSinceDisconnected {
    if (_lastDisconnectedAt == null) return null;
    
    final difference = DateTime.now().difference(_lastDisconnectedAt!);
    if (difference.inMinutes < 1) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }

  /// Pause connectivity monitoring (for testing or specific scenarios)
  void pauseMonitoring() {
    print('⏸️ ConnectivityProvider: Pausing connectivity monitoring');
    _connectivitySubscription?.pause();
    _periodicCheckTimer?.cancel();
    _reconnectionTimer?.cancel();
  }

  /// Resume connectivity monitoring
  void resumeMonitoring() {
    print('▶️ ConnectivityProvider: Resuming connectivity monitoring');
    _connectivitySubscription?.resume();
    _startPeriodicConnectivityChecks();
    _checkConnectivityState();
  }

  /// Get detailed connectivity information for debugging
  Map<String, dynamic> get debugInfo {
    return {
      'isConnected': _isConnected,
      'isChecking': _isChecking,
      'connectionType': _connectionType,
      'statusMessage': statusMessage,
      'lastDisconnectedAt': _lastDisconnectedAt?.toIso8601String(),
      'lastConnectedAt': _lastConnectedAt?.toIso8601String(),
      'timeSinceDisconnected': timeSinceDisconnected,
      'hasPeriodicTimer': _periodicCheckTimer?.isActive ?? false,
      'hasReconnectionTimer': _reconnectionTimer?.isActive ?? false,
    };
  }

  @override
  void dispose() {
    print('🗑️ ConnectivityProvider: Disposing connectivity monitoring');
    _connectivitySubscription?.cancel();
    _periodicCheckTimer?.cancel();
    _reconnectionTimer?.cancel();
    super.dispose();
  }

  // Static method to access the provider instance
  static ConnectivityProvider of(BuildContext context, {bool listen = true}) {
    if (listen) {
      return context.watch<ConnectivityProvider>();
    } else {
      return context.read<ConnectivityProvider>();
    }
  }
}