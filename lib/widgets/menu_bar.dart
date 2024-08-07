import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:talktime/screens/login_screen.dart';
import 'package:talktime/screens/profile_settings_screen.dart';

final _auth = FirebaseAuth.instance;
final _firestore = FirebaseFirestore.instance;

class MenuBare extends StatelessWidget {
  const MenuBare({super.key});

  Future<void> _deleteAccount(BuildContext context) async {
    // Controller for the password input
    TextEditingController passwordController = TextEditingController();
    String errorMessage = '';

    // Show a confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Delete Account'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('Do you really want to delete your account? This action cannot be undone.'),
                  SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      hintText: 'Enter your password to confirm',
                      errorText: errorMessage.isEmpty ? null : errorMessage,
                    ),
                    obscureText: true,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false); // User chose not to delete
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    String password = passwordController.text.trim();
                    if (password.isEmpty) {
                      setState(() {
                        errorMessage = 'Password cannot be empty';
                      });
                      return;
                    }

                    try {
                      final user = _auth.currentUser;
                      if (user != null) {
                        // Re-authenticate the user with the provided password
                        final credential = EmailAuthProvider.credential(
                          email: user.email!,
                          password: password,
                        );

                        await user.reauthenticateWithCredential(credential);

                        // Delete user data from Firestore
                        await _firestore.collection('users').doc(user.uid).delete();

                        // Delete user from Firebase Authentication
                        await user.delete();

                        // Sign out and navigate to login screen
                        await _auth.signOut();
                        Navigator.pushReplacementNamed(context, LoginScreen.screenRoute);
                      }
                    } catch (e) {
                      if (e is FirebaseAuthException && e.code == 'wrong-password') {
                        setState(() {
                          errorMessage = 'The entered password is incorrect.';
                        });
                      } else {
                        print('Error deleting account: $e');
                        setState(() {
                          errorMessage = 'Failed to delete account. Please try again.';
                        });
                      }
                    }
                  },
                  child: Text('Delete'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Do you really want to log out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout ?? false) {
      try {
        await _auth.signOut();
        Navigator.pushReplacementNamed(context, LoginScreen.screenRoute);
      } catch (e) {
        print('Error signing out: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                ListTile(
                  title: Text('Profile Settings'),
                  onTap: () {
                    Navigator.pushNamed(context, ProfileSettings.screenRoute);
                  },
                ),
                ListTile(
                  title: Text('Add Friends'),
                  onTap: () {
                    // Implement add friends navigation later
                  },
                ),
                ListTile(
                  title: Text('Blocked'),
                  onTap: () {
                    // Implement blocked navigation later
                  },
                ),
                ListTile(
                  title: Text('Safety and Security'),
                  onTap: () {
                    // Implement safety and security navigation later
                  },
                ),
                // Add the Delete Account option
                ListTile(
                  title: Text('Delete Account'),
                  onTap: () => _deleteAccount(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text('Logout'),
              onTap: () => _logout(context),
            ),
          ),
        ],
      ),
    );
  }
}
