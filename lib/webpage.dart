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

  // Table data for features and ads
  List<List<String>> featureData = [
    ['Prayer Time', 'https://example.com/prayer-time'],
    ['Halal Pop Quiz', 'https://example.com/halal-pop-quiz'],
  ];
  List<List<String>> adData = [
    ['Mobile Ad', '5 Seconds', 'https://example.com/mobile'],
    ['TV Ad', '10 Seconds', 'https://example.com/tv'],
  ];

  // Last saved data for revert
  List<List<String>> lastSavedFeatureData = [];
  List<List<String>> lastSavedAdData = [];
  List<bool> lastSavedFeatureToggles = [];
  List<bool> lastSavedAdToggles = [];

  // Edit mode flags
  bool isEditingFeatures = false;
  bool isEditingAds = false;

  // Controllers for editing
  List<List<TextEditingController>> featureControllers = [];
  List<List<TextEditingController>> adControllers = [];

  @override
  void initState() {
    super.initState();
    _initControllers();
    _saveLastState();
  }

  void _initControllers() {
    featureControllers = featureData
        .map((row) => row.map((cell) => TextEditingController(text: cell)).toList())
        .toList();
    adControllers = adData
        .map((row) => row.map((cell) => TextEditingController(text: cell)).toList())
        .toList();
  }

  void _saveLastState() {
    lastSavedFeatureData = featureData.map((row) => List<String>.from(row)).toList();
    lastSavedAdData = adData.map((row) => List<String>.from(row)).toList();
    lastSavedFeatureToggles = List<bool>.from(featureToggles);
    lastSavedAdToggles = List<bool>.from(adToggles);
  }

  void _revertToLastState() {
    setState(() {
      featureData = lastSavedFeatureData.map((row) => List<String>.from(row)).toList();
      adData = lastSavedAdData.map((row) => List<String>.from(row)).toList();
      featureToggles = List<bool>.from(lastSavedFeatureToggles);
      adToggles = List<bool>.from(lastSavedAdToggles);
      isEditingFeatures = false;
      isEditingAds = false;
      _initControllers();
    });
  }

  void _onTabChange(int index) {
    if ((_selectedIndex == 0 && isEditingFeatures) || (_selectedIndex == 1 && isEditingAds)) {
      _revertToLastState();
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onEditFeatures() {
    setState(() {
      isEditingFeatures = true;
      _initControllers();
    });
  }

  void _onEditAds() {
    setState(() {
      isEditingAds = true;
      _initControllers();
    });
  }

  void _onSaveFeatures() {
    setState(() {
      for (int i = 0; i < featureData.length; i++) {
        for (int j = 0; j < featureData[i].length; j++) {
          featureData[i][j] = featureControllers[i][j].text;
        }
      }
      isEditingFeatures = false;
      _saveLastState();
    });
  }

  void _onSaveAds() {
    setState(() {
      for (int i = 0; i < adData.length; i++) {
        for (int j = 0; j < adData[i].length; j++) {
          adData[i][j] = adControllers[i][j].text;
        }
      }
      isEditingAds = false;
      _saveLastState();
    });
  }

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
            onDestinationSelected: _onTabChange,
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
                                  isEditingFeatures
                                      ? ElevatedButton(
                                          onPressed: _onSaveFeatures,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.accentBlue,
                                            foregroundColor: AppColors.accentGreen,
                                          ),
                                          child: const Text('Save'),
                                        )
                                      : ElevatedButton(
                                          onPressed: _onEditFeatures,
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
                              rows: List<DataRow>.generate(
                                featureData.length,
                                (i) => DataRow(cells: [
                                  DataCell(Text('${i + 1}')),
                                  DataCell(
                                    isEditingFeatures
                                        ? TextField(
                                            controller: featureControllers[i][0],
                                            decoration: const InputDecoration(border: OutlineInputBorder()),
                                          )
                                        : Text(featureData[i][0]),
                                  ),
                                  DataCell(
                                    isEditingFeatures
                                        ? TextField(
                                            controller: featureControllers[i][1],
                                            decoration: const InputDecoration(border: OutlineInputBorder()),
                                          )
                                        : Text(featureData[i][1]),
                                  ),
                                  DataCell(
                                    Switch(
                                      value: featureToggles[i],
                                      onChanged: isEditingFeatures
                                          ? (val) {
                                              setState(() {
                                                featureToggles[i] = val;
                                              });
                                              log('Feature ${i + 1} toggled:  ${val.toString()}');
                                            }
                                          : null,
                                      activeColor: AppColors.accentGreen,
                                      inactiveThumbColor: AppColors.accentBlue,
                                    ),
                                  ),
                                ]),
                              ),
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
                                  isEditingAds
                                      ? ElevatedButton(
                                          onPressed: _onSaveAds,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.accentBlue,
                                            foregroundColor: AppColors.accentGreen,
                                          ),
                                          child: const Text('Save'),
                                        )
                                      : ElevatedButton(
                                          onPressed: _onEditAds,
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
                                DataColumn(label: Text('Frequency')),
                                DataColumn(label: Text('Link')),
                                DataColumn(label: Text('Enable')),
                              ],
                              rows: List<DataRow>.generate(
                                adData.length,
                                (i) => DataRow(cells: [
                                  DataCell(Text('${i + 1}')),
                                  DataCell(
                                    isEditingAds
                                        ? TextField(
                                            controller: adControllers[i][0],
                                            decoration: const InputDecoration(border: OutlineInputBorder()),
                                          )
                                        : Text(adData[i][0]),
                                  ),
                                  DataCell(
                                    isEditingAds
                                        ? TextField(
                                            controller: adControllers[i][1],
                                            decoration: const InputDecoration(border: OutlineInputBorder()),
                                          )
                                        : Text(adData[i][1]),
                                  ),
                                  DataCell(
                                    isEditingAds
                                        ? TextField(
                                            controller: adControllers[i][2],
                                            decoration: const InputDecoration(border: OutlineInputBorder()),
                                          )
                                        : Text(adData[i][2]),
                                  ),
                                  DataCell(
                                    Switch(
                                      value: adToggles[i],
                                      onChanged: isEditingAds
                                          ? (val) {
                                              setState(() {
                                                adToggles[i] = val;
                                              });
                                              log('Ad ${i + 1} toggled: ${val.toString()}');
                                            }
                                          : null,
                                      activeColor: AppColors.accentGreen,
                                      inactiveThumbColor: AppColors.accentBlue,
                                    ),
                                  ),
                                ]),
                              ),
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
