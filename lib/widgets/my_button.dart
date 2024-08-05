// ignore_for_file: prefer_const_constructors, prefer_const_constructors_in_immutables, use_key_in_widget_constructors

import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  MyButton({ required this.title, required this.onPressed, required this.color});

  final String title;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Material(
        elevation: 5,
        color: color,
        borderRadius: BorderRadius.circular(15),
        child: MaterialButton(
          onPressed:  onPressed,
          minWidth: 200,
          height: 42,
          child:Text(title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            ),
          
          ),
        ),
      ),
    );
  }
}