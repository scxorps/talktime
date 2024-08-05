import 'package:flutter/material.dart';
import 'package:talktime/screens/chat_screen.dart';
import 'package:talktime/screens/registration_screen.dart';
import 'package:talktime/widgets/my_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class LoginScreen extends StatefulWidget {
  static const String screenRoute = 'signin_screen';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  late String emailOrUsername;
  late String password;

  bool showSpinner = false;
  String errorMessage = '';
  Color passwordBorderColor = Colors.orange; // Default border color
  bool _isPasswordVisible = false; // Manage password visibility

  Future<void> _checkEmailVerification(User user) async {
    await user.reload(); // Refresh user data
    User? refreshedUser = _auth.currentUser; // Get the refreshed user

    if (refreshedUser != null && refreshedUser.emailVerified) {
      Navigator.pushNamed(context, ChatScreen.screenRoute);
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Email Not Verified'),
            content: Text(
              'Your email is not verified. Please verify your email before logging in.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<User?> _signInWithEmailOrUsername(String emailOrUsername, String password) async {
    // Check if the input is an email
    if (RegExp(r"^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$").hasMatch(emailOrUsername)) {
      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: emailOrUsername,
          password: password,
        );
        return userCredential.user;
      } catch (e) {
        print(e);
        return null;
      }
    } else {
      // If not an email, try to find the user by username in the pending_users collection
      try {
        final result = await _firestore.collection('pending_users').where('username', isEqualTo: emailOrUsername).get();
        if (result.docs.isNotEmpty) {
          // Assuming only one user per username
          final userDoc = result.docs.first;
          String email = userDoc['email']; // Retrieve the associated email
          
          // Sign in using the associated email
          UserCredential userCredential = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          return userCredential.user;
        }
        return null;
      } catch (e) {
        print(e);
        return null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: showSpinner,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 180,
                child: Image.asset('assets/images/logo.png'),
              ),
              SizedBox(height: 50),
              TextField(
                keyboardType: TextInputType.text,
                textAlign: TextAlign.center,
                onChanged: (value) {
                  emailOrUsername = value;
                },
                decoration: InputDecoration(
                  hintText: 'Enter your email or username',
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(32)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange, width: 1),
                    borderRadius: BorderRadius.all(Radius.circular(32)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(32)),
                  ),
                ),
              ),
              SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    obscureText: !_isPasswordVisible, // Manage visibility
                    textAlign: TextAlign.center,
                    onChanged: (value) {
                      password = value;
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(32)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: passwordBorderColor, width: 1),
                        borderRadius: BorderRadius.all(Radius.circular(32)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: passwordBorderColor, width: 2),
                        borderRadius: BorderRadius.all(Radius.circular(32)),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible; // Toggle visibility
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  if (errorMessage.isNotEmpty)
                    Text(
                      errorMessage,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 24),
              MyButton(
                title: 'Login',
                onPressed: () async {
                  setState(() {
                    showSpinner = true;
                    errorMessage = ''; // Clear previous error message
                    passwordBorderColor = Colors.orange; // Reset border color
                  });
                  try {
                    final user = await _signInWithEmailOrUsername(emailOrUsername, password);
                    if (user != null) {
                      await _checkEmailVerification(user);
                    } else {
                      // Determine if username or email is invalid
                      bool emailExists = await _firestore.collection('pending_users').where('email', isEqualTo: emailOrUsername).get().then((result) => result.docs.isNotEmpty);
                      bool usernameExists = await _firestore.collection('pending_users').where('username', isEqualTo: emailOrUsername).get().then((result) => result.docs.isNotEmpty);
                      
                      if (emailExists || usernameExists) {
                        setState(() {
                          errorMessage = 'Incorrect password.';
                          passwordBorderColor = Colors.red; // Set border color to red
                        });
                      } else {
                        setState(() {
                          errorMessage = 'Invalid email/username.';
                          passwordBorderColor = Colors.orange; // Reset border color
                        });
                      }
                    }
                  } catch (e) {
                    print(e);
                    setState(() {
                      errorMessage = 'An error occurred. Please try again.';
                      passwordBorderColor = Colors.orange; // Reset border color
                    });
                  } finally {
                    setState(() {
                      showSpinner = false;
                    });
                  }
                },
                color: Colors.green[800]!,
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? "),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, RegistrationScreen.screenRoute);
                    },
                    child: Text(
                      'Register',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
