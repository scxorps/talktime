// ignore_for_file: avoid_unnecessary_containers, prefer_const_constructors, sized_box_for_whitespace, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:talktime/screens/login_screen.dart';
import 'package:talktime/screens/registration_screen.dart';
import 'package:talktime/widgets/my_button.dart';

class WelcomeScreen extends StatefulWidget {
  static const screenRoute = ' welcome_screen ';
  
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
    body:Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          children :[
            Container(
              height: 180,
              child: Image.asset('assets/images/logo.png'),
            ),
              Text('TalkTime',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 69, 1, 133),
                ),
              ),
            ]
          ),
          SizedBox(height: 30,),
          MyButton(
            color: Color(0xFF3CB371),
            title: 'Log In',
            onPressed: (){
              Navigator.pushNamed(context, LoginScreen.screenRoute);
            },
          ),
          MyButton(
            color: Color(0xFF4682B4),
            title: 'Sign Up',
            onPressed: (){
              Navigator.pushNamed(context, RegistrationScreen.screenRoute);
            },
          ),
        ]
      ),
    )
    );
  }
}


