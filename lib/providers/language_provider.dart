import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('en');
  static const String _languageKey = 'selected_language';

  Locale get currentLocale => _currentLocale;

  String get currentLanguage {
    switch (_currentLocale.languageCode) {
      case 'en':
        return 'English';
      case 'fil':
        return 'Filipino';
      default:
        return 'English';
    }
  }

  LanguageProvider() {
    _loadLanguage();
  }

  // Load language from SharedPreferences
  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey);

      if (savedLanguage != null) {
        _currentLocale = Locale(savedLanguage);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading language: $e');
      _currentLocale = const Locale('en');
    }
  }

  // Save language to SharedPreferences
  Future<void> _saveLanguage(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
    } catch (e) {
      debugPrint('Error saving language: $e');
    }
  }

  // Set language and save to preferences
  Future<void> setLanguage(String languageCode) async {
    if (_currentLocale.languageCode != languageCode) {
      _currentLocale = Locale(languageCode);
      await _saveLanguage(languageCode);
      notifyListeners();
    }
  }

  Map<String, String> get translations {
    switch (_currentLocale.languageCode) {
      case 'fil':
        return _filipinoTranslations;
      default:
        return _englishTranslations;
    }
  }

  String translate(String key) {
    return translations[key] ?? key;
  }

  static const Map<String, String> _englishTranslations = {
    'welcome_back': 'Welcome Back',
    'sign_in_subtitle': 'Sign in to continue to LawBot',
    'email': 'Email',
    'password': 'Password',
    'forgot_password': 'Forgot Password?',
    'sign_in': 'Sign In',
    'sign_up': 'Sign Up',
    'continue_as_guest': 'Continue as Guest',
    'dont_have_account': "Don't have an account? Sign Up",
    'create_account': 'Create Account',
    'join_lawbot': 'Join LawBot to get legal assistance',
    'full_name': 'Full Name',
    'confirm_password': 'Confirm Password',
    'already_have_account': 'Already have an account? Sign In',
    'home': 'Home',
    'resources': 'Resources',
    'profile': 'Profile',
    'settings': 'Settings',
    'analytics': 'Analytics',
    'lawbot': 'LawBot',
    'ai_legal_assistant': 'AI Legal Assistant for Cybercrimes',
    'ask_legal_question': 'Ask a legal question...',
    'learn_cybercrime_laws': 'Learn about cybercrime laws in the Philippines',
    'search_resources': 'Search resources...',
    'all': 'All',
    'laws_regulations': 'Laws & Regulations',
    'educational_material': 'Educational Material',
    'guest_user': 'Guest User',
    'recent_cases': 'Recent Cases',
    'saved_advice': 'Saved Advice',
    'preferences': 'Preferences',
    'notifications': 'Notifications',
    'dark_mode': 'Dark Mode',
    'language': 'Language',
    'legal_support': 'Legal & Support',
    'privacy_policy': 'Privacy Policy',
    'terms_of_service': 'Terms of Service',
    'help_support': 'Help & Support',
    'account': 'Account',
    'sign_out': 'Sign Out',
    'receive_updates': 'Receive updates and legal alerts',
    'switch_dark_theme': 'Switch to dark theme',
    'get_assistance': 'Get assistance with using LawBot',
    'current': 'Current',
    'select_language': 'Select Language',
    'cancel': 'Cancel',
    'sign_out_confirmation': 'Are you sure you want to sign out?',
    'enter_email': 'Enter your email',
    'enter_password': 'Enter your password',
    'create_password': 'Create a password',
    'confirm_password_hint': 'Confirm your password',
    // Onboarding
    'skip': 'Skip',
    'next': 'Next',
    'get_started': 'Get Started',
    'welcome_to_lawbot': 'Welcome to LawBot',
    'ai_legal_assistant_philippines': 'Your AI Legal Assistant for Philippine Cybercrime Laws',
    'philippine_cybercrime_laws': 'Philippine cybercrime laws expertise',
    'bilingual_support': 'Bilingual support (English & Filipino)',
    'secure_mobile_experience': 'Secure and responsive mobile experience',
    'ai_powered_legal_chat': 'AI-Powered Legal Chat',
    'chatbot_description': 'Get instant legal guidance on cybercrime matters. Our AI understands both English and Filipino and provides accurate advice based on Philippine laws.',
    'ask_question': 'Ask your legal question',
    'get_legal_guidance': 'Receive expert legal guidance',
    'save_to_history': 'Save conversation to history',
    'prescriptive_analytics': 'Prescriptive Analytics',
    'analytics_description': 'Get actionable recommendations based on case details and legal precedents to guide next steps and potential outcomes.',
    'track_patterns': 'Track legal question patterns',
    'get_recommendations': 'Get data-driven recommendations',
    'receive_alerts': 'Receive personalized legal alerts',
    // Analytics
    'total_questions': 'Total Questions',
    'accuracy_rate': 'Accuracy Rate',
    'top_topics': 'Top Legal Topics',
    'recommendations': 'Recommendations',
    'insights': 'Legal Insights',
    'high_risk_pattern': 'High Risk Pattern Detected',
    'high_risk_description': 'Your recent questions indicate a potential high-risk cybercrime situation. Consider consulting with a legal professional.',
    'legal_precedent': 'Relevant Legal Precedent',
    'precedent_description': 'Based on similar cases, documenting evidence early significantly improves case outcomes.',
    'documentation_tip': 'Documentation Improvement',
    'documentation_description': 'Consider organizing your evidence chronologically for better case presentation.',
    'weekly_summary': 'Weekly Legal Summary',
    'weekly_summary_text': 'This week you\'ve shown increased interest in online harassment cases. The Cybercrime Prevention Act of 2012 provides strong protection against such activities. Consider filing a report with the PNP Anti-Cybercrime Group if you\'re experiencing ongoing harassment.',
  };

  static const Map<String, String> _filipinoTranslations = {
    'welcome_back': 'Maligayang Pagbabalik',
    'sign_in_subtitle': 'Mag-sign in upang magpatuloy sa LawBot',
    'email': 'Email',
    'password': 'Password',
    'forgot_password': 'Nakalimutan ang Password?',
    'sign_in': 'Mag-sign In',
    'sign_up': 'Mag-sign Up',
    'continue_as_guest': 'Magpatuloy bilang Bisita',
    'dont_have_account': "Walang account? Mag-sign Up",
    'create_account': 'Gumawa ng Account',
    'join_lawbot': 'Sumali sa LawBot para sa legal na tulong',
    'full_name': 'Buong Pangalan',
    'confirm_password': 'Kumpirmahin ang Password',
    'already_have_account': 'May account na? Mag-sign In',
    'home': 'Home',
    'resources': 'Resources',
    'profile': 'Profile',
    'settings': 'Settings',
    'analytics': 'Analytics',
    'lawbot': 'LawBot',
    'ai_legal_assistant': 'AI Legal Assistant para sa Cybercrimes',
    'ask_legal_question': 'Magtanong ng legal na katanungan...',
    'learn_cybercrime_laws': 'Matuto tungkol sa cybercrime laws sa Pilipinas',
    'search_resources': 'Maghanap ng resources...',
    'all': 'Lahat',
    'laws_regulations': 'Batas at Regulasyon',
    'educational_material': 'Educational Material',
    'guest_user': 'Guest User',
    'recent_cases': 'Kamakailang Kaso',
    'saved_advice': 'Naka-save na Payo',
    'preferences': 'Preferences',
    'notifications': 'Notifications',
    'dark_mode': 'Dark Mode',
    'language': 'Wika',
    'legal_support': 'Legal at Support',
    'privacy_policy': 'Privacy Policy',
    'terms_of_service': 'Terms of Service',
    'help_support': 'Tulong at Support',
    'account': 'Account',
    'sign_out': 'Mag-sign Out',
    'receive_updates': 'Makatanggap ng updates at legal alerts',
    'switch_dark_theme': 'Lumipat sa dark theme',
    'get_assistance': 'Makakuha ng tulong sa paggamit ng LawBot',
    'current': 'Kasalukuyan',
    'select_language': 'Pumili ng Wika',
    'cancel': 'Kanselahin',
    'sign_out_confirmation': 'Sigurado ka bang gusto mong mag-sign out?',
    'enter_email': 'Ilagay ang inyong email',
    'enter_password': 'Ilagay ang inyong password',
    'create_password': 'Gumawa ng password',
    'confirm_password_hint': 'Kumpirmahin ang inyong password',
    // Onboarding
    'skip': 'Laktawan',
    'next': 'Susunod',
    'get_started': 'Magsimula',
    'welcome_to_lawbot': 'Maligayang Pagdating sa LawBot',
    'ai_legal_assistant_philippines': 'Ang inyong AI Legal Assistant para sa Philippine Cybercrime Laws',
    'philippine_cybercrime_laws': 'Eksperto sa Philippine cybercrime laws',
    'bilingual_support': 'Bilingual support (English at Filipino)',
    'secure_mobile_experience': 'Secure at responsive mobile experience',
    'ai_powered_legal_chat': 'AI-Powered Legal Chat',
    'chatbot_description': 'Makakuha ng instant legal guidance sa cybercrime matters. Ang aming AI ay nakakaintindi ng English at Filipino at nagbibigay ng tumpak na payo base sa Philippine laws.',
    'ask_question': 'Magtanong ng legal question',
    'get_legal_guidance': 'Makatanggap ng expert legal guidance',
    'save_to_history': 'I-save ang conversation sa history',
    'prescriptive_analytics': 'Prescriptive Analytics',
    'analytics_description': 'Makakuha ng actionable recommendations base sa case details at legal precedents para sa susunod na hakbang at potential outcomes.',
    'track_patterns': 'I-track ang legal question patterns',
    'get_recommendations': 'Makakuha ng data-driven recommendations',
    'receive_alerts': 'Makatanggap ng personalized legal alerts',
    // Analytics
    'total_questions': 'Kabuuang Tanong',
    'accuracy_rate': 'Accuracy Rate',
    'top_topics': 'Top Legal Topics',
    'recommendations': 'Mga Rekomendasyon',
    'insights': 'Legal Insights',
    'high_risk_pattern': 'High Risk Pattern na Nakita',
    'high_risk_description': 'Ang inyong mga kamakailang tanong ay nagpapakita ng potential high-risk cybercrime situation. Isaalang-alang ang pakikipag-consult sa legal professional.',
    'legal_precedent': 'Relevant Legal Precedent',
    'precedent_description': 'Base sa mga katulad na kaso, ang pag-document ng evidence nang maaga ay nagpapabuti ng case outcomes.',
    'documentation_tip': 'Documentation Improvement',
    'documentation_description': 'Isaalang-alang ang pag-organize ng inyong evidence nang chronologically para sa mas magandang case presentation.',
    'weekly_summary': 'Weekly Legal Summary',
    'weekly_summary_text': 'Ngayong linggo ay nagpakita kayo ng mas mataas na interes sa online harassment cases. Ang Cybercrime Prevention Act of 2012 ay nagbibigay ng malakas na proteksyon laban sa mga ganitong aktibidad. Isaalang-alang ang pag-file ng report sa PNP Anti-Cybercrime Group kung nakakaranas kayo ng tuloy-tuloy na harassment.',
  };
}
