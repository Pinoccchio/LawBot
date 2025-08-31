import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/auth_provider.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();
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

We collect information you provide when reporting cybercrimes, such as:
• Account information (name, email, phone number, address)
• Cybercrime report details and incident descriptions  
• Evidence files (images, videos, documents, screenshots up to 25MB)
• AI assessment data and case risk scores
• Location data and timestamps for cybercrime incidents
• Communication with PNP officers and case updates
• Device information and IP addresses for security purposes

2. HOW WE USE YOUR INFORMATION

We use your information to:
• Process and investigate cybercrime reports with specialized PNP units
• Provide AI-powered evidence guidance and case assessment
• Route cases to appropriate PNP investigation units (10 specialized divisions)
• Generate pattern detection alerts for potential repeat offenders
• Send real-time case status updates and investigation notifications
• Comply with law enforcement and legal obligations under Philippine law
• Improve our AI cybercrime detection capabilities and evidence scoring
• Generate credibility scores to help prioritize case investigation

3. DATA STORAGE AND SECURITY

• All cybercrime data is stored with military-grade AES-256 encryption
• Evidence files are secured with digital chain of custody protocols
• PNP officer access is logged, monitored, and audited for accountability
• Regular security audits ensure investigation data integrity
• AI cache data uses SHA-256 keys and automatically expires after 24 hours
• Database access protected by Row Level Security (RLS) policies
• Evidence uploads validated and scanned for security threats

4. SHARING YOUR INFORMATION

Your cybercrime report information is shared with:
• Philippine National Police (PNP) specialized units for official investigation
• Assigned PNP officers based on crime type and jurisdictional requirements
• Relevant government agencies as mandated by the Cybercrime Prevention Act
• National Bureau of Investigation (NBI) for complex cases requiring coordination
• We NEVER share your information for commercial or marketing purposes
• Victim privacy is protected throughout the investigation process
• International law enforcement agencies only for transnational crimes

5. YOUR RIGHTS AS A CYBERCRIME VICTIM

You have the right to:
• Access your cybercrime reports and real-time case status tracking
• Update or correct information in your reports before investigation starts
• Receive timely updates on investigation progress and milestones
• Request case reassignment to different PNP units if circumstances change
• File complaints about investigation handling through proper channels
• Access copies of your evidence files for personal records
• Request data portability for your cybercrime reports

6. AI-POWERED FEATURES

Our advanced AI systems process your data to:
• Assess case priority and risk levels using machine learning algorithms
• Suggest relevant evidence for your specific crime type
• Detect patterns across multiple reports to identify repeat offenders
• Score report credibility and completeness in real-time
• Route cases to the most appropriate specialized investigation units
• Provide performance-optimized responses (20-40x faster with caching)
• Generate contextual evidence guidance based on 67+ crime types

7. EVIDENCE FILE HANDLING

Evidence files you upload are:
• Stored with secure digital chain of custody documentation
• Accessible only to assigned PNP investigators and authorized personnel
• Maintained for the full duration of the investigation and legal proceedings
• Protected against tampering, unauthorized access, or data corruption
• Backed up with redundant storage to prevent data loss
• Automatically validated for file integrity and authenticity

8. INVESTIGATION CONFIDENTIALITY

Your cybercrime reports are treated with strict confidentiality:
• Information is shared only for legitimate law enforcement purposes
• Victim identity is protected during ongoing investigations
• Case details are not disclosed to unauthorized parties or media
• Sensitive information is redacted in public records as appropriate
• Whistleblower protections apply for certain cybercrime types

9. DATA RETENTION AND COMPLIANCE

We retain your information as required by Philippine law:
• Active cases: Until official investigation completion and case closure
• Closed cases: As required by PNP record-keeping policies (typically 7+ years)
• Evidence files: Maintained per legal evidence requirements and court proceedings
• AI assessment data: Retained for pattern analysis and system improvement
• Personal account data: Until account deletion, subject to legal hold requirements

