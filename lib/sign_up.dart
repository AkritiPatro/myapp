import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  SignUpPageState createState() => SignUpPageState();
}

class SignUpPageState extends State<SignUpPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false; // Added loading state

  void _signUp() async {
    // 0. Initial state check
    if (_isLoading) return;

    // Input validation: Check if any field is empty
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      Fluttertoast.showToast(
          msg: "Please fill all fields", backgroundColor: Colors.red);
      developer.log('Validation failed: All fields not filled.');
      return; // Exit function if validation fails
    }

    setState(() {
      _isLoading = true;
    });

    User? createdUser; 

    try {
      developer.log('Signup process started for email: ${emailController.text.trim()}');

      // 1. Authenticate user with Firebase Auth
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      createdUser = userCredential.user;

      // --- CRUCIAL CHECK: Ensure user is available after Auth ---
      if (createdUser == null) {
        throw FirebaseAuthException(
            code: 'user-null-after-auth',
            message: 'Firebase Auth user is null after successful creation.');
      }
      developer.log('Firebase Auth user created with UID: ${createdUser.uid}');
      
      // Update profile name in Auth
      await createdUser.updateDisplayName(nameController.text.trim());
      developer.log('Auth user display name updated to: ${nameController.text.trim()}');

      // 2. Save user data to Firestore
      developer.log('Attempting to save user data to Firestore for UID: ${createdUser.uid}');
      
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(createdUser.uid)
            .set({
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'role': 'user', // Default role
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        developer.log('User data successfully saved to Firestore for UID: ${createdUser.uid}');
      } catch (firestoreError) {
        // --- ROLLBACK: Delete auth user if Firestore write fails ---
        developer.log('Firestore write FAILED. Rolling back Auth user...');
        await createdUser.delete();
        developer.log('Auth user deleted successfully.');
        
        if (firestoreError is FirebaseException && firestoreError.code == 'permission-denied') {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
            message: 'Database permission denied. Please ensure Firestore Rules allow writes to /users/{uid}.'
          );
        }
        rethrow;
      }

      Fluttertoast.showToast(
          msg: "Account created successfully ✅",
          backgroundColor: Colors.green);

      // 3. Navigate to the next screen if widget is mounted
      if (mounted) {
        context.go('/devices');
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'The account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      } else {
        message = 'Authentication Error: ${e.message}';
      }
      developer.log('Firebase Auth Exception: $message');
      Fluttertoast.showToast(msg: message, backgroundColor: Colors.red);
    } catch (e) {
      // Catch any other general exceptions (e.g., Firestore write error)
      String errorMsg = e.toString();
      if (errorMsg.contains('permission-denied')) {
        errorMsg = "Database Permissions Error: Check Firestore Rules.";
      }
      developer.log('General Signup/Firestore Error: $e');
      Fluttertoast.showToast(
          msg: errorMsg,
          backgroundColor: Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    Color inputFillColor = isDark ? Colors.grey[800]! : Colors.white;
    Color inputTextColor = isDark ? Colors.white : Colors.black87;
    Color buttonColor = isDark ? Colors.tealAccent : Colors.deepPurple;

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
                  "Create Account",
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.tealAccent : Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 50),

                // Name Field
                TextField(
                  controller: nameController,
                  style: TextStyle(color: inputTextColor),
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: "Full Name",
                    hintStyle: TextStyle(color: inputTextColor.withAlpha(153)),
                    prefixIcon: Icon(Icons.person, color: inputTextColor),
                    filled: true,
                    fillColor: inputFillColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Email Field
                TextField(
                  controller: emailController,
                  style: TextStyle(color: inputTextColor),
                  enabled: !_isLoading,
                  keyboardType: TextInputType.emailAddress,
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

                // Password Field
                TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: inputTextColor),
                  enabled: !_isLoading,
                  onSubmitted: (_) => _signUp(),
                  decoration: InputDecoration(
                    hintText: "Password",
                    hintStyle: TextStyle(color: inputTextColor.withAlpha(153)),
                    prefixIcon: Icon(Icons.lock, color: inputTextColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
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
                const SizedBox(height: 30),

                // Sign Up Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    disabledBackgroundColor: buttonColor.withAlpha(128),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          "Sign Up",
                          style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                ),
                const SizedBox(height: 25),

                // Already have account? Sign In
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account? ",
                        style: GoogleFonts.poppins(
                            color: isDark ? Colors.white70 : Colors.black87)),
                    GestureDetector(
                      onTap: _isLoading ? null : () => context.go('/signin'),
                      child: Text(
                        "Sign In",
                        style: GoogleFonts.poppins(
                            color: buttonColor,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}