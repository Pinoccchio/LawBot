import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/auth_provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // NEW: User preferences during signup
  String _selectedLanguage = 'en';
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _legalUpdates = true;

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'fil', 'name': 'Filipino'},
    {'code': 'es', 'name': 'Español'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  void _signUp() async {
    final authProvider = context.read<AuthProvider>();

    // Validate inputs
    if (_nameController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter your full name');
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter your email');
      return;
    }

    // Email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      _showErrorSnackBar('Please enter a valid email address');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showErrorSnackBar('Password must be at least 6 characters');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('Passwords do not match');
      return;
    }

    // UPDATED: Call the enhanced sign up with preferences
    // UPDATED: Simplify notification preferences structure
    final success = await authProvider.signUp(
      _emailController.text.trim(),
      _passwordController.text,
      _nameController.text.trim(),
      preferredLanguage: _selectedLanguage,
      notificationPreferences: {
        'email': _emailNotifications,
        'push': _pushNotifications,
        'legal_updates': _legalUpdates,
        'marketing': false,
        'security_alerts': true,
      },
    );

    if (success && mounted) {
      // UPDATED: Sign out user after successful registration
      // This ensures they must manually sign in on the sign in page
      await authProvider.signOut();

      // Show success message and redirect to sign in
      if (mounted) {
        _showSuccessDialog();
      }
    } else if (mounted && authProvider.errorMessage != null) {
      _showErrorSnackBar(authProvider.errorMessage!);
    }
  }

  void _showErrorSnackBar(String message) {
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

  void _showSuccessDialog() {
    final themeProvider = context.read<ThemeProvider>();
    final languageProvider = context.read<LanguageProvider>();
    final isDark = themeProvider.isDarkMode;

    showDialog(
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade600],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Account Created!',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your account has been successfully created with the following preferences:',
                style: TextStyle(
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              _buildPreferenceSummary(isDark),
              const SizedBox(height: 16),
              Text(
                'Please sign in with your email and password to continue.',
                style: TextStyle(
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pushReplacementNamed(context, '/signin');
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
                child: Text(
                  'Go to Sign In',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPreferenceSummary(bool isDark) {
    final selectedLangName = _languages.firstWhere(
          (lang) => lang['code'] == _selectedLanguage,
      orElse: () => {'name': 'English'},
    )['name'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF334155).withOpacity(0.5)
            : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? const Color(0xFF475569)
              : Colors.blue.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• Language: $selectedLangName',
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '• Email notifications: ${_emailNotifications ? "Enabled" : "Disabled"}',
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '• Push notifications: ${_pushNotifications ? "Enabled" : "Disabled"}',
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '• Legal updates: ${_legalUpdates ? "Enabled" : "Disabled"}',
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // App Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
                          : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB)).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.smart_toy,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),
                // Create Account Text - Centered
                Text(
                  languageProvider.translate('create_account'),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  languageProvider.translate('join_lawbot'),
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Full Name Field
                TextField(
                  controller: _nameController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: languageProvider.translate('full_name'),
                    hintText: 'John Doe',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                    ),
                    labelStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                    ),
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 20),
                // Email Field
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: languageProvider.translate('email'),
                    hintText: languageProvider.translate('enter_email'),
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                    ),
                    labelStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                    ),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 20),
                // Password Field
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: languageProvider.translate('password'),
                    hintText: languageProvider.translate('create_password'),
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                    ),
                    labelStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      onPressed: _togglePasswordVisibility,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 20),
                // Confirm Password Field
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: languageProvider.translate('confirm_password'),
                    hintText: languageProvider.translate('confirm_password_hint'),
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                    ),
                    labelStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      onPressed: _toggleConfirmPasswordVisibility,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 30),

                // NEW: Preferences Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preferences',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Language Selection
                      Text(
                        'Preferred Language',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedLanguage,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                            ),
                          ),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF334155) : Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        dropdownColor: isDark ? const Color(0xFF334155) : Colors.white,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        items: _languages.map((lang) {
                          return DropdownMenuItem<String>(
                            value: lang['code'],
                            child: Text(lang['name']!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedLanguage = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Notification Preferences
                      Text(
                        'Notification Preferences',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Email Notifications
                      SwitchListTile(
                        value: _emailNotifications,
                        onChanged: (value) {
                          setState(() {
                            _emailNotifications = value;
                          });
                        },
                        title: Text(
                          'Email Notifications',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          'Receive email updates and alerts',
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        activeColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                        contentPadding: EdgeInsets.zero,
                      ),

                      // Push Notifications
                      SwitchListTile(
                        value: _pushNotifications,
                        onChanged: (value) {
                          setState(() {
                            _pushNotifications = value;
                          });
                        },
                        title: Text(
                          'Push Notifications',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          'Receive push notifications on your device',
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        activeColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                        contentPadding: EdgeInsets.zero,
                      ),

                      // Legal Updates
                      SwitchListTile(
                        value: _legalUpdates,
                        onChanged: (value) {
                          setState(() {
                            _legalUpdates = value;
                          });
                        },
                        title: Text(
                          'Legal Updates',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          'Get notified about new laws and legal changes',
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        activeColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
                      disabledForegroundColor: isDark ? Colors.grey[500] : Colors.grey[500],
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: authProvider.isLoading
                        ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? Colors.white70 : Colors.white,
                        ),
                      ),
                    )
                        : Text(
                      languageProvider.translate('sign_up'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Sign In Link
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/signin');
                  },
                  child: Text.rich(
                    TextSpan(
                      text: languageProvider.translate('already_have_account'),
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}