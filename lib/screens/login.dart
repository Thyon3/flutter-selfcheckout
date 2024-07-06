import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:selfcheckoutapp/screens/register.dart';
import 'package:selfcheckoutapp/services/firebase_services.dart';
import 'package:selfcheckoutapp/widgets/custom_button.dart';
import 'package:selfcheckoutapp/widgets/custom_input.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseServices _firebaseServices = FirebaseServices();
  bool _isLoading = false;

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorDialog('Please fill in all fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _firebaseServices.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (user == null) {
        _showErrorDialog('Invalid email or password');
      }
    } catch (e) {
      _showErrorDialog('Login failed: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 60.0),
                Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 32.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff1faa00),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10.0),
                Text(
                  'Sign in to continue shopping',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                        MaterialPageRoute(
                            builder: (context) => RegisterPage()
                        )
                    );
                  },
                  outlineBtn: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
