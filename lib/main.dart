import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Import the generated file
import 'firebase_options.dart';
import 'config/supabase_config.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/connectivity_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/sign_up_screen.dart';
import 'screens/home_screen_container.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'widgets/connectivity_wrapper.dart';

void main() async {
  // Ensure that plugin services are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (Auth only)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Supabase (Database only) - Simple configuration
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const LawBotApp());
}

class LawBotApp extends StatelessWidget {
  const LawBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, child) {
          return MaterialApp(
            title: 'LawBot',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            locale: languageProvider.currentLocale,
            home: const ConnectivityWrapper(
              showDebugInfo: false, // Set to true for debugging connectivity
              child: SplashScreen(),
            ),
            routes: {
              '/onboarding': (context) => ConnectivityWrapper(
                child: OnboardingScreen(),
              ),
              '/signin': (context) => ConnectivityWrapper(
                child: SignInScreen(),
              ),
              '/signup': (context) => ConnectivityWrapper(
                child: SignUpScreen(),
              ),
              '/forgot-password': (context) => ConnectivityWrapper(
                child: ForgotPasswordScreen(),
              ),
              '/home': (context) => ConnectivityWrapper(
                child: HomeScreenContainer(),
              ),
            },
          );
        },
      ),
    );
  }
}
