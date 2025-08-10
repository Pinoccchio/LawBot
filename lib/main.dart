import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Import the generated file
import 'firebase_options.dart';
import 'config/supabase_config.dart';
import 'services/fcm_service.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/realtime_provider.dart';
import 'providers/global_refresh_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/sign_up_screen.dart';
import 'screens/home_screen_container.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/report_detail_by_id_screen.dart';
import 'widgets/connectivity_wrapper.dart';

void main() async {
  // Ensure that plugin services are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (Auth & FCM)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set up background message handler before any other Firebase operations
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

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
        ChangeNotifierProvider(create: (_) => RealtimeProvider()),
        ChangeNotifierProvider(create: (_) => GlobalRefreshProvider()),
        // Set up provider dependencies
        ProxyProvider2<NotificationProvider, RealtimeProvider, RealtimeProvider>(
          update: (context, notificationProvider, realtimeProvider, previous) {
            realtimeProvider.setNotificationProvider(notificationProvider);
            return realtimeProvider;
          },
        ),
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
            onGenerateRoute: (settings) {
              // Handle complaint detail routes (both /complaint/ and /case/ patterns)
              if (settings.name?.startsWith('/complaint/') == true || 
                  settings.name?.startsWith('/case/') == true) {
                final uri = Uri.parse(settings.name!);
                final complaintId = uri.pathSegments.last;
                
                return MaterialPageRoute(
                  builder: (context) => ConnectivityWrapper(
                    child: ReportDetailByIdScreen(
                      complaintId: complaintId,
                    ),
                  ),
                  settings: settings,
                );
              }
              
              return null;
            },
            onUnknownRoute: (settings) {
              // Fallback for unknown routes
              return MaterialPageRoute(
                builder: (context) => ConnectivityWrapper(
                  child: HomeScreenContainer(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
