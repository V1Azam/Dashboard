import 'package:flutter/material.dart';
import 'package:Dashboard/Theme/app_colors.dart';

void main() => runApp(MyApp());

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accentGreen,
        // You can further customize the color scheme here if needed
      ),
      scaffoldBackgroundColor: AppColors.mainBackground,
      cardColor: AppColors.cardBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.accentGreen,
        foregroundColor: AppColors.textLight,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.textDark),
        bodyMedium: TextStyle(color: AppColors.textDark),
      ),
      // Add more theme customizations as needed
    );
  }
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dummy Verify Halal',
      theme: AppTheme.lightTheme,
    );
  }
}