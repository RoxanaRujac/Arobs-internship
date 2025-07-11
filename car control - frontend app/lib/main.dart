import 'package:flutter/material.dart';
import 'screens/car_control_screen.dart';

void main() {
  runApp(const CarControlApp());
}

class CarControlApp extends StatelessWidget {
  const CarControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Car Control',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Roboto',
      ),
      home: const CarControlScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}