import 'package:flutter/material.dart';
import 'package:Dashboard/Theme/app_colors.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dummy Verify Halal',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 32, 206, 49)),
      ),
    );
  }
}