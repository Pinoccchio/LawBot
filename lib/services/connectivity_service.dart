import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();

  /// Check if device has network connectivity (WiFi or mobile data)
  Future<bool> hasNetworkConnectivity() async {
    try {
      final List<ConnectivityResult> connectivityResult = await _connectivity.checkConnectivity();
      
      // Check if we have any active connectivity
      return connectivityResult.any((result) => 
        result == ConnectivityResult.wifi || 
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet
      );
    } catch (e) {
      print('❌ Error checking network connectivity: $e');
      return false;
    }
  }

  /// Check if device has actual internet access by testing connection
  Future<bool> hasInternetAccess() async {
    try {
      // First check if we have network connectivity
      bool hasNetwork = await hasNetworkConnectivity();
      if (!hasNetwork) {
        print('📱 No network connectivity detected');
        return false;
      }

      print('📡 Network connectivity detected, testing internet access...');

      // Test actual internet connectivity with multiple reliable endpoints
      final List<String> testUrls = [
        'https://www.google.com',
        'https://www.cloudflare.com',
        'https://httpbin.org/status/200',
      ];

      // Try each URL with timeout
      for (String url in testUrls) {
        try {
          final response = await http.get(
            Uri.parse(url),
            headers: {'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'},
          ).timeout(const Duration(seconds: 5));

          if (response.statusCode >= 200 && response.statusCode < 300) {
            print('✅ Internet access confirmed via $url');
            return true;
          }
        } catch (e) {
          print('⚠️ Failed to connect to $url: $e');
          continue; // Try next URL
        }
      }

      print('❌ No internet access - all test URLs failed');
      return false;
    } catch (e) {
      print('❌ Error testing internet access: $e');
      return false;
    }
  }

  /// Get current connectivity status as a user-friendly string
  Future<String> getConnectivityStatus() async {
    try {
      final List<ConnectivityResult> connectivityResult = await _connectivity.checkConnectivity();
      
      if (connectivityResult.contains(ConnectivityResult.wifi)) {
        return 'WiFi';
      } else if (connectivityResult.contains(ConnectivityResult.mobile)) {
        return 'Mobile Data';
      } else if (connectivityResult.contains(ConnectivityResult.ethernet)) {
        return 'Ethernet';
      } else {
        return 'No Connection';
      }
    } catch (e) {
      print('❌ Error getting connectivity status: $e');
      return 'Unknown';
    }
  }

  /// Listen to connectivity changes
  Stream<List<ConnectivityResult>> get connectivityStream => _connectivity.onConnectivityChanged;

  /// Check connectivity with detailed logging for debugging
  Future<ConnectivityCheckResult> checkConnectivityDetailed() async {
    print('🔍 Starting detailed connectivity check...');
    
    final stopwatch = Stopwatch()..start();
    
    try {
      // Step 1: Check network connectivity
      bool hasNetwork = await hasNetworkConnectivity();
      String connectivityType = await getConnectivityStatus();
      
      print('📱 Network connectivity: $hasNetwork ($connectivityType)');
      
      if (!hasNetwork) {
        return ConnectivityCheckResult(
          hasNetwork: false,
          hasInternet: false,
          connectivityType: connectivityType,
          duration: stopwatch.elapsed,
          error: 'No network connectivity detected',
        );
      }

      // Step 2: Test internet access
      bool hasInternet = await hasInternetAccess();
      
      print('🌐 Internet access: $hasInternet');
      
      stopwatch.stop();
      
      return ConnectivityCheckResult(
        hasNetwork: hasNetwork,
        hasInternet: hasInternet,
        connectivityType: connectivityType,
        duration: stopwatch.elapsed,
        error: hasInternet ? null : 'Network connected but no internet access',
      );
    } catch (e) {
      stopwatch.stop();
      print('❌ Connectivity check failed: $e');
      
      return ConnectivityCheckResult(
        hasNetwork: false,
        hasInternet: false,
        connectivityType: 'Error',
        duration: stopwatch.elapsed,
        error: e.toString(),
      );
    }
  }

  /// Quick connectivity check (network only, no internet test)
  Future<bool> hasQuickConnectivity() async {
    try {
      return await hasNetworkConnectivity();
    } catch (e) {
      print('❌ Quick connectivity check failed: $e');
      return false;
    }
  }
}

/// Result class for detailed connectivity checking
class ConnectivityCheckResult {
  final bool hasNetwork;
  final bool hasInternet;
  final String connectivityType;
  final Duration duration;
  final String? error;

  ConnectivityCheckResult({
    required this.hasNetwork,
    required this.hasInternet,
    required this.connectivityType,
    required this.duration,
    this.error,
  });

  bool get isFullyConnected => hasNetwork && hasInternet;
  
  String get statusMessage {
    if (isFullyConnected) {
      return 'Connected via $connectivityType';
    } else if (hasNetwork && !hasInternet) {
      return 'Connected to $connectivityType but no internet access';
    } else {
      return 'No network connection';
    }
  }

  @override
  String toString() {
    return 'ConnectivityCheckResult(network: $hasNetwork, internet: $hasInternet, type: $connectivityType, duration: ${duration.inMilliseconds}ms, error: $error)';
  }
}