10. THIRD-PARTY INTEGRATIONS

• Firebase Authentication: Secure login and account management
• Supabase Database: Encrypted storage with Row Level Security
• Google AI (Gemini): Evidence analysis and case assessment (data not stored by Google)
• File storage services: Secure evidence file management with encryption

11. CONTACT US FOR PRIVACY CONCERNS

For privacy questions regarding your cybercrime reports:
Email: privacy@lawbot.ph
PNP Anti-Cybercrime Group: +63-2-723-0401 ext. 5123
PNP Cybercrime Hotline: 117
Emergency: 911
Data Privacy Officer: dpo@lawbot.ph

This privacy policy complies with the Data Privacy Act of 2012, Cybercrime Prevention Act of 2012, and Philippine cybercrime investigation protocols.
''';
  }

  String _getTermsOfServiceContent() {
    return '''
TERMS OF SERVICE

Last updated: ${DateTime.now().year}

1. ACCEPTANCE OF TERMS AND LEGAL AUTHORITY

By using LawBot's cybercrime reporting platform, you accept these Terms of Service and agree to cooperate fully with official PNP investigations. LawBot operates under the authority of the Cybercrime Prevention Act of 2012 and in partnership with the Philippine National Police.

2. OFFICIAL SERVICE DESCRIPTION

LawBot is the official AI-powered cybercrime reporting platform integrated with the Philippine National Police (PNP) providing:
• Comprehensive reporting system for 67+ cybercrime types across 10 major categories
• Advanced AI-assisted evidence collection, assessment, and case prioritization
• Direct integration with 10 specialized PNP investigation units
• Real-time case tracking with 5-stage status workflow
• Professional victim assistance and investigation support
• Pattern detection system for identifying repeat cybercriminals

3. OFFICIAL PNP PARTNERSHIP AND AUTHORITY

• LawBot operates under official partnership with the Philippine National Police
• All reports submitted become official cybercrime complaints with legal standing
• PNP specialized units investigate cases according to Philippine criminal law
• Cases are automatically routed to appropriate investigation units using AI assessment
• This platform supplements but does not replace emergency services - call 911 for immediate threats
• Reports carry the same legal weight as traditional police reports

4. USER RESPONSIBILITIES AND LEGAL OBLIGATIONS

You agree to:
• Provide accurate, complete, and truthful information in all cybercrime reports
• Upload authentic evidence files directly related to your case (max 5 files, 25MB total)
• Cooperate fully with PNP investigations, requests, and testimony requirements
• Report cybercrimes promptly to preserve digital evidence and prevent further damage
• Not file false reports, which is a criminal offense under Philippine law
• Maintain confidentiality of ongoing investigations and not interfere with law enforcement
• Respond to PNP officer requests for clarification or additional evidence

5. PROHIBITED USES AND CRIMINAL LIABILITY

You may not use LawBot to:
• File false, fraudulent, or malicious cybercrime reports (criminal offense)
• Upload illegal content, malware, or evidence obtained through unlawful means
• Interfere with ongoing PNP investigations or tamper with evidence
• Share confidential investigation details publicly or compromise case integrity
• Use the platform for purposes other than legitimate cybercrime reporting
• Attempt to access other users' case information or PNP investigation data
• Upload copyrighted material without authorization or consent

6. AI-POWERED INVESTIGATION SUPPORT

• AI Risk Assessment Service provides case priority scoring for PNP officers
• Evidence Guidance Service suggests specific evidence types for each crime category
• Pattern Detection Service identifies potential repeat offenders across reports
• Credibility Scorer assesses report completeness and provides improvement suggestions
• AI Database Service provides 20-40x performance improvement through intelligent caching
• AI recommendations are advisory tools - final investigation decisions rest with PNP officers
• All AI processing follows strict data privacy and security protocols

7. EVIDENCE HANDLING AND CHAIN OF CUSTODY

