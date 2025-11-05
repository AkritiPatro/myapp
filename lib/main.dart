import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // <--- ADD/CONFIRM THIS IMPORT
import 'sign_in.dart';
import 'sign_up.dart';
import 'device_page.dart';
import 'device_provider.dart';
import 'theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart'; // <--- ADD/CONFIRM THIS IMPORT

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Ensure the .env file is loaded BEFORE Firebase.initializeApp()
  await dotenv.load(fileName: ".env"); // <--- ADD/CONFIRM THIS LINE
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AuthWrapper());
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => DeviceProvider()),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: SaneMachineApp(key: ValueKey(user?.uid)),
        );
      },
    );
  }
}

class SaneMachineApp extends StatelessWidget {
  const SaneMachineApp({super.key});

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(
    analytics: analytics,
  );

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authUser = FirebaseAuth.instance.currentUser;

    // --- CRUCIAL PRINT STATEMENTS FOR DIAGNOSIS ---
    print('SaneMachineApp build method called.');
    print('Current authenticated user (authUser): ${authUser?.uid ?? "null"}');
    final String resolvedInitialRoute = authUser == null ? '/' : '/devices';
    print('Resolved initialRoute: $resolvedInitialRoute');
    // --- END CRUCIAL PRINTS ---

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sane Machine',
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.deepPurpleAccent,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.deepPurple,
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.all(Colors.deepPurple),
          checkColor: WidgetStateProperty.all(Colors.white),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.tealAccent,
        scaffoldBackgroundColor: Colors.grey[900], // Consistent grey shade
        unselectedWidgetColor: Colors.deepPurple,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black87,
          foregroundColor: Colors.tealAccent,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.tealAccent,
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.all(Colors.tealAccent),
          checkColor: WidgetStateProperty.all(Colors.black),
        ),
      ),
      navigatorObservers: <NavigatorObserver>[observer],
      initialRoute: resolvedInitialRoute,
      routes: {
        '/': (context) => LandingPage(),
        '/signin': (context) => SignInPage(),
        '/signup': (context) => SignUpPage(),
        '/devices': (context) => DevicePage(),
        '/chatbot': (context) => const ChatScreen(),
      },
    );
  }
}

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    Color primaryColor = isDark ? Colors.tealAccent : Colors.deepPurple;

    return Scaffold(
      backgroundColor: isDark ? Colors.black87 : Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your app logo/text, which is "Sane Machine"
            Text(
              'Sane Machine',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Welcome to Sane Machine. Sign in or Sign up to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: isDark ? Colors.black : Colors.white,
                minimumSize: const Size(200, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/signin');
              },
              child: Text(
                'Sign In',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.black : Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                minimumSize: const Size(200, 50),
                side: BorderSide(color: primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/signup');
              },
              child: Text(
                'Sign Up',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
