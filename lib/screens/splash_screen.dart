import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../services/connectivity_service.dart';
import '../widgets/no_internet_dialog.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  final ConnectivityService _connectivityService = ConnectivityService();
  String _loadingMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();

    // Start the initialization process with connectivity check
    _initializeApp();
  }

  // SIMPLIFIED: Initialize app - global connectivity monitoring handles connectivity
  void _initializeApp() async {
    try {
      print('🚀 SplashScreen: Starting app initialization...');

      // Wait for animation to complete
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // The ConnectivityWrapper will handle connectivity monitoring globally
      // Just proceed with authentication check
      await _checkAuthAndNavigate();
    } catch (e) {
      print('❌ SplashScreen: Error during app initialization: $e');
      if (mounted) {
        _updateLoadingMessage('Initialization failed');
        // Fallback to onboarding in case of error
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    }
  }

  // NEW: Update loading message with state management
  void _updateLoadingMessage(String message) {
    if (mounted) {
      setState(() {
        _loadingMessage = message;
      });
    }
    print('📝 SplashScreen: $message');
  }

  // UPDATED: Enhanced auth check with proper initialization waiting
  Future<void> _checkAuthAndNavigate() async {
    try {
      print('🚀 SplashScreen: Starting auth check...');
      _updateLoadingMessage('Checking authentication...');

      if (mounted) {
        final authProvider = context.read<AuthProvider>();

        print('📱 SplashScreen: AuthProvider obtained, waiting for initialization...');
        _updateLoadingMessage('Initializing authentication...');

        // CRITICAL: Wait for AuthProvider to be fully initialized
        await authProvider.waitForInitialization();

        print('✅ SplashScreen: AuthProvider initialized');
        print('👤 SplashScreen: User authenticated: ${authProvider.isAuthenticated}');

        if (!mounted) return;

        // Check if user is already authenticated
        if (authProvider.isAuthenticated) {
          print('🏠 SplashScreen: User is authenticated, navigating to home');
          _updateLoadingMessage('Welcome back!');

          // Additional safety check: ensure user profile is loaded
          if (authProvider.userProfile == null) {
            print('⚠️ SplashScreen: User authenticated but no profile, trying to load...');
            _updateLoadingMessage('Loading profile...');
            // Give a moment for profile to load if it's in progress
            await Future.delayed(const Duration(milliseconds: 500));
          }

          // Navigate to home
          _updateLoadingMessage('Entering app...');
          await Future.delayed(const Duration(milliseconds: 300)); // Brief pause for UX
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          print('📝 SplashScreen: User not authenticated, navigating to onboarding');
          _updateLoadingMessage('Setting up...');
          // User is not logged in, show onboarding
          await Future.delayed(const Duration(milliseconds: 300)); // Brief pause for UX
          Navigator.pushReplacementNamed(context, '/onboarding');
        }
      }
    } catch (e) {
      print('❌ SplashScreen: Error during auth check: $e');
      _updateLoadingMessage('Authentication failed');

      // Fallback: navigate to onboarding in case of error
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 500)); // Give user time to see error
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
                              : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: (isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB)).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.smart_toy,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'LawBot',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI Legal Assistant',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Loading indicator
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Dynamic loading status text
                    Text(
                      _loadingMessage,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}