• Evidence files become part of official PNP investigation records with legal standing
• Digital chain of custody protocols ensure evidence integrity and court admissibility
• You retain ownership rights to your evidence but grant PNP investigative access
• Evidence may be used in legal proceedings, court cases, and prosecution efforts
• Tampering with or destroying evidence is a criminal offense under Philippine law
• Evidence storage follows international digital forensics standards

8. INVESTIGATION PROCESS AND PROCEDURES

• Cases follow official PNP cybercrime investigation procedures and protocols
• Status workflow: Pending → Under Investigation → Requires More Info → Resolved/Dismissed
• Investigation timelines vary based on case complexity, evidence quality, and priority level
• Assigned PNP officers may contact you for additional information, clarification, or testimony
• Case outcomes are determined by evidence quality, legal proceedings, and prosecutorial decisions
• Appeals process available through proper PNP channels for case handling disputes

9. SERVICE AVAILABILITY AND TECHNICAL SUPPORT

• Platform available 24/7 for cybercrime reporting and evidence submission
• Emergency cybercrime support available through PNP specialized hotlines
• Scheduled maintenance windows will be announced in advance
• Critical evidence uploads and urgent case submissions are prioritized during maintenance
• Technical support available for evidence upload issues and platform problems

10. LIMITATION OF LIABILITY AND DISCLAIMERS

• LawBot facilitates cybercrime reporting but does not guarantee specific investigation outcomes
• Investigation results depend on evidence quality, legal factors, and prosecutorial discretion
• We are not responsible for PNP investigation decisions, timelines, or resource allocation
• Service is provided to support law enforcement operations, not replace legal counsel
• AI assessments are tools to assist investigation - not legal determinations

11. LEGAL COMPLIANCE AND JURISDICTION

• All platform activities governed by Philippine cybercrime and criminal laws
• Reports are processed under the Cybercrime Prevention Act of 2012
• Evidence handling follows Philippine Rules of Evidence for court proceedings
• International cybercrime cases involve cooperation with foreign law enforcement
• Platform operates under Philippine legal jurisdiction and regulatory oversight
• Disputes resolved through Philippine courts and legal system

12. ACCOUNT TERMINATION AND CONSEQUENCES

• Accounts may be suspended or terminated for filing false or malicious reports
• Interference with investigations may result in criminal charges and prosecution
• Account closure does not affect ongoing PNP investigations or legal proceedings
• Evidence and reports remain accessible to PNP as required by law and court orders
• Terminated users may be banned from future platform use

13. UPDATES TO TERMS AND NOTIFICATION

• Terms may be updated to reflect changes in law or platform capabilities
• Material changes will be communicated through in-app notifications
• Continued use after updates constitutes acceptance of revised terms
• Legal requirements may supersede these terms where applicable

14. CONTACT INFORMATION AND LEGAL SUPPORT

For questions about these terms and legal matters:
Legal Team: legal@lawbot.ph
PNP Anti-Cybercrime Group: +63-2-723-0401 ext. 5123
PNP Cybercrime Hotline: 117
Emergency Hotline: 911
Victim Support Services: victim.support@lawbot.ph

By using LawBot, you acknowledge this is an official cybercrime reporting platform with direct law enforcement integration and legal consequences for misuse.
''';
  }

  String _getFAQContent() {
    return '''
Q: How do I report a cybercrime through LawBot?
A: Select your crime category from 10 major types, fill out the AI-guided form with incident details, upload evidence files (max 5 files, 25MB total), and submit. Your report receives an official complaint number (CYB-YYYY-XXX format) and is automatically routed to the appropriate specialized PNP unit based on AI assessment.

Q: What types of cybercrimes can I report?
A: LawBot covers 67+ specific crime types across 10 categories: Communication & Social Media Crimes, Financial & Economic Crimes, Data & Privacy Crimes, Malware & System Attacks, Harassment & Exploitation, Content-Related Crimes, System Disruption & Sabotage, Government & Terrorism, Technical Exploitation, and Targeted Attacks.

