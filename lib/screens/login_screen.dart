import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_3/main.dart';
import 'sign_up_screen.dart';
import 'vendor_sign_up_screen.dart';
import 'vendor_panel.dart';
import 'admin_panel.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Function to handle login
  Future<void> _login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _showSnackbar('Please fill in all fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Sign in with Firebase Authentication
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      User? user = userCredential.user;
      if (user == null) {
        _showSnackbar('User not found.');
        return;
      }

      // Retrieve the ID token result to check custom claims
      IdTokenResult idTokenResult = await user.getIdTokenResult(true);

      // Check if the admin claim is present
      if (idTokenResult.claims != null && idTokenResult.claims!['admin'] == true) {
        _showSnackbar('Admin Login Successful!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminPanelScreen()),
        );
        return;
      }

      // If not an admin, fetch user role from Firestore
      String userId = user.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        // Retrieve the role and status from Firestore data
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String role = userData['role'] ?? 'user';
        String status = userData['status'] ?? 'active';

        // Check if the user's account is active
        if (status.toLowerCase() == 'inactive') {
          await _auth.signOut(); // Sign out the user
          _showSnackbar('Your account has been deactivated. Please contact support.');
          return;
        }

        _showSnackbar('Login Successful!');
        if (role == 'vendor') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => VendorPanelScreen(vendorId: userId)),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainScreen()),
          );
        }
      } else {
        _showSnackbar('User data not found in database!');
      }
    } on FirebaseAuthException catch (e) {
      String message = _getFirebaseErrorMessage(e.code);
      _showSnackbar(message);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Function to handle Forgot Password
  Future<void> _forgotPassword() async {
    if (emailController.text.isEmpty) {
      _showSnackbar('Enter your email to reset password');
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: emailController.text.trim());
      _showSnackbar('Password reset email sent! Check your inbox.');
    } catch (e) {
      _showSnackbar('Error: ${e.toString()}');
    }
  }

  // Utility: Show Snackbar message
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // Map Firebase error codes to user-friendly messages
  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Invalid password.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Image.asset('assets/images/nutriselect.png', height: 100),
              SizedBox(height: 20),

              // Email Field
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),

              // Password Field with Visibility Toggle
              TextField(
                controller: passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),

              // Login Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Login'),
              ),
              SizedBox(height: 20),

              // Forgot Password Button
              TextButton(
                onPressed: _forgotPassword,
                child: Text('Forgot Password?', style: TextStyle(color: Colors.green)),
              ),

              // User Signup Button
              TextButton(
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (context) => SignUpScreen())),
                child: Text('Don\'t have an account? Sign Up', style: TextStyle(color: Colors.green)),
              ),

              // Vendor Signup Button
              TextButton(
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (context) => VendorSignUpScreen())),
                child: Text('Register as Vendor', style: TextStyle(color: Colors.green)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
