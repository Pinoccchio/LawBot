import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/database_service.dart';
import '../../utils/philippine_time.dart';
import '../../widgets/tiktok_avatar.dart';
import '../saved_advice_screen.dart';
import '../recent_cases_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _isUploading = false;
  bool _isDeleting = false;
  List<Map<String, dynamic>> _recentCases = [];
  List<Map<String, dynamic>> _savedAdvice = [];
  bool _isLoadingData = true;
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;

    setState(() {
      _isLoadingData = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isAuthenticated) {
        final recentCases = await _databaseService.getRecentChatHistory();
        final savedAdvice = await _databaseService.getSavedAdvice();

        if (mounted) {
          setState(() {
            _recentCases = recentCases;
            _savedAdvice = savedAdvice;
            _isLoadingData = false;
          });
        }
      } else {
        setState(() {
          _isLoadingData = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
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
          if (authProvider.isAuthenticated)
            IconButton(
              onPressed: _loadUserData,
              icon: Icon(
                Icons.refresh_rounded,
                color: isDark ? Colors.white : const Color(0xFF2563EB),
              ),
            ),
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
                                onTap: () => _showImagePreview(authProvider.userProfile?['avatar_url']),
                                child: TikTokAvatar(
                                  imageUrl: authProvider.userProfile?['avatar_url'] ?? '',
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
                              // Removed the edit button row - now just showing the name centered
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
                        if (authProvider.isAuthenticated) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF10B981).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified_user,
                                  size: 18,
                                  color: const Color(0xFF10B981),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: const Color(0xFF10B981),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else
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
                  icon: Icons.language_outlined,
                  title: 'Preferred Language',
                  value: authProvider.userProfile?['preferred_language'] == 'fil'
                      ? 'Filipino'
                      : 'English',
                  isDark: isDark,
                  isEditable: false,
                ),
                _buildInfoCard(
                  icon: Icons.calendar_today_outlined,
                  title: 'Member Since',
                  value: authProvider.userProfile?['created_at'] != null
                      ? _formatDate(authProvider.userProfile!['created_at'])
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

                // Recent Cases Section
                _buildSectionHeader(
                  icon: Icons.history_outlined,
                  title: 'Recent Cases',
                  isDark: isDark,
                  actionText: _recentCases.isNotEmpty ? 'View All' : null,
                  onAction: _recentCases.isNotEmpty ? () => _navigateToRecentCases() : null,
                ),
                _isLoadingData
                    ? _buildLoadingCard(isDark)
                    : _recentCases.isEmpty
                    ? _buildEmptyStateCard(
                  isDark: isDark,
                  icon: Icons.chat_bubble_outline,
                  title: 'No legal questions yet',
                  description: 'Start by asking your first legal question in the Chat tab',
                )
                    : Column(
                  children: _recentCases.take(3).map((chat) => _buildRecentCaseCard(chat, isDark)).toList(),
                ),

                // Saved Advice Section
                _buildSectionHeader(
                  icon: Icons.bookmark_outline,
                  title: 'Saved Advice',
                  isDark: isDark,
                  actionText: _savedAdvice.isNotEmpty ? 'View All' : null,
                  onAction: _savedAdvice.isNotEmpty ? () => _navigateToSavedAdvice() : null,
                ),
                _isLoadingData
                    ? _buildLoadingCard(isDark)
                    : _savedAdvice.isEmpty
                    ? _buildEmptyStateCard(
                  isDark: isDark,
                  icon: Icons.bookmark_border,
                  title: 'No saved advice yet',
                  description: 'Save important legal advice from your conversations for quick reference',
                )
                    : Column(
                  children: _savedAdvice.take(3).map((advice) => _buildSavedAdviceCard(advice, isDark)).toList(),
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

  void _navigateToRecentCases() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecentCasesScreen(
          recentCases: _recentCases,
          onCaseUpdated: () {
            _loadUserData(); // Refresh data when returning
          },
        ),
      ),
    );
  }

  void _navigateToSavedAdvice() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SavedAdviceScreen(
          savedAdvice: _savedAdvice,
          onAdviceRemoved: (String adviceId) {
            setState(() {
              _savedAdvice.removeWhere((advice) => advice['id'] == adviceId);
            });
          },
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

  Widget _buildRecentCaseCard(Map<String, dynamic> chat, bool isDark) {
    final categories = chat['categories'] as List<dynamic>?;
    final avgConfidence = chat['avg_confidence'] as double?;
    final messageCount = chat['message_count'] as int? ?? 0;
    final firstQuestion = chat['first_question'] as String? ?? 'No question';
    final hasRecommendations = chat['has_recommendations'] as bool? ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _navigateToRecentCases(),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with categories and metadata
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category badges
                      Flexible(
                        flex: 2,
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: (categories?.take(2) ?? ['General']).map((category) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
                                    : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              category.toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          )).toList(),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Message count and confidence section
                      Flexible(
                        flex: 3,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Message count badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.blue.withOpacity(0.2)
                                    : Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? Colors.blue[700]! : Colors.blue[200]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.forum_rounded,
                                    size: 10,
                                    color: isDark ? Colors.blue[300] : Colors.blue[700],
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '$messageCount',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isDark ? Colors.blue[300] : Colors.blue[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),

                            // Recommendations indicator
                            if (hasRecommendations) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.orange,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.lightbulb_outline,
                                      size: 10,
                                      color: Colors.orange[700],
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Tips',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.orange[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],

                            if (avgConfidence != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(
                                  color: avgConfidence > 0.8
                                      ? Colors.green.withOpacity(0.1)
                                      : avgConfidence > 0.6
                                      ? Colors.orange.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: avgConfidence > 0.8
                                        ? Colors.green
                                        : avgConfidence > 0.6
                                        ? Colors.orange
                                        : Colors.grey,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified_rounded,
                                      size: 10,
                                      color: avgConfidence > 0.8
                                          ? Colors.green
                                          : avgConfidence > 0.6
                                          ? Colors.orange
                                          : Colors.grey,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${(avgConfidence * 100).round()}%',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: avgConfidence > 0.8
                                            ? Colors.green
                                            : avgConfidence > 0.6
                                            ? Colors.orange
                                            : Colors.grey,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Question text
                  Text(
                    firstQuestion,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Session summary
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          messageCount == 1
                              ? 'Single question conversation'
                              : '$messageCount messages in this conversation',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[300] : Colors.grey[600],
                            height: 1.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasRecommendations) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                size: 12,
                                color: Colors.orange[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Has recommendations',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildSavedAdviceCard(Map<String, dynamic> advice, bool isDark) {
    final categories = advice['categories'] as List<dynamic>?;
    final avgConfidence = advice['avg_confidence'] as double?;
    final messageCount = advice['message_count'] as int? ?? 0;
    final firstQuestion = advice['first_question'] as String? ?? 'No question';
    final hasRecommendations = advice['has_recommendations'] as bool? ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _navigateToSavedAdvice(),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with categories and metadata
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category badges
                      Flexible(
                        flex: 2,
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: (categories?.take(2) ?? ['General']).map((category) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
                                    : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              category.toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          )).toList(),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Message count and confidence section
                      Flexible(
                        flex: 3,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Message count badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.blue.withOpacity(0.2)
                                    : Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? Colors.blue[700]! : Colors.blue[200]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.forum_rounded,
                                    size: 10,
                                    color: isDark ? Colors.blue[300] : Colors.blue[700],
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '$messageCount',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isDark ? Colors.blue[300] : Colors.blue[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),

                            // Recommendations indicator
                            if (hasRecommendations) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.orange,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.lightbulb_outline,
                                      size: 10,
                                      color: Colors.orange[700],
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Tips',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.orange[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],

                            if (avgConfidence != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(
                                  color: avgConfidence > 0.8
                                      ? Colors.green.withOpacity(0.1)
                                      : avgConfidence > 0.6
                                      ? Colors.orange.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: avgConfidence > 0.8
                                        ? Colors.green
                                        : avgConfidence > 0.6
                                        ? Colors.orange
                                        : Colors.grey,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified_rounded,
                                      size: 10,
                                      color: avgConfidence > 0.8
                                          ? Colors.green
                                          : avgConfidence > 0.6
                                          ? Colors.orange
                                          : Colors.grey,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${(avgConfidence * 100).round()}%',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: avgConfidence > 0.8
                                            ? Colors.green
                                            : avgConfidence > 0.6
                                            ? Colors.orange
                                            : Colors.grey,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Question text
                  Text(
                    firstQuestion,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Session summary
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          messageCount == 1
                              ? 'Single question conversation'
                              : '$messageCount messages in this conversation',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[300] : Colors.grey[600],
                            height: 1.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasRecommendations) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                size: 12,
                                color: Colors.orange[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Has recommendations',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  // Added delete confirmation dialog for saved advice in profile
  void _showDeleteAdviceConfirmation(Map<String, dynamic> advice) {
    final isDark = context.read<ThemeProvider>().isDarkMode;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental dismissal
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.delete_forever_outlined,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'Delete Saved Advice?',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
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
              'Are you sure you want to permanently delete this saved legal advice?',
              style: TextStyle(
                color: isDark ? Colors.grey[300] : Colors.grey[700],
                height: 1.4,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF374151) : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category: ${advice['category'] ?? 'General'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    advice['question'] ?? 'No question',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Keep Advice',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeSavedAdvice(advice['id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
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
                  Icons.delete_forever,
                  size: 18,
                  color: Colors.white,
                ),
                SizedBox(width: 6),
                Text(
                  'Delete Forever',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _removeSavedAdvice(String adviceId) async {
    try {
      await _databaseService.removeSavedAdvice(adviceId);
      _showSuccessSnackBar('Saved advice removed successfully!');
      _loadUserData(); // Refresh the data
    } catch (e) {
      print('Error removing saved advice: $e');
      _showErrorSnackBar('Failed to remove saved advice. Please try again.');
    }
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
          icon: Icons.history,
          title: 'Chat History',
          description: 'Keep track of all your legal questions and answers',
          isDark: isDark,
        ),
        _buildBenefitCard(
          icon: Icons.bookmark,
          title: 'Save Advice',
          description: 'Bookmark important legal advice for future reference',
          isDark: isDark,
        ),
        _buildBenefitCard(
          icon: Icons.analytics,
          title: 'Personal Analytics',
          description: 'Get insights into your legal question patterns',
          isDark: isDark,
        ),
        _buildBenefitCard(
          icon: Icons.sync,
          title: 'Sync Across Devices',
          description: 'Access your data from any device, anywhere',
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

  // All the dialog and utility methods remain the same...
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

  Future<void> _uploadProfilePicture(String imagePath, AuthProvider authProvider) async {
    if (!mounted) return;

    setState(() {
      _isUploading = true;
    });

    final databaseService = DatabaseService();

    try {
      final imageUrl = await databaseService.uploadProfilePicture(imagePath);

      if (mounted) {
        _showSuccessSnackBar('Profile picture updated successfully!');

        await authProvider.updateProfile(
          fullName: authProvider.userProfile?['full_name'] ??
              authProvider.user?.displayName ??
              'User',
          avatarUrl: imageUrl,
        );
      }
    } catch (e) {
      print('Error uploading profile picture: $e');

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
                        avatarUrl: authProvider.userProfile?['avatar_url'],
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