Q: Will PNP officers really investigate my case?
A: Yes, absolutely. All reports go directly to specialized PNP investigation units including Cyber Crime Investigation Cell, Economic Offenses Wing, Cyber Security Division, and 7 other specialized units. Cases are assigned based on crime type and AI-assessed priority levels with real-time officer assignments.

Q: How long does a cybercrime investigation take?
A: Investigation timelines vary by case complexity, evidence quality, and priority level. Simple scam cases may resolve in 2-4 weeks, while complex hacking or financial fraud cases can take 2-6 months. You receive real-time status updates and can track investigation milestones.

Q: What evidence should I upload with my report?
A: Our AI Evidence Guidance Service provides personalized evidence suggestions for each of the 67+ crime types. Common evidence includes screenshots, transaction records, communication logs, URLs, account details, banking records, phone logs, and any relevant documents or photos.

Q: How secure is my evidence and personal information?
A: All data is protected with AES-256 military-grade encryption. Evidence files maintain digital chain of custody protocols with SHA-256 integrity verification. Only authorized PNP investigators can access your case information through Row Level Security policies. We never share data commercially.

Q: Can I track the status of my cybercrime report?
A: Yes, you can monitor your case progress in real-time through the app. Status updates include: Pending → Under Investigation → Requires More Info → Resolved/Dismissed. Push notifications and in-app updates keep you informed of investigation milestones and officer assignments.

Q: What is the AI Risk Assessment feature?
A: Our 5-service AI system analyzes your report to determine case priority (1-10 scale), suggest specific evidence, assess report credibility (0-100% score), detect patterns across reports to identify repeat offenders, and provide performance-optimized responses with 20-40x speed improvement through intelligent caching.

Q: Can I report cybercrimes that happened outside the Philippines?
A: Yes, LawBot handles international cybercrime cases affecting Filipino citizens or involving Philippine jurisdiction. Our system coordinates with foreign law enforcement agencies through proper diplomatic channels and international cooperation agreements.

Q: What should I do for cybercrime emergencies?
A: For immediate threats, ongoing attacks, or life-threatening situations, call 911 or PNP Hotline 117 immediately. Then file a detailed report through LawBot within 24 hours to provide evidence and ensure proper investigation documentation and follow-up.

Q: How does LawBot assign cases to different PNP units?
A: Our AI automatically routes cases to 10 specialized units based on crime type analysis: Communication crimes → Cyber Crime Investigation Cell, Financial crimes → Economic Offenses Wing, Data breaches → Cyber Security Division, etc. Each unit has specific expertise and jurisdiction.

Q: What is the Credibility Scorer and how does it work?
A: The AI Credibility Scorer evaluates your report completeness and provides real-time suggestions to improve your case quality. It analyzes evidence quality, incident details, and supporting documentation to give you a 0-100% credibility score with actionable improvement recommendations.

Q: How does the Pattern Detection system protect other victims?
A: Our AI analyzes report patterns across the platform to identify potential repeat offenders and scammer networks. When similar fraud patterns are detected, the system generates alerts to help PNP officers connect related cases and protect future victims.

Q: Can I update my cybercrime report after submission?
A: You can update case information during the "Pending" status. Once investigation begins, updates require PNP officer approval. Critical new evidence can always be added through proper channels with chain of custody documentation.

Q: What happens if my case is marked "Requires More Info"?
A: You'll receive specific requests from assigned PNP officers about additional evidence or clarification needed. The case status remains active, and you can submit additional information through the secure platform to help advance the investigation.

Q: How do I know which PNP officer is handling my case?
A: Officer assignment information is provided once investigation begins. You'll see the assigned officer's badge number, specialization, and contact information for authorized case-related communication through the secure platform.
''';
  }

  String _getContactContent() {
    return '''
Need help with cybercrime reporting? Our specialized support team and official PNP partners provide comprehensive assistance for all cybercrime victims.

