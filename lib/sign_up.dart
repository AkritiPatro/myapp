import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;

  void _signUp() async {
    // Input validation: Check if any field is empty
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      Fluttertoast.showToast(
          msg: "Please fill all fields", backgroundColor: Colors.red);
      print('Validation failed: All fields not filled.');
      return; // Exit function if validation fails
    }

    try {
      print('Signup process started for email: ${emailController.text.trim()}');

      // 1. Authenticate user with Firebase Auth
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // --- CRUCIAL CHECK: Ensure user is available after Auth ---
      if (userCredential.user == null) {
        throw FirebaseAuthException(
            code: 'user-null-after-auth',
            message: 'Firebase Auth user is null after successful creation.');
      }
      print('Firebase Auth user created with UID: ${userCredential.user!.uid}');

      // 2. Save user data to Firestore
      print('Attempting to save user data to Firestore for UID: ${userCredential.user!.uid}');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(), // Added timestamp for debugging/future use
      }, SetOptions(merge: true)); // Using merge:true is safer for updates, though .set() without merge
                                   // also works for initial creation.

      print('User data successfully saved to Firestore for UID: ${userCredential.user!.uid}');

      Fluttertoast.showToast(
          msg: "Account created successfully ✅",
          backgroundColor: Colors.green);

      // 3. Navigate to the next screen if widget is mounted
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/devices');
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
        message = 'Firebase Auth Error: ${e.message} (Code: ${e.code})';
      }
      print('Firebase Auth Exception during signup: $message');
      Fluttertoast.showToast(msg: message, backgroundColor: Colors.red);
    } catch (e, stacktrace) {
      // Catch any other general exceptions (e.g., Firestore write error, network issues)
      print('General Error during signup/Firestore save: $e');
      print('Stacktrace: $stacktrace'); // Print stacktrace for more context
      Fluttertoast.showToast(
          msg: "An unexpected error occurred: $e",
          backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    Color gradientStart = isDark ? Colors.deepPurple : Colors.purpleAccent;
    Color gradientEnd = isDark ? Colors.black87 : Colors.deepPurpleAccent;
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
                  decoration: InputDecoration(
                    hintText: "Full Name",
                    hintStyle: TextStyle(color: inputTextColor.withOpacity(0.6)),
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
                const SizedBox(height: 16),

                // Password Field
                TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: inputTextColor),
                  onSubmitted: (_) => _signUp(),
                  decoration: InputDecoration(
                    hintText: "Password",
                    hintStyle: TextStyle(color: inputTextColor.withOpacity(0.6)),
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
                  onPressed: _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
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
                      onTap: () => Navigator.pushNamed(context, '/signin'),
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
