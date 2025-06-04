import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
              onTap: () => _showPrivacyPolicyDialog(context),
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
              onTap: () => _showTermsOfServiceDialog(context),
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
              onTap: () => _showHelpSupportDialog(context),
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

  void _showPrivacyPolicyDialog(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
                        : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.shield,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Privacy Policy',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    _getPrivacyPolicyContent(),
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTermsOfServiceDialog(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF10B981), const Color(0xFF047857)]
                        : [const Color(0xFF059669), const Color(0xFF047857)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.description,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Terms of Service',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    _getTermsOfServiceContent(),
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpSupportDialog(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                        : [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.help,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Help & Support',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHelpSection(
                        'Frequently Asked Questions',
                        _getFAQContent(),
                        isDark,
                      ),
                      const SizedBox(height: 24),
                      _buildHelpSection(
                        'Contact Support',
                        _getContactContent(),
                        isDark,
                      ),

                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpSection(String title, String content, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildContactButtons(BuildContext context, bool isDark) {
    return Column(
      children: [
        Text(
          'Get in Touch',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _launchEmail(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.email, color: Colors.white, size: 20),
                label: const Text(
                  'Email',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _launchPhone(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.phone, color: Colors.white, size: 20),
                label: const Text(
                  'Call',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getPrivacyPolicyContent() {
    return '''
PRIVACY POLICY

Last updated: ${DateTime.now().year}

1. INFORMATION WE COLLECT

We collect information you provide directly to us, such as:
• Account information (name, email, phone number)
• Profile information and preferences
• Legal questions and chat history
• Usage data and analytics

2. HOW WE USE YOUR INFORMATION

We use your information to:
• Provide and improve our AI legal assistance services
• Personalize your experience and recommendations
• Send important updates and notifications
• Ensure security and prevent fraud
• Comply with legal obligations

3. DATA STORAGE AND SECURITY

• Your data is stored securely using industry-standard encryption
• We implement appropriate technical and organizational measures
• Access to personal data is strictly limited to authorized personnel
• Regular security audits and monitoring are conducted

4. SHARING YOUR INFORMATION

We do not sell, trade, or rent your personal information to third parties. We may share your information only:
• With your explicit consent
• To comply with legal obligations
• To protect our rights and safety
• With trusted service providers under strict confidentiality agreements

5. YOUR RIGHTS

You have the right to:
• Access, update, or delete your personal information
• Opt-out of non-essential communications
• Request data portability
• File complaints with relevant authorities

6. COOKIES AND TRACKING

We use cookies and similar technologies to:
• Remember your preferences
• Analyze usage patterns
• Improve our services
• Provide personalized content

7. CHILDREN'S PRIVACY

Our services are not intended for children under 13. We do not knowingly collect personal information from children under 13.

8. INTERNATIONAL TRANSFERS

Your information may be transferred to and processed in countries other than your country of residence, always with appropriate safeguards.

9. CHANGES TO THIS POLICY

We may update this privacy policy periodically. We will notify you of significant changes via email or app notification.

10. CONTACT US

If you have questions about this privacy policy, please contact us at:
Email: privacy@lawbot.ph
Phone: +63 xxx-xxx-xxxx

This privacy policy is governed by the laws of the Republic of the Philippines.
''';
  }

  String _getTermsOfServiceContent() {
    return '''
TERMS OF SERVICE

Last updated: ${DateTime.now().year}

1. ACCEPTANCE OF TERMS

By accessing and using LawBot, you accept and agree to be bound by these Terms of Service and our Privacy Policy.

2. DESCRIPTION OF SERVICE

LawBot is an AI-powered legal information assistant that provides general information about Philippine cybercrime laws and related legal topics.

3. IMPORTANT DISCLAIMERS

• LawBot provides general legal information, NOT legal advice
• Our AI responses are for informational purposes only
• We do not create attorney-client relationships
• Always consult qualified legal professionals for legal advice
• We are not responsible for decisions made based on our information

4. USER RESPONSIBILITIES

You agree to:
• Provide accurate and truthful information
• Use the service for lawful purposes only
• Respect intellectual property rights
• Not attempt to reverse engineer or hack our systems
• Not use the service to harass or harm others

5. PROHIBITED USES

You may not use LawBot to:
• Seek advice for illegal activities
• Share confidential or privileged information
• Spam or send malicious content
• Violate any applicable laws or regulations
• Impersonate others or provide false information

6. INTELLECTUAL PROPERTY

• LawBot and its content are protected by copyright and trademark laws
• You retain ownership of your questions and input
• We may use aggregated, anonymized data to improve our services
• You grant us a license to use your feedback for service improvement

7. SERVICE AVAILABILITY

• We strive for 99.9% uptime but cannot guarantee uninterrupted service
• We may temporarily suspend service for maintenance
• Features may be modified or discontinued with notice

8. LIMITATION OF LIABILITY

To the maximum extent permitted by law:
• We are not liable for decisions made based on our information
• Our liability is limited to the amount you paid for our services
• We disclaim warranties except as required by law
• We are not responsible for third-party content or services

9. INDEMNIFICATION

You agree to indemnify and hold us harmless from claims arising from your use of our service or violation of these terms.

10. TERMINATION

• You may delete your account at any time
• We may terminate accounts for violations of these terms
• Certain provisions survive termination (privacy, intellectual property)

11. GOVERNING LAW

These terms are governed by the laws of the Republic of the Philippines. Disputes will be resolved in Philippine courts.

12. CHANGES TO TERMS

We may update these terms periodically. Continued use after changes constitutes acceptance of new terms.

13. CONTACT INFORMATION

For questions about these terms:
Email: legal@lawbot.ph
Phone: +63 xxx-xxx-xxxx
Address: Philippines

By using LawBot, you acknowledge that you have read, understood, and agree to these Terms of Service.
''';
  }

  String _getFAQContent() {
    return '''
Q: Is LawBot a replacement for a real lawyer?
A: No, LawBot provides general legal information only. Always consult a qualified attorney for legal advice specific to your situation.

Q: How accurate is the legal information provided?
A: We strive for accuracy, but laws change frequently. Always verify information with current legal sources or professionals.

Q: Can I trust LawBot with confidential information?
A: While we protect your privacy, avoid sharing highly sensitive details. Use general scenarios instead of specific confidential information.

Q: What areas of law does LawBot cover?
A: LawBot specializes in Philippine cybercrime laws, data privacy, online harassment, e-commerce fraud, and related digital legal issues.

Q: Is my chat history private?
A: Yes, your conversations are private and secured. We don't share your personal legal questions with third parties.

Q: Can I download or print my chat history?
A: Yes, you can save important advice and share relevant information through the app's built-in sharing features.

Q: How often is the legal information updated?
A: Our knowledge base is regularly updated to reflect current Philippine laws and regulations.

Q: What should I do in a legal emergency?
A: For urgent legal matters, contact a lawyer immediately or call relevant authorities. LawBot is not for emergency situations.
''';
  }

  String _getContactContent() {
    return '''
Need additional help? Our support team is here to assist you.

📧 Email Support: support@lawbot.ph
• Response time: 24-48 hours
• Available 24/7 for urgent issues

📞 Phone Support: +63 xxx-xxx-xxxx
• Business hours: Monday-Friday, 9 AM - 6 PM (PHT)
• For technical issues and general inquiries

💬 In-App Support:
• Use the feedback feature in the app
• Report bugs or suggest improvements
• Rate your experience

🌐 Online Resources:
• Visit our website for additional guides
• Check our blog for legal updates
• Follow us on social media for tips

🏢 Office Address:
LawBot Philippines
[Address to be provided]
Philippines

For urgent legal matters, please contact emergency services or seek immediate legal counsel.
''';
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@lawbot.ph',
      query: 'subject=LawBot Support Request',
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      }
    } catch (e) {
      print('Could not launch email: $e');
    }
  }

  Future<void> _launchPhone() async {
    final Uri phoneLaunchUri = Uri(
      scheme: 'tel',
      path: '+63xxxxxxxxx', // Replace with actual phone number
    );

    try {
      if (await canLaunchUrl(phoneLaunchUri)) {
        await launchUrl(phoneLaunchUri);
      }
    } catch (e) {
      print('Could not launch phone: $e');
    }
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
            const SizedBox(
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
            const Icon(
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
            const Icon(
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