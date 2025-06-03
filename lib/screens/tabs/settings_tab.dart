import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        title: Text(
          languageProvider.translate('settings'),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preferences Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                languageProvider.translate('preferences'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                ),
              ),
            ),

            // Notifications Setting
            _buildSettingCard(
              context,
              icon: Icons.notifications_outlined,
              activeIcon: Icons.notifications,
              title: languageProvider.translate('notifications'),
              subtitle: languageProvider.translate('receive_updates'),
              trailing: Switch.adaptive(
                value: notificationProvider.notificationsEnabled,
                onChanged: (value) {
                  notificationProvider.toggleNotifications();
                  _showSnackBar(
                    context,
                    value
                        ? 'Notifications enabled'
                        : 'Notifications disabled',
                    isDark,
                  );
                },
                activeColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
              ),
            ),

            // Dark Mode Setting
            _buildSettingCard(
              context,
              icon: Icons.dark_mode_outlined,
              activeIcon: Icons.dark_mode,
              title: languageProvider.translate('dark_mode'),
              subtitle: languageProvider.translate('switch_dark_theme'),
              trailing: Switch.adaptive(
                value: isDark,
                onChanged: (value) {
                  themeProvider.toggleTheme();
                  _showSnackBar(
                    context,
                    value
                        ? 'Dark mode enabled'
                        : 'Light mode enabled',
                    !value, // Use opposite since theme hasn't changed yet
                  );
                },
                activeColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
              ),
            ),

            // Language Setting
            _buildSettingCard(
              context,
              icon: Icons.language_outlined,
              activeIcon: Icons.language,
              title: languageProvider.translate('language'),
              subtitle: '${languageProvider.translate('current')}: ${languageProvider.currentLanguage}',
              trailing: Icon(
                Icons.chevron_right,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              onTap: () => _showModernLanguageDialog(context),
            ),

            const SizedBox(height: 24),

            // Legal & Support Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                languageProvider.translate('legal_support'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                ),
              ),
            ),

            // Privacy Policy
            _buildSettingCard(
              context,
              icon: Icons.shield_outlined,
              activeIcon: Icons.shield,
              title: languageProvider.translate('privacy_policy'),
              trailing: Icon(
                Icons.chevron_right,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              onTap: () {
                _showSnackBar(context, 'Privacy Policy - Coming Soon', isDark);
              },
            ),

            // Terms of Service
            _buildSettingCard(
              context,
              icon: Icons.description_outlined,
              activeIcon: Icons.description,
              title: languageProvider.translate('terms_of_service'),
              trailing: Icon(
                Icons.chevron_right,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              onTap: () {
                _showSnackBar(context, 'Terms of Service - Coming Soon', isDark);
              },
            ),

            // Help & Support
            _buildSettingCard(
              context,
              icon: Icons.help_outline,
              activeIcon: Icons.help,
              title: languageProvider.translate('help_support'),
              subtitle: languageProvider.translate('get_assistance'),
              trailing: Icon(
                Icons.chevron_right,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              onTap: () {
                _showSnackBar(context, 'Help & Support - Coming Soon', isDark);
              },
            ),

            const SizedBox(height: 24),

            // Account Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                languageProvider.translate('account'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                ),
              ),
            ),

            // Sign Out
            _buildSettingCard(
              context,
              icon: Icons.logout_outlined,
              activeIcon: Icons.logout,
              iconColor: Colors.red,
              title: languageProvider.translate('sign_out'),
              trailing: Icon(
                Icons.chevron_right,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              onTap: () => _showSignOutDialog(context),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard(
      BuildContext context, {
        required IconData icon,
        IconData? activeIcon,
        Color? iconColor,
        required String title,
        String? subtitle,
        Widget? trailing,
        VoidCallback? onTap,
      }) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final effectiveIconColor = iconColor ?? (isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: effectiveIconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: effectiveIconColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    activeIcon ?? icon,
                    color: effectiveIconColor,
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
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 16),
                  trailing,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showModernLanguageDialog(BuildContext context) {
    final languageProvider = context.read<LanguageProvider>();
    final themeProvider = context.read<ThemeProvider>();
    final authProvider = context.read<AuthProvider>();
    final isDark = themeProvider.isDarkMode;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Consumer3<LanguageProvider, ThemeProvider, AuthProvider>(
          builder: (context, langProvider, themeProvider, authProvider, child) {
            final isDarkMode = themeProvider.isDarkMode;

            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode
                          ? Colors.black.withOpacity(0.5)
                          : Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20), // Reduced from 24
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDarkMode
                              ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
                              : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40, // Reduced from 48
                            height: 40, // Reduced from 48
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10), // Reduced from 12
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.language,
                              color: Colors.white,
                              size: 20, // Reduced from 24
                            ),
                          ),
                          const SizedBox(width: 12), // Reduced from 16
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  langProvider.translate('select_language'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18, // Reduced from 20
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2), // Reduced from 4
                                Text(
                                  'Choose your preferred language',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12, // Reduced from 14
                                  ),
                                  maxLines: 2, // Added maxLines
                                  overflow: TextOverflow.ellipsis, // Added overflow handling
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Language Options
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildModernLanguageOption(
                            dialogContext,
                            'English',
                            'en',
                            '🇺🇸',
                            'English (US)',
                            langProvider,
                            authProvider,
                            isDarkMode,
                          ),
                          const SizedBox(height: 12),
                          _buildModernLanguageOption(
                            dialogContext,
                            'Filipino',
                            'fil',
                            '🇵🇭',
                            'Filipino (Philippines)',
                            langProvider,
                            authProvider,
                            isDarkMode,
                          ),
                        ],
                      ),
                    ),

                    // Footer
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF0F172A).withOpacity(0.5)
                            : Colors.grey.shade50,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              langProvider.translate('cancel'),
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModernLanguageOption(
      BuildContext context,
      String language,
      String code,
      String flag,
      String subtitle,
      LanguageProvider languageProvider,
      AuthProvider authProvider,
      bool isDark,
      ) {
    final isSelected = languageProvider.currentLocale.languageCode == code;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isSelected
            ? (isDark ? const Color(0xFF3B82F6).withOpacity(0.1) : const Color(0xFF2563EB).withOpacity(0.05))
            : (isDark ? const Color(0xFF334155).withOpacity(0.3) : Colors.grey.shade50),
        border: Border.all(
          color: isSelected
              ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB))
              : (isDark ? const Color(0xFF475569) : Colors.grey.shade200),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            // Show loading state
            _showLoadingSnackBar(context, 'Updating language preference...', isDark);

            try {
              // Update local language preference
              await languageProvider.setLanguage(code);

              // Update user profile in Supabase if user is authenticated
              if (authProvider.isAuthenticated) {
                await authProvider.updateProfile(
                  fullName: authProvider.userProfile?['full_name'] ??
                      authProvider.user?.displayName ??
                      'User',
                  phoneNumber: authProvider.userProfile?['phone_number'],
                  avatarUrl: authProvider.userProfile?['avatar_url'],
                  preferredLanguage: code, // Update the preferred language in database
                );
              }

              if (context.mounted) {
                Navigator.pop(context);
                _showSuccessSnackBar(
                    context,
                    'Language changed to $language${authProvider.isAuthenticated ? ' and synced to your profile' : ''}',
                    isDark
                );
              }
            } catch (e) {
              if (context.mounted) {
                Navigator.pop(context);
                _showErrorSnackBar(
                    context,
                    'Failed to update language preference. Please try again.',
                    isDark
                );
              }
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF475569).withOpacity(0.3)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF64748B).withOpacity(0.3)
                          : Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      flag,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        language,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected) ...[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
                            : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB)).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ] else ...[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? Colors.grey[600]!
                            : Colors.grey[400]!,
                        width: 2,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    final languageProvider = context.read<LanguageProvider>();
    final themeProvider = context.read<ThemeProvider>();
    final authProvider = context.read<AuthProvider>();
    final isDark = themeProvider.isDarkMode;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Consumer<LanguageProvider>(
          builder: (context, langProvider, child) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                langProvider.translate('sign_out'),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                langProvider.translate('sign_out_confirmation'),
                style: TextStyle(
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    langProvider.translate('cancel'),
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);

                    // Sign out the user
                    await authProvider.signOut();

                    // Navigate to splash screen (which will show onboarding for signed out users)
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/',
                            (route) => false,
                      );
                    }
                  },
                  child: Text(
                    langProvider.translate('sign_out'),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSnackBar(BuildContext context, String message, bool isDark) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF2563EB),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showLoadingSnackBar(BuildContext context, String message, bool isDark) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF2563EB),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showSuccessSnackBar(BuildContext context, String message, bool isDark) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message, bool isDark) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
