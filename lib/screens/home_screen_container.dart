import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lawbot/screens/tabs/resources_tabs.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import 'tabs/reports_tab.dart';
import 'tabs/history_tab.dart';
import 'tabs/notifications_tab.dart'; // NEW: Import notifications tab
import 'tabs/profile_tab.dart';
import 'tabs/settings_tab.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/realtime_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgresChangeFilter, PostgresChangeEvent, PostgresChangeFilterType;

class HomeScreenContainer extends StatefulWidget {
  const HomeScreenContainer({super.key});

  @override
  State<HomeScreenContainer> createState() => _HomeScreenContainerState();
}

class _HomeScreenContainerState extends State<HomeScreenContainer> {
  int _currentIndex = 0;
  RealtimeChannel? _userProfileChannel;
  RealtimeChannel? _notificationsChannel; // OLD: For real-time notifications (removed for frontend-only)

  @override
  void initState() {
    super.initState();
    // FIXED: Use post-frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscribeToUserProfile();
      _initializeRealtimeProvider();
      // _subscribeToNotifications(); // Removed for frontend-only notifications
    });
  }

  @override
  void dispose() {
    _userProfileChannel?.unsubscribe();
    // _notificationsChannel?.unsubscribe(); // Removed for frontend-only notifications
    super.dispose();
  }

  void _subscribeToUserProfile() async {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;
    if (userId == null) return;

    try {
      final supabase = Supabase.instance.client;
      _userProfileChannel = supabase.channel('public:user_profiles:user_status_$userId')
          .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'user_profiles',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'firebase_uid', value: userId),
        callback: (payload) async {
          final newStatus = payload.newRecord['user_status'];
          if (newStatus != null && newStatus != 'active') {
            // FIXED: Use post-frame callback to avoid setState during build
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (mounted) {
                await _handleSuspended();
              }
            });
          }
        },
      )
        ..subscribe();
    } catch (e) {
      print('Error subscribing to user profile changes: $e');
    }
  }

  // Initialize real-time provider for live notifications
  void _initializeRealtimeProvider() async {
    try {
      final realtimeProvider = Provider.of<RealtimeProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (authProvider.user != null) {
        print('🔄 Initializing real-time provider for user: ${authProvider.user!.uid}');
        await realtimeProvider.initialize();
        print('✅ Real-time provider initialized successfully');
      } else {
        print('⚠️ Cannot initialize real-time provider: User not authenticated');
      }
    } catch (e) {
      print('❌ Error initializing real-time provider: $e');
    }
  }

  // OLD: Subscribe to real-time notifications (removed for frontend-only)
  // void _subscribeToNotifications() async {
  //   Frontend-only notifications using sample data in NotificationProvider
  // }

  Future<void> _handleSuspended() async {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3B82F6).withOpacity(0.15) : const Color(0xFF2563EB).withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.block,
                    color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Account Suspended',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your account has been suspended. Please contact the admin for assistance.',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await authProvider.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/signin');
      }
    } catch (e) {
      print('Error handling suspended dialog: $e');
    }
  }

  // Method to change tab from external widgets
  void _changeTab(int index) {
    if (mounted) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  Future<bool?> _showExitConfirmationDialog(BuildContext context) async {
    final themeProvider = context.read<ThemeProvider>();
    final languageProvider = context.read<LanguageProvider>();
    final isDark = themeProvider.isDarkMode;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.exit_to_app,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Exit App?',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to exit LawBot?',
                style: TextStyle(
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF3B82F6).withOpacity(0.1)
                      : const Color(0xFF2563EB).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF3B82F6).withOpacity(0.3)
                        : const Color(0xFF2563EB).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your cybercrime reports and account data will be preserved when you return.',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Stay',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
                SystemNavigator.pop(); // This will completely exit the app
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.exit_to_app,
                    size: 18,
                    color: Colors.white,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Exit App',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final isDark = themeProvider.isDarkMode;

    // UPDATED: Create tabs with navigation callback and proper order
    final List<Widget> _tabs = [
      ReportsTab(onNavigateToTab: _changeTab),  // Index 0: Reports
      const ResourcesTab(),                     // Index 1: Resources
      const HistoryTab(),                       // Index 2: History
      const NotificationsTab(),                 // Index 3: Notifications (NEW)
      const ProfileTab(),                       // Index 4: Profile
      const SettingsTab(),                      // Index 5: Settings
    ];

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final shouldPop = await _showExitConfirmationDialog(context);
        if (shouldPop == true) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _tabs,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              if (mounted) {
                setState(() {
                  _currentIndex = index;
                });
              }
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
            unselectedItemColor: isDark ? Colors.grey[500] : Colors.grey[600],
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
            showSelectedLabels: true,
            showUnselectedLabels: true,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.report_problem_outlined),
                activeIcon: const Icon(Icons.report_problem),
                label: languageProvider.translate('reports') ?? 'Reports',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.library_books_outlined),
                activeIcon: const Icon(Icons.library_books),
                label: languageProvider.translate('resources') ?? 'Resources',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.history_outlined),
                activeIcon: const Icon(Icons.history),
                label: languageProvider.translate('history') ?? 'History',
              ),
              // Notifications tab (frontend-only, no badge)
              BottomNavigationBarItem(
                icon: const Icon(Icons.notifications_outlined),
                activeIcon: const Icon(Icons.notifications),
                label: languageProvider.translate('notifications') ?? 'Notifications',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline),
                activeIcon: const Icon(Icons.person),
                label: languageProvider.translate('profile') ?? 'Profile',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.settings_outlined),
                activeIcon: const Icon(Icons.settings),
                label: languageProvider.translate('settings') ?? 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}