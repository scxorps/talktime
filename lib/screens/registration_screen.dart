import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:talktime/screens/login_screen.dart';
import 'package:talktime/widgets/my_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:talktime/widgets/password_strength_indicator.dart';
import 'package:crypto/crypto.dart';

class RegistrationScreen extends StatefulWidget {
  static const String screenRoute = 'registration_screen';
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String email = '';
  String password = '';
  String confirmPassword = '';
  String username = '';

  bool showSpinner = false;
  bool passwordsMatch = true;
  bool emailAlreadyExists = false;
  bool usernameAlreadyExists = false;
  bool _isPasswordEntered = false;
  bool _isConfirmPasswordEntered = false;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? _emailError;
  String? _usernameError;
  String? _passwordError;
  String? _confirmPasswordError;

  // Check if the email already exists in 'pending_users' or 'current_users' collections
  Future<bool> _checkIfEmailExists(String email) async {
    try {
      final pendingUsersResult = await _firestore.collection('pending_users').where('email', isEqualTo: email).get();
      final currentUsersResult = await _firestore.collection('current_users').where('email', isEqualTo: email).get();
      return pendingUsersResult.docs.isNotEmpty || currentUsersResult.docs.isNotEmpty;
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }

  // Check if the username already exists in 'pending_users' or 'current_users' collections
  Future<bool> _checkIfUsernameExists(String username) async {
    try {
      final pendingUsersResult = await _firestore.collection('pending_users').where('username', isEqualTo: username).get();
      final currentUsersResult = await _firestore.collection('current_users').where('username', isEqualTo: username).get();
      return pendingUsersResult.docs.isNotEmpty || currentUsersResult.docs.isNotEmpty;
    } catch (e) {
      print('Error checking username: $e');
      return false;
    }
  }

  // Store user registration details in 'pending_users' collection
  Future<void> _storePendingRegistration(String email, String password, String username) async {
    try {
      String hashedPassword = _hashPassword(password); // Hash the password

      await _firestore.collection('pending_users').add({
        'email': email,
        'password': hashedPassword, // Store hashed password
        'username': username,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('Pending registration stored successfully');
    } catch (e) {
      print('Error storing pending registration: $e');
    }
  }

  // Send email verification to the newly registered user
  Future<void> _sendValidationEmail(User user) async {
    try {
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        print('Verification email sent to ${user.email}');
      } else {
        print('User is null or email is already verified');
      }
    } catch (e) {
      print('Error sending verification email: $e');
    }
  }

  // Validate the form fields and display errors
  void _validateForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        showSpinner = true;
      });

      try {
        emailAlreadyExists = await _checkIfEmailExists(email);
        usernameAlreadyExists = await _checkIfUsernameExists(username);

        if (emailAlreadyExists) {
          setState(() {
            _emailError = 'Email already exists. Please try logging in.';
          });
        } else if (usernameAlreadyExists) {
          setState(() {
            _usernameError = 'Username already exists. Please try another one.';
          });
        } else {
          // Register user and store in Firestore
          UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          await _storePendingRegistration(email, password, username);
          await _sendValidationEmail(userCredential.user!);
          Navigator.pushNamed(context, LoginScreen.screenRoute);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('A validation email has been sent to $email. Please confirm your account and navigate to login.'),
            ),
          );
        }
      } catch (e) {
        print('Registration error: $e');
      } finally {
        setState(() {
          showSpinner = false;
        });
      }
    }
  }

  // Validate email format
  String? _validateEmail(String? value) {
    final emailRegExp = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    if (value == null || value.isEmpty) {
      return 'Email is required';
    } else if (!emailRegExp.hasMatch(value)) {
      return 'Email is badly formatted';
    }
    return null;
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
                  Column(
                    children: [
                      Container(
                        height: 180,
                        child: Image.asset('assets/images/logo.png'),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'TalkTime',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  SizedBox(height: 50),
                  TextFormField(
                    controller: _usernameController,
                    keyboardType: TextInputType.text,
                    textAlign: TextAlign.center,
                    onChanged: (value) {
                      setState(() {
                        username = value;
                        _usernameError = null; // Clear error message
                      });
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
                      errorText: _usernameError,
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
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textAlign: TextAlign.center,
                    onChanged: (value) {
                      setState(() {
                        email = value;
                        _emailError = null; // Clear error message
                      });
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
                      errorText: _emailError,
                    ),
                    validator: (value) {
                      return _validateEmail(value);
                    },
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    textAlign: TextAlign.center,
                    onChanged: (value) {
                      setState(() {
                        password = value;
                        _isPasswordEntered = password.isNotEmpty;
                        passwordsMatch = password == confirmPassword;
                        _passwordError = null; // Clear error message
                      });
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
                        borderSide: BorderSide(
                          color: _isPasswordEntered && passwordsMatch ? Colors.green : Colors.orange,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(32)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: _isPasswordEntered && passwordsMatch ? Colors.green : Colors.deepPurple,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(32)),
                      ),
                      prefixIcon: _isPasswordEntered
                          ? PasswordStrengthIndicator(password: password)
                          : null,
                      suffixIcon: _isPasswordEntered
                          ? IconButton(
                              icon: Icon(
                                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            )
                          : null,
                      errorText: _passwordError,
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
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    textAlign: TextAlign.center,
                    onChanged: (value) {
                      setState(() {
                        confirmPassword = value;
                        _isConfirmPasswordEntered = confirmPassword.isNotEmpty;
                        passwordsMatch = password == confirmPassword;
                        _confirmPasswordError = null; // Clear error message
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
                        borderSide: BorderSide(
                          color: _isConfirmPasswordEntered && passwordsMatch ? Colors.green : Colors.orange,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(32)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: _isConfirmPasswordEntered && passwordsMatch ? Colors.green : Colors.deepPurple,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(32)),
                      ),
                      suffixIcon: _isConfirmPasswordEntered
                        ? IconButton(
                            icon: Icon(
                              _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                              });
                            },
                          )
                        : null,
                      errorText: _confirmPasswordError,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Confirm password is required';
                      }
                      if (value != password) {
                        return 'Passwords should match';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 24),
                  MyButton(
                    color: Colors.blue,
                    title: 'Register',
                    onPressed: _validateForm,
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already registered? '),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, LoginScreen.screenRoute);
                        },
                        child: Text(
                          'Go to Login',
                          style: TextStyle(color: Colors.blue),
                        ),
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

  // Function to hash the password using SHA-256
  String _hashPassword(String password) {
    var bytes = utf8.encode(password); // Encode the password to UTF-8
    var digest = sha256.convert(bytes); // Apply SHA-256 hashing
    return digest.toString(); // Return the hashed password as a string
  }
}
