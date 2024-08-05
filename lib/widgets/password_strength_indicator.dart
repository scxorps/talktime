import 'package:flutter/material.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({required this.password});

  @override
  Widget build(BuildContext context) {
    final strength = _calculateStrength(password);
    final color = _getColorForStrength(strength);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lock, color: color),
        SizedBox(width: 8),
        Text(
          strength,
          style: TextStyle(color: color),
        ),
      ],
    );
  }

  String _calculateStrength(String password) {
    if (password.length < 6) return 'Weak';
    if (password.length < 10) return 'Moderate';
    return 'Strong';
  }

  Color _getColorForStrength(String strength) {
    switch (strength) {
      case 'Weak':
        return Colors.red;
      case 'Moderate':
        return Colors.orange;
      case 'Strong':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
