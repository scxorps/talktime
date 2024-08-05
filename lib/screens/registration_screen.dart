import 'package:flutter/material.dart';
import 'package:talktime/screens/login_screen.dart'; // Import your login screen
import 'package:talktime/widgets/my_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class RegistrationScreen extends StatefulWidget {
  static const String screenRoute = 'registration_screen';
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  late String email;
  late String password;
  late String confirmPassword;
  late String username;

  bool showSpinner = false;
  bool passwordsMatch = true;
  bool emailAlreadyExists = false;
  bool usernameAlreadyExists = false;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<bool> _checkIfEmailExists(String email) async {
    try {
      final result = await _firestore.collection('pending_users').where('email', isEqualTo: email).get();
      return result.docs.isNotEmpty;
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }

  Future<bool> _checkIfUsernameExists(String username) async {
    try {
      final result = await _firestore.collection('pending_users').where('username', isEqualTo: username).get();
      return result.docs.isNotEmpty;
    } catch (e) {
      print('Error checking username: $e');
      return false;
    }
  }

  Future<void> _storePendingRegistration(String email, String password, String username) async {
    try {
      await _firestore.collection('pending_users').add({
        'email': email,
        'password': password,
        'username': username,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error storing registration: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 180,
                    child: Image.asset('assets/images/logo.png'),
                  ),
                  SizedBox(height: 50),
                  TextFormField(
                    keyboardType: TextInputType.text,
                    textAlign: TextAlign.center,
                    onChanged: (value) {
                      username = value;
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter your username',
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Username is required';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    keyboardType: TextInputType.emailAddress,
                    textAlign: TextAlign.center,
                    onChanged: (value) {
                      email = value;
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter your email',
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email is required';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    obscureText: !_isPasswordVisible,
                    textAlign: TextAlign.center,
                    onChanged: (value) {
                      password = value;
                    },
                    decoration: InputDecoration(
                      hintText: 'Create your password',
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
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    obscureText: !_isConfirmPasswordVisible,
                    textAlign: TextAlign.center,
                    onChanged: (value) {
                      confirmPassword = value;
                      setState(() {
                        passwordsMatch = password == confirmPassword;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Confirm your password',
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
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Confirm password is required';
                      }
                      if (value != password) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 24),
                  MyButton(
                    color: Colors.blue[800]!,
                    title: 'Register',
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          showSpinner = true;
                        });

                        // Check if email or username already exists
                        emailAlreadyExists = await _checkIfEmailExists(email);
                        usernameAlreadyExists = await _checkIfUsernameExists(username);

                        if (emailAlreadyExists) {
                          setState(() {
                            showSpinner = false; // Reset spinner before showing dialog
                          });
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text('Email Already Exists'),
                                content: Text('The email you entered is already registered. Please use a different email.'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushReplacementNamed(context, LoginScreen.screenRoute);
                                    },
                                    child: Text('Go to Login'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      setState(() {
                                        showSpinner = false; // Reset spinner after closing dialog
                                      });
                                    },
                                    child: Text('Go Back'),
                                  ),
                                ],
                              );
                            },
                          );
                        } else if (usernameAlreadyExists) {
                          setState(() {
                            showSpinner = false; // Reset spinner before showing dialog
                          });
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text('Username Already Exists'),
                                content: Text('The username you entered is already taken. Please choose a different username.'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushReplacementNamed(context, LoginScreen.screenRoute);
                                    },
                                    child: Text('Go to Login'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      setState(() {
                                        showSpinner = false; // Reset spinner after closing dialog
                                      });
                                    },
                                    child: Text('Go Back'),
                                  ),
                                ],
                              );
                            },
                          );
                        } else {
                          // Store the pending user and show success message
                          await _storePendingRegistration(email, password, username);
                          setState(() {
                            showSpinner = false; // Reset spinner after storing data
                          });

                          // Show verification message and timer
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text('Check Your Email'),
                                content: Text('A validation email has been sent to you. Please confirm your account and navigate to login. You can request a new verification email in 2:00.'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushReplacementNamed(context, LoginScreen.screenRoute);
                                    },
                                    child: Text('Go to Login'),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      }
                    },
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account?'),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, LoginScreen.screenRoute);
                        },
                        child: Text('Go to Login'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
