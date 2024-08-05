// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:talktime/screens/chat_screen.dart';
import 'package:talktime/screens/login_screen.dart';
import 'package:talktime/screens/registration_screen.dart';
import 'package:talktime/screens/welcome_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TalkTime',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      //home: SigninScreen(),

      initialRoute: _auth.currentUser != null? ChatScreen.screenRoute: WelcomeScreen.screenRoute,

      routes: {
        WelcomeScreen.screenRoute: (context) => WelcomeScreen(),
        LoginScreen.screenRoute: (context) => LoginScreen(),
        RegistrationScreen.screenRoute: (context) => RegistrationScreen(),
        ChatScreen.screenRoute:(context) => ChatScreen(),
      },);
  }
}

