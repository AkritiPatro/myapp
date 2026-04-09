import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Import for kIsWeb

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  SignInPageState createState() => SignInPageState();
}

class SignInPageState extends State<SignInPage> {
  // CORRECTED: Ensure these are on a single line
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool rememberMe = false;

  void _resetPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      Fluttertoast.showToast(
          msg: "Please enter your email above first.", backgroundColor: Colors.orange);
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      developer.log("Password reset email sent to: $email");
      Fluttertoast.showToast(
          msg: "Password reset link sent to your email 📧",
          backgroundColor: Colors.blue);
    } on FirebaseAuthException catch (e) {
      developer.log("Error sending reset email: ${e.message}");
      Fluttertoast.showToast(
          msg: "Error: ${e.message}", backgroundColor: Colors.red);
    } catch (e) {
      developer.log("General error during password reset: $e");
      Fluttertoast.showToast(
          msg: "Failed to send reset email.", backgroundColor: Colors.red);
    }
  }

  void _signIn() async {
    developer.log("Login attempt started.");

    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Fluttertoast.showToast(
          msg: "Please enter both email and password.", backgroundColor: Colors.red);
      developer.log("Validation failed: Email or password field is empty.");
      return;
    }

    try {
      developer.log("Attempting to sign in with email: ${emailController.text.trim()}");

      // --- MODIFIED: Conditionally call setPersistence for web only ---
      if (kIsWeb) { // Check if the app is running on the web
        try {
          await FirebaseAuth.instance.setPersistence(rememberMe ? Persistence.LOCAL : Persistence.SESSION);
          developer.log("Firebase persistence set to: ${rememberMe ? 'LOCAL' : 'SESSION'} successfully (Web).");
        } catch (eForPersistence) {
          developer.log("Error setting Firebase persistence (Web): $eForPersistence");
          Fluttertoast.showToast(
              msg: "Failed to set login persistence (Web): $eForPersistence", backgroundColor: Colors.red);
          // For web, if persistence fails, we might still want to try signing in.
          // Or decide to return here based on desired web behavior.
        }
      } else {
        developer.log("setPersistence is not supported on non-web platforms, skipping.");
      }
      // --- END MODIFIED ---

      // Attempt actual sign-in
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      developer.log("Login successful for email: ${emailController.text.trim()}");
      Fluttertoast.showToast(
          msg: "Signed in successfully ✅",
          backgroundColor: Colors.green);

      if (mounted) {
        developer.log("Navigating to /devices...");
        context.go('/devices');
        developer.log("Navigation command issued.");
      } else {
        developer.log("Widget not mounted, cannot navigate after successful login.");
      }
    } on FirebaseAuthException catch (e) {
      String message;
      developer.log("FirebaseAuthException caught: Code = ${e.code}, Message = ${e.message}");
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
      developer.log("General error caught during sign in: $e");
      Fluttertoast.showToast(
          msg: "An unexpected error occurred: $e",
          backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    Color inputFillColor = isDark ? Colors.grey[800]! : Colors.white;
    Color inputTextColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: isDark ? Colors.black87 : Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
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
                const SizedBox(height: 50),

                // Email
                TextField(
                  controller: emailController,
                  style: TextStyle(color: inputTextColor),
                  decoration: InputDecoration(
                    hintText: "Email",
                    hintStyle: TextStyle(color: inputTextColor.withAlpha(153)),
                    prefixIcon: Icon(Icons.email, color: inputTextColor),
                    filled: true,
                    fillColor: inputFillColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Password
                TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: inputTextColor),
                  onSubmitted: (_) => _signIn(),
                  decoration: InputDecoration(
                    hintText: "Password",
                    hintStyle: TextStyle(color: inputTextColor.withAlpha(153)),
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
                const SizedBox(height: 10),

                // Forgot Password Link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _resetPassword,
                    child: Text(
                      "Forgot Password?",
                      style: GoogleFonts.poppins(
                        color: isDark ? Colors.tealAccent : Colors.deepPurple,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 5),

                // Remember Me
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return Row(
                      children: [
                        Checkbox(
                          value: rememberMe,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                rememberMe = value;
                              });
                            }
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
                const SizedBox(height: 20),

                // Login Button
                ElevatedButton(
                  onPressed: _signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.tealAccent : Colors.deepPurple,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text("Log In",
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(height: 20),

                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don’t have an account? ",
                        style: GoogleFonts.poppins(color: isDark ? Colors.white70 : Colors.black87)),
                    GestureDetector(
                      onTap: () => context.go('/signup'),
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