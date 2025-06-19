import 'package:flutter/material.dart';
import 'package:Dashboard/Theme/app_colors.dart';

void main() => runApp(MyApp());

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accentGreen,
      ),
      scaffoldBackgroundColor: AppColors.mainBackground,
      cardColor: AppColors.cardBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.accentGreen,
        foregroundColor: AppColors.textLight,
        titleTextStyle: AppColors.boldTitle.copyWith(color: AppColors.textLight),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.textDark),
        bodyMedium: TextStyle(color: AppColors.textDark),
        titleLarge: AppColors.boldTitle,
        titleMedium: AppColors.boldTitle,
        titleSmall: AppColors.boldTitle,
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Super Admin Dashboard',
      theme: AppTheme.lightTheme,
      home: NavigationRailExample(),
    );
  }
}

class NavigationRailExample extends StatefulWidget {
  @override
  State<NavigationRailExample> createState() => _NavigationRailExampleState();
}

class _NavigationRailExampleState extends State<NavigationRailExample> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'web/icons/Icon-512.jpg',
              height: 32,
            ),
            const SizedBox(width: 12),
            const Text('Super Admin Dashboard'),
          ],
        ),
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            backgroundColor: AppColors.accentBlue,
            labelType: NavigationRailLabelType.all,
            selectedLabelTextStyle: AppColors.boldTitle.copyWith(color: Colors.white),
            unselectedLabelTextStyle: AppColors.unselectedLabel,
            selectedIconTheme: const IconThemeData(color: AppColors.accentBlue),
            unselectedIconTheme: const IconThemeData(color: Colors.white),
            indicatorColor: AppColors.accentGreen,
            destinations: [
              NavigationRailDestination(
                icon: const Icon(Icons.featured_play_list),
                selectedIcon: const Icon(Icons.featured_play_list),
                label: Text('Features', style: AppColors.railLabel),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.campaign),
                selectedIcon: const Icon(Icons.campaign),
                label: Text('Ads', style: AppColors.railLabel),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main content area
          Expanded(
            child: Center(
              child: _selectedIndex == 0
                  ? Text('Welcome to the Features page!', style: AppColors.bodyText)
                  : Text('Welcome to the Ads page!', style: AppColors.bodyText),
            ),
          ),
        ],
      ),
    );
  }
}
