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

  String emailOrUsername = '';
  String password = '';
  bool showSpinner = false;
  String errorMessage = '';
  Color passwordBorderColor = Colors.orange;
  bool _isPasswordVisible = false;
  bool _isPasswordEntered = false;
  int _failedAttempts = 0;
  bool _showForgotPasswordDialog = false;
  String _lastEnteredUsernameOrEmail = '';

  Future<User?> _signInWithEmailOrUsername(String emailOrUsername, String password) async {
  try {
    if (RegExp(r"^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$").hasMatch(emailOrUsername)) {
      // Sign in with email and password
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailOrUsername,
        password: password,
      );
      return userCredential.user;
    } else {
      // Handle username login
      final result = await _firestore.collection('pending_users').where('username', isEqualTo: emailOrUsername).get();
      if (result.docs.isNotEmpty) {
        final userDoc = result.docs.first;
        String email = userDoc['email'];
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        return userCredential.user;
      }
      return null;
    }
  } catch (e) {
    print('Error during sign-in: $e');
    return null;
  }
}


  Future<void> _handleForgotPassword(String email) async {
    if (email.isEmpty) {
      _showDialog('Invalid Input', 'Please enter your email address.');
      return;
    }

    bool isEmailAssociated = await _checkEmailAssociatedWithUsername(_lastEnteredUsernameOrEmail, email);

    if (isEmailAssociated) {
      await _sendPasswordResetEmail(email);
    } else {
      _showDialog('Invalid Email', 'The email address does not match the username or email used during login attempts.');
    }
  }

  Future<void> _sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showDialog('Password Reset', 'A password reset email has been sent to $email. Please follow the instructions to reset your password.');
    } catch (e) {
      print(e);
      _showDialog('Error', 'Failed to send password reset email. Please try again later.');
    }
  }

  Future<bool> _checkEmailAssociatedWithUsername(String usernameOrEmail, String email) async {
    if (RegExp(r"^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$").hasMatch(usernameOrEmail)) {
      return usernameOrEmail == email;
    } else {
      final result = await _firestore.collection('pending_users').where('username', isEqualTo: usernameOrEmail).get();
      if (result.docs.isNotEmpty) {
        final userDoc = result.docs.first;
        String associatedEmail = userDoc['email'];
        return associatedEmail == email;
      }
      return false;
    }
  }

 Future<void> _login() async {
  if (emailOrUsername.isEmpty) {
    setState(() {
      errorMessage = 'Please enter your username or email.';
      passwordBorderColor = Colors.orange;
    });
    return;
  }
  if (password.isEmpty) {
    setState(() {
      errorMessage = 'Please enter your password.';
      passwordBorderColor = Colors.orange;
    });
    return;
  }

  setState(() {
    showSpinner = true;
    errorMessage = '';
    passwordBorderColor = Colors.orange;
  });

  try {
    final user = await _signInWithEmailOrUsername(emailOrUsername, password);

    if (user != null) {
      if (user.emailVerified) {
        final currentUserSnapshot = await _firestore.collection('current_users').doc(user.uid).get();
        print('Current user data: ${currentUserSnapshot.data()}');

        if (currentUserSnapshot.exists) {
          Navigator.pushNamed(context, ChatScreen.screenRoute);
        } else {
          final pendingUsersSnapshot = await _firestore.collection('pending_users').where('email', isEqualTo: user.email).get();
          print('Pending users count: ${pendingUsersSnapshot.docs.length}');

          if (pendingUsersSnapshot.docs.isNotEmpty) {
            final pendingUserDoc = pendingUsersSnapshot.docs.first;
            final data = pendingUserDoc.data();

            await _firestore.collection('current_users').doc(user.uid).set({
              'username': data['username'],
              'email': data['email'],
              'profilePicture': data['profilePicture'],
              'createdAt': FieldValue.serverTimestamp(),
              'password' : data['password'],
            });

            await pendingUserDoc.reference.delete();

            Navigator.pushNamed(context, ChatScreen.screenRoute);
          } else {
            await _firestore.collection('current_users').doc(user.uid).set({
              'username': emailOrUsername,
              'email': user.email ?? '',
              'profilePicture': 'https://example.com/default-profile-picture.png',
              'createdAt': FieldValue.serverTimestamp(),
              'password' : password,
            });

            Navigator.pushNamed(context, ChatScreen.screenRoute);
          }
        }

        setState(() {
          _failedAttempts = 0;
          _showForgotPasswordDialog = false;
          _lastEnteredUsernameOrEmail = '';
        });

      } else {
        setState(() {
          errorMessage = 'Your email is not verified. Please verify your email before logging in.';
          passwordBorderColor = Colors.orange;
        });
      }

    } else {
      bool emailExistsInPending = (await _firestore.collection('pending_users').where('email', isEqualTo: emailOrUsername).get()).docs.isNotEmpty;
      bool usernameExistsInPending = (await _firestore.collection('pending_users').where('username', isEqualTo: emailOrUsername).get()).docs.isNotEmpty;
      bool emailExistsInCurrent = (await _firestore.collection('current_users').where('email', isEqualTo: emailOrUsername).get()).docs.isNotEmpty;
      bool usernameExistsInCurrent = (await _firestore.collection('current_users').where('username', isEqualTo: emailOrUsername).get()).docs.isNotEmpty;

      if (emailExistsInPending || usernameExistsInPending || emailExistsInCurrent || usernameExistsInCurrent) {
        setState(() {
          errorMessage = 'Incorrect password.';
          passwordBorderColor = Colors.red;
        });
      } else {
        setState(() {
          errorMessage = 'Invalid email/username.';
          passwordBorderColor = Colors.orange;
        });
      }

      setState(() {
        _failedAttempts += 1;
        if (_failedAttempts >= 3) {
          _showForgotPasswordDialog = true;
          _lastEnteredUsernameOrEmail = emailOrUsername;
        }
      });
    }
  } catch (e) {
    print('Error: $e');
    setState(() {
      errorMessage = 'An error occurred. Please try again.';
      passwordBorderColor = Colors.orange;
    });
  } finally {
    setState(() {
      showSpinner = false;
    });
  }
}


  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
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

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: showSpinner,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
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
                TextField(
                  keyboardType: TextInputType.text,
                  textAlign: TextAlign.center,
                  onChanged: (value) {
                    emailOrUsername = value;
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter your email or username',
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
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
                TextField(
                  obscureText: !_isPasswordVisible,
                  textAlign: TextAlign.center,
                  onChanged: (value) {
                    setState(() {
                      password = value;
                      _isPasswordEntered = password.isNotEmpty;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
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
                SizedBox(height: 24),
                MyButton(
                  title: 'Login',
                  onPressed: () async {
                    await _login();
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
        floatingActionButton: _showForgotPasswordDialog
            ? FloatingActionButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      TextEditingController emailController = TextEditingController();
                      return AlertDialog(
                        title: Text('Forgot Password?'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Enter your email address to receive a password reset link.'),
                            TextField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'Email Address',
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              final email = emailController.text.trim();
                              Navigator.pop(context);
                              _handleForgotPassword(email);
                            },
                            child: Text('Submit'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Icon(Icons.help),
                backgroundColor: Colors.blue,
              )
            : null,
      ),
    );
  }
}
