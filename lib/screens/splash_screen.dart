import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';

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

    // FIXED: Properly wait for auth initialization
    _checkAuthAndNavigate();
  }

  // FIXED: Enhanced auth check with proper initialization waiting
  void _checkAuthAndNavigate() async {
    try {
      print('🚀 SplashScreen: Starting auth check...');

      // Wait for animation to complete
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        final authProvider = context.read<AuthProvider>();

        print('📱 SplashScreen: AuthProvider obtained, waiting for initialization...');

        // CRITICAL: Wait for AuthProvider to be fully initialized
        await authProvider.waitForInitialization();

        print('✅ SplashScreen: AuthProvider initialized');
        print('👤 SplashScreen: User authenticated: ${authProvider.isAuthenticated}');

        if (!mounted) return;

        // Check if user is already authenticated
        if (authProvider.isAuthenticated) {
          print('🏠 SplashScreen: User is authenticated, navigating to home');

          // Additional safety check: ensure user profile is loaded
          if (authProvider.userProfile == null) {
            print('⚠️ SplashScreen: User authenticated but no profile, trying to load...');
            // Give a moment for profile to load if it's in progress
            await Future.delayed(const Duration(milliseconds: 500));
          }

          // Navigate to home
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          print('📝 SplashScreen: User not authenticated, navigating to onboarding');
          // User is not logged in, show onboarding
          Navigator.pushReplacementNamed(context, '/onboarding');
        }
      }
    } catch (e) {
      print('❌ SplashScreen: Error during auth check: $e');

      // Fallback: navigate to onboarding in case of error
      if (mounted) {
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
                    // Status text for debugging (remove in production)
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        String statusText = 'Initializing...';
                        if (authProvider.isInitialized) {
                          statusText = authProvider.isAuthenticated
                              ? 'Welcome back!'
                              : 'Setting up...';
                        }

                        return Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                          ),
                        );
                      },
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