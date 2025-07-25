import 'package:flutter/material.dart';

class AppTheme {
  static const Color backgroundColor = Color(0xFF93E5B2);
  static const Color primaryGreen = Color(0xFF7BC794);
  static const Color darkGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFB8E6C1);
  static const Color greyContainer = Color(0xFFBDBDBD);
  static const Color lightGrey = Color(0xFFE0E0E0);

  static BorderRadius defaultBorderRadius = BorderRadius.circular(8.0);
  static BorderRadius containerBorderRadius = BorderRadius.circular(12.0);

  static const TextStyle titleStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  static const TextStyle labelStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );

  static const TextStyle statLabelStyle = TextStyle(
    fontSize: 16,
    color: Colors.black87,
  );

  static const TextStyle statValueStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );
}
