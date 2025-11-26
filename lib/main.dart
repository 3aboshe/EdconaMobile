import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/super_admin/super_admin_dashboard.dart';
import 'services/language_service.dart';
import 'services/auth_service.dart';
import 'utils/locale_delegates.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize EasyLocalization
  await EasyLocalization.ensureInitialized();

  // Initialize services
  AuthService.initialize();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'), // English
        Locale('ar'), // Arabic
        Locale('ckb'), // Kurdish (Sorani)
        Locale('bhn'), // Kurdish (Bahdini)
        Locale('arc'), // Assyrian
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const EdConaApp(),
    ),
  );
}

class EdConaApp extends StatelessWidget {
  const EdConaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EdCona',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        ...context.localizationDelegates,
        const KurdishMaterialLocalizationsDelegate(),
        const KurdishCupertinoLocalizationsDelegate(),
        const AssyrianMaterialLocalizationsDelegate(),
        const AssyrianCupertinoLocalizationsDelegate(),
      ],
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      localeResolutionCallback: (locale, supportedLocales) {
        // If the exact locale is supported, use it
        if (locale != null) {
          for (var supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale.languageCode) {
              return supportedLocale;
            }
          }
        }
        // Map unsupported languages to supported ones for MaterialLocalizations
        if (locale != null) {
          if (locale.languageCode == 'ckb' || locale.languageCode == 'bhn') {
            return const Locale('ar'); // Use Arabic Material localizations for Kurdish
          }
          if (locale.languageCode == 'arc') {
            return const Locale('en'); // Use English Material localizations for Assyrian
          }
        }
        // Fallback to English if locale is not supported
        return const Locale('en');
      },
      theme: ThemeData(
        primaryColor: const Color(0xFF0D47A1), // Deep blue
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D47A1),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D47A1),
            foregroundColor: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2),
          ),
        ),
      ),
      home: const AppInitializer(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/admin': (context) => const AdminDashboard(),
        '/super_admin': (context) => const SuperAdminDashboard(),
      },
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _checkLanguageAndNavigate();
  }

  Future<void> _checkLanguageAndNavigate() async {
    // Wait a bit for localization to initialize
    await Future.delayed(const Duration(milliseconds: 100));

    final selectedLanguageCode = await LanguageService.getSelectedLanguage();
    final authService = AuthService();
    final isLoggedIn = await authService.isLoggedIn();

    if (mounted) {
      // Update context locale
      if (context.mounted) {
        context.setLocale(Locale(selectedLanguageCode));

        // Check if user is already logged in and navigate accordingly
        if (isLoggedIn) {
          final user = await authService.getCurrentUser();
          if (user != null) {
            if (user['role'] == 'SUPER_ADMIN') {
              Navigator.pushReplacementNamed(context, '/super_admin');
            } else if (user['role'] == 'ADMIN' || user['role'] == 'SCHOOL_ADMIN') {
              Navigator.pushReplacementNamed(context, '/admin');
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          }
        } else {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while checking language preference
    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 200,
              height: 80,
              child: Image.asset(
                'assets/logowhite.png',
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.school,
                    size: 60,
                    color: Colors.white,
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}