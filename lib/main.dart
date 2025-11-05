import 'dart:async'; // Import the async library for runZonedGuarded
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'device_provider.dart';
import 'theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'router.dart'; // Import the new router

void main() async {
  // Use runZonedGuarded to catch all errors
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: ".env");
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    runApp(const SaneMachineApp());
  }, (error, stack) {
    // This will be executed whenever an error is caught
    developer.log('🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥');
    developer.log('FATAL ERROR CAUGHT BY runZonedGuarded:');
    developer.log('Error: $error');
    developer.log('Stack trace: $stack');
    developer.log('🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥');
  });
}

class SaneMachineApp extends StatelessWidget {
  const SaneMachineApp({super.key});

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(
    analytics: analytics,
  );

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final baseLightTheme = ThemeData.light();
          final baseDarkTheme = ThemeData.dark();

          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Sane Machine',
            themeMode: themeProvider.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            theme: ThemeData(
              brightness: Brightness.light,
              primaryColor: Colors.deepPurple,
              scaffoldBackgroundColor: Colors.white,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.deepPurpleAccent,
                foregroundColor: Colors.white,
                iconTheme: IconThemeData(color: Colors.white),
              ),
              floatingActionButtonTheme:
                  const FloatingActionButtonThemeData(
                backgroundColor: Colors.deepPurple,
              ),
              checkboxTheme: CheckboxThemeData(
                fillColor:
                    WidgetStateProperty.all(Colors.deepPurple),
                checkColor: WidgetStateProperty.all(Colors.white),
              ),
              textTheme: GoogleFonts.poppinsTextTheme(baseLightTheme.textTheme),
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primaryColor: Colors.tealAccent,
              scaffoldBackgroundColor: Colors.grey[900],
              unselectedWidgetColor: Colors.deepPurple,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.tealAccent,
                iconTheme: IconThemeData(color: Colors.tealAccent),
              ),
              floatingActionButtonTheme:
                  const FloatingActionButtonThemeData(
                backgroundColor: Colors.tealAccent,
              ),
              checkboxTheme: CheckboxThemeData(
                fillColor: WidgetStateProperty.all(Colors.tealAccent),
                checkColor: WidgetStateProperty.all(Colors.black),
              ),
              textTheme: GoogleFonts.poppinsTextTheme(baseDarkTheme.textTheme),
            ),
            routerConfig: router, // Use the new router configuration
          );
        },
      ),
    );
  }
}
