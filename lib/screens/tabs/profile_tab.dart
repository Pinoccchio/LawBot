import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/database_service.dart';
import '../../utils/philippine_time.dart';
import '../../widgets/tiktok_avatar.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _isUploading = false;
  bool _isDeleting = false;
  bool _isRefreshing = false;
  bool _isLoadingData = true;
  bool? _wasAuthenticated;
  final DatabaseService _databaseService = DatabaseService();

  // Real-time subscription
  RealtimeChannel? _profileSubscription;
  final SupabaseClient _supabase = Supabase.instance.client;

  // Add a key to force TikTokAvatar rebuild
  Key _avatarKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _wasAuthenticated = authProvider.isAuthenticated;
    _loadUserData();
  }

  @override
  void dispose() {
    _cleanupRealtimeSubscription();
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated || authProvider.user?.uid == null) {
      return;
    }

    try {
      _profileSubscription = _supabase
          .channel('profile_changes_${authProvider.user!.uid}')
          .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'user_profiles',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'firebase_uid',
          value: authProvider.user!.uid,
        ),
        callback: (payload) {
          print('🔄 Profile updated from external source');
          _handleProfileUpdate(payload);
        },
      )
          .subscribe();
      print('✅ Real-time subscription setup for profile updates');
    } catch (e) {
      print('❌ Error setting up real-time subscription: $e');
    }
  }

  void _cleanupRealtimeSubscription() {
    if (_profileSubscription != null) {
      _supabase.removeChannel(_profileSubscription!);
      _profileSubscription = null;
      print('🧹 Cleaned up real-time subscription');
    }
  }

  void _handleProfileUpdate(PostgresChangePayload payload) {
    if (!mounted) return;

    try {
      final newRecord = payload.newRecord;
      print('📱 Profile update received: $newRecord');

      // Update the AuthProvider with new profile data
      final authProvider = context.read<AuthProvider>();
      authProvider.updateUserProfileFromRealtime(newRecord);

      // Force avatar rebuild by generating new key
      setState(() {
        _avatarKey = UniqueKey();
      });

      // Show a subtle notification to the user
      _showProfileUpdateNotification();

      // Clear image cache for the new profile picture
      _clearProfileImageCache(newRecord['profile_picture_url']);

    } catch (e) {
      print('❌ Error handling profile update: $e');
    }
  }

  // Enhanced cache clearing method
  Future<void> _clearProfileImageCache(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return;

    try {
      // Clear from default cache manager
      await DefaultCacheManager().removeFile(imageUrl);

      // Also clear from network image cache
      await DefaultCacheManager().emptyCache();

      print('✅ Profile image cache cleared for: $imageUrl');
    } catch (e) {
      print('⚠️ Cache clear error: $e');
    }
  }

  void _showProfileUpdateNotification() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.sync,
              color: Colors.white,
              size: 16,
            ),
            SizedBox(width: 8),
            Text(
              'Profile updated',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingData = true;
      _isRefreshing = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isAuthenticated) {
        print('🔄 Loading user data - refreshing profile and other data...');

        // Clear all cached images before refreshing
        try {
          await DefaultCacheManager().emptyCache();
          print('✅ All image cache cleared for refresh');
        } catch (cacheError) {
          print('⚠️ Cache clear error (non-critical): $cacheError');
        }

        // Refresh user profile data from database
        await authProvider.refreshUserProfile();

        // Force avatar rebuild
        setState(() {
          _avatarKey = UniqueKey();
          _isLoadingData = false;
          _isRefreshing = false;
        });

        print('✅ User data loaded successfully');
      } else {
        setState(() {
          _isLoadingData = false;
          _isRefreshing = false;
        });
        _cleanupRealtimeSubscription();
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoadingData = false;
          _isRefreshing = false;
        });
        _showErrorSnackBar('Failed to refresh data. Please try again.');
      }
    }
  }

  void _handleAuthStateChange() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isAuthenticated) {
      _setupRealtimeSubscription();
      _loadUserData();
    } else {
      _cleanupRealtimeSubscription();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isDark = themeProvider.isDarkMode;

    if (_isDeleting) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
              ),
              const SizedBox(height: 24),
              Text(
                'Deleting account...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait while we delete your account and data',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        title: Text(
          languageProvider.translate('profile') ?? 'Profile',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          if (authProvider.isAuthenticated) ...[
            _isRefreshing
                ? Container(
              margin: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isDark ? Colors.white : const Color(0xFF2563EB),
                ),
              ),
            )
                : IconButton(
              onPressed: _loadUserData,
              icon: Icon(
                Icons.refresh_rounded,
                color: isDark ? Colors.white : const Color(0xFF2563EB),
              ),
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (authProvider.isAuthenticated) ...[
                          Stack(
                            children: [
                              GestureDetector(
                                onTap: () => _showImagePreview(authProvider.userProfile?['profile_picture_url']),
                                child: TikTokAvatar(
                                  key: _avatarKey,
                                  imageUrl: authProvider.userProfile?['profile_picture_url'] ?? '',
                                  size: 120,
                                  isEditable: false,
                                ),
                              ),
                              if (_isUploading)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                              if (!_isUploading)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _showImagePickerOptions,
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ] else
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isDark
                                    ? [const Color(0xFF3B82F6).withOpacity(0.2), const Color(0xFF1D4ED8).withOpacity(0.2)]
                                    : [const Color(0xFF2563EB).withOpacity(0.1), const Color(0xFF1D4ED8).withOpacity(0.1)],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                                width: 3,
                              ),
                            ),
                            child: Icon(
                              Icons.person_outline,
                              size: 50,
                              color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                            ),
                          ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                authProvider.isAuthenticated
                                    ? (authProvider.userProfile?['full_name'] ??
                                    authProvider.user?.displayName ??
                                    'User')
                                    : languageProvider.translate('guest_user') ?? 'Guest User',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.email_outlined,
                                    size: 16,
                                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      authProvider.isAuthenticated
                                          ? (authProvider.user?.email ?? 'No email')
                                          : 'Not signed in',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                        height: 1.3,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(
                                    Icons.lock_outline,
                                    size: 16,
                                    color: isDark ? Colors.grey[600] : Colors.grey[500],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (!authProvider.isAuthenticated)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 20),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(context, '/signin');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Rest of your existing UI code...
              if (authProvider.isAuthenticated) ...[
                // Account Information Section
                _buildSectionHeader(
                  icon: Icons.account_circle_outlined,
                  title: 'Account Information',
                  isDark: isDark,
                ),
                _buildInfoCard(
                  icon: Icons.person_outline,
                  title: 'Full Name',
                  value: authProvider.userProfile?['full_name'] ??
                      authProvider.user?.displayName ??
                      'Not set',
                  isDark: isDark,
                  isEditable: true,
                  onTap: () => _showEditNameDialog(context, authProvider),
                ),
                _buildInfoCard(
                  icon: Icons.email_outlined,
                  title: 'Email Address',
                  value: authProvider.user?.email ?? 'No email',
                  isDark: isDark,
                  isEditable: false,
                ),
                _buildInfoCard(
                  icon: Icons.phone_outlined,
                  title: 'Phone Number',
                  value: authProvider.userProfile?['phone_number'] ?? 'Not provided',
                  isDark: isDark,
                  isEditable: true,
                  onTap: () => _showEditPhoneDialog(context, authProvider),
                ),
                _buildInfoCard(
                  icon: Icons.account_box_outlined,
                  title: 'User Type',
                  value: authProvider.userProfile?['user_type'] ?? 'CLIENT',
                  isDark: isDark,
                  isEditable: false,
                ),
                _buildInfoCard(
                  icon: Icons.info_outline,
                  title: 'Account Status',
                  value: (authProvider.userProfile?['user_status'] ?? 'active').toString().toUpperCase(),
                  isDark: isDark,
                  isEditable: false,
                ),
                _buildInfoCard(
                  icon: Icons.calendar_today_outlined,
                  title: 'Member Since',
                  value: authProvider.userProfile?['created_at'] != null
                      ? PhilippineTime.formatDatabaseTime(authProvider.userProfile!['created_at'])
                      : 'Recently joined',
                  isDark: isDark,
                  isEditable: false,
                ),
                _buildInfoCard(
                  icon: Icons.delete_forever_outlined,
                  title: 'Delete Account',
                  value: 'Permanently delete your account and data',
                  isDark: isDark,
                  isEditable: true,
                  isDestructive: true,
                  onTap: () => _showDeleteAccountDialog(context, authProvider),
                ),

                // Cybercrime reporting system features section
                _buildSectionHeader(
                  icon: Icons.report_outlined,
                  title: 'Report Activity',
                  isDark: isDark,
                ),
                _buildEmptyStateCard(
                  isDark: isDark,
                  icon: Icons.report_problem_outlined,
                  title: 'No cybercrime reports yet',
                  description: 'Submit your first cybercrime report in the Reports tab',
                ),
              ] else
                _buildGuestContent(isDark),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircularProgressIndicator(
              color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
              strokeWidth: 2,
            ),
            const SizedBox(width: 16),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestContent(bool isDark) {
    return Column(
      children: [
        _buildSectionHeader(
          icon: Icons.info_outline,
          title: 'Sign In Benefits',
          isDark: isDark,
        ),
        _buildBenefitCard(
          icon: Icons.report_outlined,
          title: 'Cybercrime Reports',
          description: 'Submit and track your cybercrime reports to PNP',
          isDark: isDark,
        ),
        _buildBenefitCard(
          icon: Icons.history_outlined,
          title: 'Report History',
          description: 'View status and track progress of your reports',
          isDark: isDark,
        ),
        _buildBenefitCard(
          icon: Icons.security_outlined,
          title: 'Secure Storage',
          description: 'Safely store evidence files and sensitive information',
          isDark: isDark,
        ),
        _buildBenefitCard(
          icon: Icons.sync,
          title: 'Sync Across Devices',
          description: 'Access your reports from any device, anywhere',
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
    bool isEditable = false,
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    final cardColor = isDestructive
        ? (isDark ? Colors.red.withOpacity(0.1) : Colors.red.withOpacity(0.05))
        : (isDark ? const Color(0xFF1E293B) : Colors.white);
    final iconColor = isDestructive
        ? Colors.red
        : (isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEditable ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: cardColor,
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDestructive
                          ? Colors.red.withOpacity(0.2)
                          : (isDark
                          ? const Color(0xFF3B82F6).withOpacity(0.2)
                          : const Color(0xFF2563EB).withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDestructive
                            ? Colors.red.withOpacity(0.5)
                            : (isDark
                            ? const Color(0xFF3B82F6).withOpacity(0.5)
                            : const Color(0xFF2563EB).withOpacity(0.3)),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDestructive
                                ? Colors.red
                                : (isDark ? Colors.grey[400] : Colors.grey[600]),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDestructive
                                ? Colors.red.withOpacity(0.9)
                                : (isDark ? Colors.white : Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isEditable && isDestructive)
                    const Icon(
                      Icons.delete_forever,
                      size: 20,
                      color: Colors.red,
                    )
                  else if (isEditable)
                    Icon(
                      Icons.edit,
                      size: 16,
                      color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                    )
                  else if (!isEditable && title == 'Email Address')
                      Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: isDark ? Colors.grey[600] : Colors.grey[500],
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF3B82F6).withOpacity(0.2)
                    : const Color(0xFF2563EB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF3B82F6).withOpacity(0.5)
                      : const Color(0xFF2563EB).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required bool isDark,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF3B82F6).withOpacity(0.2)
                  : const Color(0xFF2563EB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF3B82F6).withOpacity(0.5)
                    : const Color(0xFF2563EB).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          if (actionText != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionText,
                style: TextStyle(
                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Image preview and picker methods
  void _showImagePreview(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return;
    final isDark = context.read<ThemeProvider>().isDarkMode;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.7),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent,
              ),
            ),
            Center(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.network(
                    imageUrl,
                    width: 300,
                    height: 300,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_outline,
                        size: 100,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 60,
              right: 30,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePickerOptions() {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    final authProvider = context.read<AuthProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Change Profile Picture',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF3B82F6).withOpacity(0.1)
                      : const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                ),
              ),
              title: Text(
                'Take a photo',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, authProvider);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF3B82F6).withOpacity(0.1)
                      : const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.photo_library,
                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                ),
              ),
              title: Text(
                'Choose from gallery',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, authProvider);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, AuthProvider authProvider) async {
    if (!mounted) return;
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        await _uploadProfilePicture(image.path, authProvider);
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to pick image. Please try again.');
      }
    }
  }

  // Enhanced upload method with better cache management and UI updates
  Future<void> _uploadProfilePicture(String imagePath, AuthProvider authProvider) async {
    if (!mounted) return;

    setState(() {
      _isUploading = true;
    });

    final databaseService = DatabaseService();

    try {
      // Step 1: Upload the image
      final imageUrl = await databaseService.uploadProfilePicture(imagePath);
      print('✅ Image uploaded successfully: $imageUrl');

      if (mounted) {
        // Step 2: Clear all image caches BEFORE updating profile
        try {
          await DefaultCacheManager().emptyCache();
          print('✅ All image cache cleared before profile update');
        } catch (cacheError) {
          print('⚠️ Cache clear error (non-critical): $cacheError');
        }

        // Step 3: Update profile with new image URL
        final success = await authProvider.updateProfile(
          fullName: authProvider.userProfile?['full_name'] ??
              authProvider.user?.displayName ??
              'User',
          profilePictureUrl: imageUrl,
        );

        if (success && mounted) {
          // Step 4: Force UI refresh with new avatar key
          setState(() {
            _avatarKey = UniqueKey(); // This forces TikTokAvatar to rebuild
          });

          // Step 5: Show success message
          _showSuccessSnackBar('Profile picture updated successfully!');

          // Step 6: Additional refresh after a short delay to ensure everything is updated
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() {
                // Additional state refresh
              });
            }
          });

          print('✅ Profile picture update completed');
        }
      }
    } catch (e) {
      print('❌ Error uploading profile picture: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to upload profile picture. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  // Dialog methods
  Future<void> _showEditPhoneDialog(BuildContext context, AuthProvider authProvider) async {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    final phoneController = TextEditingController(
      text: authProvider.userProfile?['phone_number'] ?? '',
    );
    bool isSaving = false;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              title: Text(
                'Edit Phone Number',
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter your phone number',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                          fontSize: 16,
                        ),
                        prefixIcon: Icon(
                          Icons.phone_outlined,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          size: 20,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                    final newPhone = phoneController.text.trim();

                    // Allow empty phone number (optional field)
                    if (newPhone.isNotEmpty && newPhone.length < 10) {
                      _showErrorSnackBar('Phone number must be at least 10 digits');
                      return;
                    }

                    setState(() {
                      isSaving = true;
                    });

                    try {
                      await authProvider.updateProfile(
                        fullName: authProvider.userProfile?['full_name'] ??
                            authProvider.user?.displayName ?? 'User',
                        profilePictureUrl: authProvider.userProfile?['profile_picture_url'],
                        phoneNumber: newPhone.isEmpty ? null : newPhone,
                      );
                      _showSuccessSnackBar('Phone number updated successfully!');
                      Navigator.of(dialogContext).pop();
                    } catch (e) {
                      print('Error updating phone: $e');
                      _showErrorSnackBar('Failed to update phone number. Please try again.');
                    } finally {
                      setState(() {
                        isSaving = false;
                      });
                    }
                  },
                  child: isSaving
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditNameDialog(BuildContext context, AuthProvider authProvider) async {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    final nameController = TextEditingController(
      text: authProvider.userProfile?['full_name'] ?? authProvider.user?.displayName ?? '',
    );
    bool isSaving = false;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              title: Text(
                'Edit Full Name',
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    TextFormField(
                      controller: nameController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        hintText: 'Enter your new name',
                        hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                    final newName = nameController.text.trim();
                    if (newName.isEmpty) {
                      _showErrorSnackBar('Name cannot be empty');
                      return;
                    }
                    if (newName.length < 2) {
                      _showErrorSnackBar('Name must be at least 2 characters long');
                      return;
                    }

                    setState(() {
                      isSaving = true;
                    });

                    try {
                      await authProvider.updateProfile(
                        fullName: newName,
                        profilePictureUrl: authProvider.userProfile?['profile_picture_url'],
                      );
                      _showSuccessSnackBar('Name updated successfully!');
                      Navigator.of(dialogContext).pop();
                    } catch (e) {
                      print('Error updating name: $e');
                      _showErrorSnackBar('Failed to update name. Please try again.');
                    } finally {
                      setState(() {
                        isSaving = false;
                      });
                    }
                  },
                  child: isSaving
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showDeleteAccountDialog(BuildContext context, AuthProvider authProvider) async {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    final passwordController = TextEditingController();
    bool isDeleting = false;
    bool showPassword = false;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              title: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_outlined,
                    color: Colors.red,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Delete Account',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Are you sure you want to delete your account?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This action will:',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[300] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...[
                      '• Permanently delete your profile',
                      '• Remove all chat history',
                      '• Delete saved legal advice',
                      '• Remove all personal data',
                      '• Sign you out immediately',
                    ].map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    )),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_outlined,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'This action cannot be undone!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Enter your password to confirm:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordController,
                      obscureText: !showPassword,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        hintText: 'Enter your current password',
                        hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            showPassword ? Icons.visibility : Icons.visibility_off,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          onPressed: () {
                            setState(() {
                              showPassword = !showPassword;
                            });
                          },
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF334155) : Colors.grey[50],
                      ),
                    ),
                    if (authProvider.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                authProvider.errorMessage!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () {
                    authProvider.clearError();
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isDeleting ? null : () async {
                    if (passwordController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter your password'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    setState(() {
                      isDeleting = true;
                    });

                    authProvider.clearError();

                    try {
                      final success = await authProvider.deleteAccount(passwordController.text.trim());
                      if (success) {
                        Navigator.of(dialogContext).pop();
                        Navigator.of(context).pushNamedAndRemoveUntil('/signin', (route) => false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Account deleted successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        setState(() {
                          isDeleting = false;
                        });
                      }
                    } catch (e) {
                      setState(() {
                        isDeleting = false;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: isDeleting
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text('Delete Account'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return 'Recently joined';
    }
  }

  String _formatDateWithTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];

      // Format time in 12-hour format
      final hour = date.hour;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

      return '${months[date.month - 1]} ${date.day}, ${date.year} at ${displayHour}:${minute} ${period}';
    } catch (e) {
      return 'Recently joined';
    }
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else {
        final months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
      }
    } catch (e) {
      return 'Not available';
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
