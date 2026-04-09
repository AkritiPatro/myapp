import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'device_provider.dart';
import 'theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'router.dart'; // Import the new router

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Attempt DotEnv load with error handling
    // Load app.env file from assets
    try {
      await dotenv.load(fileName: "assets/app.env");
      debugPrint('✅ DotEnv loaded successfully from assets/app.env');
    } catch (e) {
      debugPrint('⚠️ DotEnv load failed for assets/app.env: $e');
      // Fallback or handle missing env gracefully
    }

    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    debugPrint('✅ Firebase initialized');
    
    runApp(const SaneMachineApp());
  } catch (error, stack) {
    debugPrint('❌ FATAL STARTUP ERROR:');
    debugPrint('Error: $error');
    debugPrint('Stack: $stack');
    
    // Fallback UI to show the error instead of a white screen
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text('Initialization Error: $error\n\nCheck logs for details.', 
                style: const TextStyle(color: Colors.red)),
          ),
        ),
      ),
    ));
  }
}

class SaneMachineApp extends StatelessWidget {
  const SaneMachineApp({super.key});

  // Analytics can be accessed via FirebaseAnalytics.instance directly when needed
  // rather than being initialized as static members which can crash on boot.

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
                centerTitle: false,
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
                centerTitle: false,
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