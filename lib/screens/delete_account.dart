// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:talktime/screens/login_screen.dart';

// class DeleteAccountScreen extends StatefulWidget {
//   const DeleteAccountScreen({super.key});
//   static const String screenRoute = 'delete_account';

//   @override
//   _DeleteAccountScreenState createState() => _DeleteAccountScreenState();
// }

// class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
//   final _auth = FirebaseAuth.instance;
//   final _firestore = FirebaseFirestore.instance;
//   final _passwordController = TextEditingController();
//   String _errorMessage = '';

//   Future<void> _deleteAccount() async {
//     String password = _passwordController.text.trim();
//     if (password.isEmpty) {
//       setState(() {
//         _errorMessage = 'Password cannot be empty';
//       });
//       return;
//     }

//     try {
//       final user = _auth.currentUser;
//       if (user != null) {
//         // Re-authenticate the user with the provided password
//         final credential = EmailAuthProvider.credential(
//           email: user.email!,
//           password: password,
//         );

//         await user.reauthenticateWithCredential(credential);

//         // Delete user data from Firestore
//         await _firestore.collection('current_users').doc(user.uid).delete();

//         // Delete user from Firebase Authentication
//         await user.delete();

//         // Sign out and navigate to login screen
//         await _auth.signOut();
//         Navigator.pushReplacementNamed(context, LoginScreen.screenRoute);
//       }
//     } catch (e) {
//       if (e is FirebaseAuthException && e.code == 'wrong-password') {
//         setState(() {
//           _errorMessage = 'The entered password is incorrect.';
//         });
//       } else {
//         print('Error deleting account: $e');
//         setState(() {
//           _errorMessage = 'Failed to delete account. Please try again.';
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Delete Account'),
//         backgroundColor: Colors.redAccent,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: <Widget>[
//             Text('Do you really want to delete your account?'),
//             SizedBox(height: 16),
//             TextField(
//               controller: _passwordController,
//               decoration: InputDecoration(
//                 hintText: 'Enter your password to confirm',
//                 errorText: _errorMessage.isEmpty ? null : _errorMessage,
//               ),
//               obscureText: true,
//             ),
//             SizedBox(height: 24),
//             Center(
//               child: ElevatedButton(
//                 onPressed: _deleteAccount,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.redAccent,
//                 ),
//                 child: Text('Delete Account'),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
