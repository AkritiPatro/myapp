import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Import for kIsWeb

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  // CORRECTED: Ensure these are on a single line
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool rememberMe = false;

  void _signIn() async {
    print("Login attempt started.");

    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Fluttertoast.showToast(
          msg: "Please enter both email and password.", backgroundColor: Colors.red);
      print("Validation failed: Email or password field is empty.");
      return;
    }

    try {
      print("Attempting to sign in with email: ${emailController.text.trim()}");

      // --- MODIFIED: Conditionally call setPersistence for web only ---
      if (kIsWeb) { // Check if the app is running on the web
        try {
          await FirebaseAuth.instance.setPersistence(rememberMe ? Persistence.LOCAL : Persistence.SESSION);
          print("Firebase persistence set to: ${rememberMe ? 'LOCAL' : 'SESSION'} successfully (Web).");
        } catch (eForPersistence) {
          print("Error setting Firebase persistence (Web): $eForPersistence");
          Fluttertoast.showToast(
              msg: "Failed to set login persistence (Web): $eForPersistence", backgroundColor: Colors.red);
          // For web, if persistence fails, we might still want to try signing in.
          // Or decide to return here based on desired web behavior.
        }
      } else {
        print("setPersistence is not supported on non-web platforms, skipping.");
      }
      // --- END MODIFIED ---

      // Attempt actual sign-in
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      print("Login successful for email: ${emailController.text.trim()}");
      Fluttertoast.showToast(
          msg: "Signed in successfully ✅",
          backgroundColor: Colors.green);

      if (mounted) {
        print("Navigating to /devices...");
        Navigator.pushNamed(context, '/devices');
        print("Navigation command issued.");
      } else {
        print("Widget not mounted, cannot navigate after successful login.");
      }
    } on FirebaseAuthException catch (e) {
      String message;
      print("FirebaseAuthException caught: Code = ${e.code}, Message = ${e.message}");
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided for that user.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many failed login attempts. Try again later.';
      } else if (e.code == 'network-request-failed') {
        message = 'Network error. Please check your internet connection.';
      }
      else {
        message = 'Firebase Auth Error: ${e.message}. Please try again.';
      }
      Fluttertoast.showToast(msg: message, backgroundColor: Colors.red);
    } catch (e) {
      print("General error caught during sign in: $e");
      Fluttertoast.showToast(
          msg: "An unexpected error occurred: $e",
          backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    // These gradient colors are not used in the current UI logic directly,
    // but kept from your original code.
    // The warnings about unused local variables (gradientStart, gradientEnd) 
    // are benign; you can remove those lines if you wish.
    Color gradientStart = isDark ? Colors.deepPurple : Colors.blueAccent;
    Color gradientEnd = isDark ? Colors.black87 : Colors.lightBlueAccent;

    Color inputFillColor = isDark ? Colors.grey[800]! : Colors.white;
    Color inputTextColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: isDark ? Colors.black87 : Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Sane Machine",
                  style: GoogleFonts.poppins(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.tealAccent : Colors.deepPurple),
                ),
                SizedBox(height: 50),

                // Email
                TextField(
                  controller: emailController,
                  style: TextStyle(color: inputTextColor),
                  decoration: InputDecoration(
                    hintText: "Email",
                    hintStyle: TextStyle(color: inputTextColor.withOpacity(0.6)),
                    prefixIcon: Icon(Icons.email, color: inputTextColor),
                    filled: true,
                    fillColor: inputFillColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Password
                TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: inputTextColor),
                  onSubmitted: (_) => _signIn(),
                  decoration: InputDecoration(
                    hintText: "Password",
                    hintStyle: TextStyle(color: inputTextColor.withOpacity(0.6)),
                    prefixIcon: Icon(Icons.lock, color: inputTextColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: inputTextColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: inputFillColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 10),

                // Remember Me
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return Row(
                      children: [
                        Checkbox(
                          value: rememberMe,
                          onChanged: (value) {
                            setState(() {
                              rememberMe = value!;
                            });
                          },
                          activeColor: Colors.grey,
                          checkColor: Colors.white,
                        ),
                        Text("Remember Me",
                            style: GoogleFonts.poppins(color: isDark ? Colors.white : Colors.black87)),
                      ],
                    );
                  },
                ),
                SizedBox(height: 20),

                // Login Button
                ElevatedButton(
                  onPressed: _signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.tealAccent : Colors.deepPurple,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text("Log In",
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                SizedBox(height: 20),

                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don’t have an account? ",
                        style: GoogleFonts.poppins(color: isDark ? Colors.white70 : Colors.black87)),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/signup'),
                      child: Text(
                        "Sign Up",
                        style: GoogleFonts.poppins(
                            color: isDark ? Colors.tealAccent : Colors.deepPurple,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
