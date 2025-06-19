import 'package:flutter/material.dart';
import 'package:dashboard/Theme/app_colors.dart';
import 'dart:developer';

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

  // Toggle states for features and ads
  List<bool> featureToggles = [true, false];
  List<bool> adToggles = [true, false];

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
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Feature Activity', style: AppColors.boldTitle.copyWith(fontSize: 24)),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.add, color: AppColors.accentBlue),
                                    tooltip: 'Add Feature',
                                    onPressed: () {
                                      log('Add Feature pressed');
                                    },
                                    color: AppColors.accentGreen,
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStateProperty.all(AppColors.accentGreen),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      log('Edit Feature pressed');
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accentGreen,
                                      foregroundColor: AppColors.accentBlue,
                                    ),
                                    child: const Text('Edit'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('S/N')),
                                DataColumn(label: Text('Feature Name')),
                                DataColumn(label: Text('Link')),
                                DataColumn(label: Text('Enable')),
                              ],
                              rows: [
                                DataRow(cells: [
                                  const DataCell(Text('1')),
                                  const DataCell(Text('Login')),
                                  const DataCell(Text('https://example.com/login')),
                                  DataCell(Switch(
                                    value: featureToggles[0],
                                    onChanged: (val) {
                                      setState(() {
                                        featureToggles[0] = val;
                                      });
                                      log('Feature 1 toggled:  ${val.toString()}');
                                    },
                                    activeColor: AppColors.accentGreen,
                                    inactiveThumbColor: AppColors.accentBlue,
                                  )),
                                ]),
                                DataRow(cells: [
                                  const DataCell(Text('2')),
                                  const DataCell(Text('Dashboard')),
                                  const DataCell(Text('https://example.com/dashboard')),
                                  DataCell(Switch(
                                    value: featureToggles[1],
                                    onChanged: (val) {
                                      setState(() {
                                        featureToggles[1] = val;
                                      });
                                      log('Feature 2 toggled:  ${val.toString()}');
                                    },
                                    activeColor: AppColors.accentGreen,
                                    inactiveThumbColor: AppColors.accentBlue,
                                  )),
                                ]),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Ad Activity', style: AppColors.boldTitle.copyWith(fontSize: 24)),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.add, color: AppColors.accentBlue),
                                    tooltip: 'Add Ad',
                                    onPressed: () {
                                      log('Add Ad pressed');
                                    },
                                    color: AppColors.accentGreen,
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStateProperty.all(AppColors.accentGreen),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      log('Edit Ad pressed');
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accentGreen,
                                      foregroundColor: AppColors.accentBlue,
                                    ),
                                    child: const Text('Edit'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('S/N')),
                                DataColumn(label: Text('Ad Name')),
                                DataColumn(label: Text('Link')),
                                DataColumn(label: Text('Enable')),
                              ],
                              rows: [
                                DataRow(cells: [
                                  const DataCell(Text('1')),
                                  const DataCell(Text('Banner Ad')),
                                  const DataCell(Text('https://example.com/banner')),
                                  DataCell(Switch(
                                    value: adToggles[0],
                                    onChanged: (val) {
                                      setState(() {
                                        adToggles[0] = val;
                                      });
                                      log('Ad 1 toggled: ${val.toString()}');
                                    },
                                    activeColor: AppColors.accentGreen,
                                    inactiveThumbColor: AppColors.accentBlue,
                                  )),
                                ]),
                                DataRow(cells: [
                                  const DataCell(Text('2')),
                                  const DataCell(Text('Sidebar Ad')),
                                  const DataCell(Text('https://example.com/sidebar')),
                                  DataCell(Switch(
                                    value: adToggles[1],
                                    onChanged: (val) {
                                      setState(() {
                                        adToggles[1] = val;
                                      });
                                      log('Ad 2 toggled: ${val.toString()}');
                                    },
                                    activeColor: AppColors.accentGreen,
                                    inactiveThumbColor: AppColors.accentBlue,
                                  )),
                                ]),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
