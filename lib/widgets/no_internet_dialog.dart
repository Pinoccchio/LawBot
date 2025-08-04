import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/connectivity_service.dart';

class NoInternetDialog extends StatefulWidget {
  final VoidCallback? onRetry;
  final VoidCallback? onExit;
  final String? customMessage;

  const NoInternetDialog({
    super.key,
    this.onRetry,
    this.onExit,
    this.customMessage,
  });

  @override
  State<NoInternetDialog> createState() => _NoInternetDialogState();
}

class _NoInternetDialogState extends State<NoInternetDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  bool _isRetrying = false;
  String _connectivityStatus = 'Checking...';
  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();
    _checkConnectivityStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _checkConnectivityStatus() async {
    try {
      final status = await _connectivityService.getConnectivityStatus();
      if (mounted) {
        setState(() {
          _connectivityStatus = status;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _connectivityStatus = 'Unknown';
        });
      }
    }
  }

  void _handleRetry() async {
    if (_isRetrying) return;

    setState(() {
      _isRetrying = true;
    });

    try {
      // Call the onRetry callback if provided (this will trigger connectivity provider check)
      if (widget.onRetry != null) {
        widget.onRetry!();
      } else {
        // Fallback: test connectivity directly
        final result = await _connectivityService.checkConnectivityDetailed();
        
        if (result.isFullyConnected) {
          // Connection successful - close dialog
          if (mounted) {
            Navigator.of(context).pop();
          }
        } else {
          // Still no connection - update status and show message
          if (mounted) {
            setState(() {
              _connectivityStatus = result.connectivityType;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ ${result.statusMessage}'),
                duration: const Duration(seconds: 3),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error checking connection: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  void _handleExit() {
    // Close dialog first
    Navigator.of(context).pop();
    
    // Call custom exit callback or exit app
    if (widget.onExit != null) {
      widget.onExit!();
    } else {
      // Exit the app
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false, // Prevent dismissing by back button
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Icon(
                      Icons.wifi_off_rounded,
                      size: 40,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Title
                  Text(
                    'No Internet Connection',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  
                  // Description
                  Text(
                    widget.customMessage ?? 
                    'Please check your internet connection and try again. Make sure WiFi or mobile data is enabled.',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey[300] : Colors.grey[600],
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Connectivity Status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getConnectivityIcon(),
                          size: 16,
                          color: _getConnectivityColor(),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Status: $_connectivityStatus',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    children: [
                      // Exit Button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _handleExit,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Exit App',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.grey[300] : Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Retry Button
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isRetrying ? null : _handleRetry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isRetrying
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Retry',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Troubleshooting Tips
                  const SizedBox(height: 20),
                  ExpansionTile(
                    title: Text(
                      'Troubleshooting Tips',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                    iconColor: isDark ? Colors.grey[300] : Colors.grey[700],
                    collapsedIconColor: isDark ? Colors.grey[400] : Colors.grey[500],
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTroubleshootingItem('• Turn WiFi off and on'),
                            _buildTroubleshootingItem('• Check mobile data is enabled'),
                            _buildTroubleshootingItem('• Move closer to WiFi router'),
                            _buildTroubleshootingItem('• Restart your device'),
                            _buildTroubleshootingItem('• Check with your internet provider'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTroubleshootingItem(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
    );
  }

  IconData _getConnectivityIcon() {
    switch (_connectivityStatus.toLowerCase()) {
      case 'wifi':
        return Icons.wifi;
      case 'mobile data':
        return Icons.signal_cellular_alt;
      case 'ethernet':
        return Icons.cable;
      case 'no connection':
        return Icons.signal_wifi_off;
      default:
        return Icons.help_outline;
    }
  }

  Color _getConnectivityColor() {
    switch (_connectivityStatus.toLowerCase()) {
      case 'wifi':
      case 'mobile data':
      case 'ethernet':
        return Colors.orange; // Connected but no internet
      case 'no connection':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

}