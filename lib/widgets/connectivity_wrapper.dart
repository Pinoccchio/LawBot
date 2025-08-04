import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';
import '../widgets/no_internet_dialog.dart';

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;
  final bool showDebugInfo;

  const ConnectivityWrapper({
    super.key,
    required this.child,
    this.showDebugInfo = false,
  });

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  bool _isDialogShowing = false;
  ConnectivityProvider? _lastProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupConnectivityListener();
    });
  }

  void _setupConnectivityListener() {
    final connectivityProvider = context.read<ConnectivityProvider>();
    connectivityProvider.addListener(_onConnectivityChanged);
  }

  @override
  void dispose() {
    _lastProvider?.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  void _onConnectivityChanged() {
    if (!mounted) return;

    final connectivityProvider = context.read<ConnectivityProvider>();
    
    // Update listener reference
    if (_lastProvider != connectivityProvider) {
      _lastProvider?.removeListener(_onConnectivityChanged);
      _lastProvider = connectivityProvider;
    }

    final bool isConnected = connectivityProvider.isConnected;
    final bool isChecking = connectivityProvider.isChecking;

    print('🔔 ConnectivityWrapper: Connectivity changed - Connected: $isConnected, Checking: $isChecking, Dialog showing: $_isDialogShowing');

    // Show dialog when connection is lost (but not when checking)
    if (!isConnected && !isChecking && !_isDialogShowing) {
      _showNoInternetDialog();
    }
    
    // Hide dialog when connection is restored
    if (isConnected && _isDialogShowing) {
      _hideNoInternetDialog();
    }
  }

  void _showNoInternetDialog() {
    if (_isDialogShowing || !mounted) return;

    print('🚫 ConnectivityWrapper: Showing no internet dialog');
    _isDialogShowing = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return NoInternetDialog(
          onRetry: () async {
            print('🔄 ConnectivityWrapper: User requested connectivity retry');
            
            // Show loading state
            final connectivityProvider = context.read<ConnectivityProvider>();
            
            // Perform manual connectivity check
            final isConnected = await connectivityProvider.checkConnectivityManually();
            
            if (isConnected) {
              // Connection restored, dialog will be closed by the listener
              print('✅ ConnectivityWrapper: Connection restored via retry');
            } else {
              // Still no connection, show feedback
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Still no internet connection. Please check your network settings.'),
                    duration: const Duration(seconds: 3),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          onExit: () {
            print('🚪 ConnectivityWrapper: User chose to exit app');
            // Close dialog first
            if (_isDialogShowing) {
              Navigator.of(dialogContext).pop();
              _isDialogShowing = false;
            }
            // Exit the app
            // SystemNavigator.pop(); // This will be handled by the dialog itself
          },
          customMessage: 'LawBot requires an internet connection to function properly. Please check your WiFi or mobile data connection and try again.',
        );
      },
    ).then((_) {
      // Dialog was dismissed (shouldn't happen since barrierDismissible is false)
      print('🔄 ConnectivityWrapper: Dialog dismissed unexpectedly');
      _isDialogShowing = false;
    });
  }

  void _hideNoInternetDialog() {
    if (!_isDialogShowing || !mounted) return;

    print('✅ ConnectivityWrapper: Hiding no internet dialog - connection restored');
    _isDialogShowing = false;
    
    // Close the dialog
    Navigator.of(context).pop();
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Internet connection restored!'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivityProvider, child) {
        return Stack(
          children: [
            // Main app content
            widget.child,
            
            // Debug connectivity info (if enabled)
            if (widget.showDebugInfo)
              _buildDebugInfo(connectivityProvider),
            
            // Connectivity status indicator
            _buildConnectivityIndicator(connectivityProvider),
          ],
        );
      },
    );
  }

  Widget _buildDebugInfo(ConnectivityProvider connectivityProvider) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 10,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Connectivity Debug',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Connected: ${connectivityProvider.isConnected}',
              style: TextStyle(
                color: connectivityProvider.isConnected ? Colors.green : Colors.red,
                fontSize: 10,
              ),
            ),
            Text(
              'Type: ${connectivityProvider.connectionType}',
              style: TextStyle(color: Colors.white, fontSize: 10),
            ),
            Text(
              'Checking: ${connectivityProvider.isChecking}',
              style: TextStyle(color: Colors.orange, fontSize: 10),
            ),
            if (connectivityProvider.timeSinceDisconnected != null)
              Text(
                'Disconnected: ${connectivityProvider.timeSinceDisconnected}',
                style: TextStyle(color: Colors.yellow, fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectivityIndicator(ConnectivityProvider connectivityProvider) {
    // Only show indicator when checking or when connection is unstable
    if (!connectivityProvider.isChecking && connectivityProvider.isConnected) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + 50,
      right: 10,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: connectivityProvider.isChecking 
              ? Colors.orange 
              : Colors.red,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (connectivityProvider.isChecking ? Colors.orange : Colors.red).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (connectivityProvider.isChecking)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              Icon(
                Icons.wifi_off,
                size: 12,
                color: Colors.white,
              ),
            const SizedBox(width: 4),
            Text(
              connectivityProvider.isChecking 
                  ? 'Checking...' 
                  : 'No Internet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}