🚨 EMERGENCY CYBERCRIME SUPPORT:
• PNP Emergency Hotline: 911
• PNP General Hotline: 117  
• PNP Anti-Cybercrime Group: +63-2-723-0401
• For immediate threats, ongoing cyberattacks, or life-threatening situations
• Available 24/7 for critical cybercrime emergencies

📧 OFFICIAL LAWBOT CYBERCRIME SUPPORT:
• Technical Support: support@lawbot.ph (Response: 2-4 hours urgent, 24-48 hours general)
• Legal Questions: legal@lawbot.ph
• Privacy Concerns: privacy@lawbot.ph
• Victim Support: victim.support@lawbot.ph
• Available 24/7 for critical cybercrime assistance and case submission support

📞 PNP SPECIALIZED CYBERCRIME UNITS:
• PNP Anti-Cybercrime Group Main: +63-2-723-0401 ext. 5123
• Cyber Crime Investigation Cell: ext. 5124
• Economic Offenses Wing: ext. 5125
• Cyber Security Division: ext. 5126
• Available: Monday-Friday, 8 AM - 5 PM (PHT), 24/7 for emergencies

🏛️ COMPLETE PNP CYBERCRIME UNIT DIRECTORY:
• Cyber Crime Investigation Cell - Communication & social media crimes
• Economic Offenses Wing - Financial fraud and scams
• Cyber Security Division - Data breaches and privacy crimes
• Cyber Crime Technical Unit - Malware and system attacks
• Cyber Crime Against Women and Children - Harassment and exploitation
• Special Investigation Team - Content-related crimes
• Critical Infrastructure Protection Unit - System sabotage
• National Security Cyber Division - Government and terrorism threats
• Advanced Cyber Forensics Unit - Technical exploitation cases
• Special Cyber Operations Unit - Targeted and advanced attacks

💬 IN-APP CYBERCRIME ASSISTANCE:
• Real-time case tracking and status monitoring
• Evidence upload troubleshooting and file validation
• AI assessment results and credibility score explanations
• Request additional investigation support or case priority review
• Provide feedback on case handling and officer responsiveness
• Access to victim support resources and legal assistance programs

🌐 ADDITIONAL CYBERCRIME RESOURCES:
• Republic Act 10175 (Cybercrime Prevention Act of 2012)
• Republic Act 10173 (Data Privacy Act of 2012)
• PNP Cybercrime Prevention Guidelines
• International cybercrime cooperation treaties and protocols
• Victim assistance programs and legal aid services
• Cybersecurity awareness and prevention resources

🏢 PNP ANTI-CYBERCRIME GROUP HEADQUARTERS:
Camp Crame, Quezon City, Metro Manila, Philippines
Main Office: +63-2-723-0401
Direct Cybercrime Hotline: 117
Email: pnp.cybercrime@pnp.gov.ph
Operating Hours: 24/7 for emergencies, 8 AM - 5 PM for general inquiries

⚠️ CRITICAL CYBERCRIME REPORTING REMINDERS:
• For immediate physical threats or ongoing attacks, call 911 FIRST
• Preserve ALL digital evidence - do not delete anything
• Screenshot everything immediately before evidence disappears
• Do not attempt to confront cybercriminals directly - this can escalate danger
• Report cybercrimes within 24-48 hours for optimal evidence preservation
• Keep all transaction records, communication logs, and account information
• Document financial losses with bank statements and transaction histories

🛡️ VICTIM SAFETY AND INVESTIGATION SUCCESS:
Your personal safety and successful cybercrime case investigation are our highest priorities. Our AI-powered platform and PNP partnership ensure professional, thorough investigation of all reported cybercrimes.
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

              // Language preference is now stored locally only
              // No need to update user profile in database

              if (context.mounted) {
                Navigator.pop(context);
                _showSuccessSnackBar(
                    context,
                    'Language changed to $language',
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