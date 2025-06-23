import 'package:flutter/material.dart';
import 'package:dashboard/Theme/app_colors.dart';
import 'dart:developer';
import 'package:pocketbase/pocketbase.dart';
import 'dart:async';
import 'package:flutter/services.dart';

final pb = PocketBase('http://127.0.0.1:8090');

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
  const MyApp({super.key});

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
  const NavigationRailExample({super.key});

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

  bool isAddingFeature = false;
  List<TextEditingController> newFeatureControllers = [];

  bool isAddingAd = false;
  List<TextEditingController> newAdControllers = [];

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
        .map((row) => [
              TextEditingController(text: row[0]),
              TextEditingController(text: row[1].replaceAll(RegExp(r'\s*Seconds$', caseSensitive: false), '')),
              TextEditingController(text: row[2]),
            ])
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

  Future<void> _syncFeaturesToPocketBase() async {
    // Delete all existing features
    final records = await pb.collection('features').getFullList();
    for (final r in records) {
      await pb.collection('features').delete(r.id);
    }
    // Add current UI rows
    for (int i = 0; i < featureData.length; i++) {
      await pb.collection('features').create(body: {
        'featureName': featureData[i][0],
        'link': featureData[i][1],
        'isEnabled': featureToggles[i],
      });
    }
  }

  Future<void> _syncAdsToPocketBase() async {
    // Delete all existing ads
    final records = await pb.collection('ads').getFullList();
    for (final r in records) {
      await pb.collection('ads').delete(r.id);
    }
    // Add current UI rows
    for (int i = 0; i < adData.length; i++) {
      await pb.collection('ads').create(body: {
        'adName': adData[i][0],
        'freq': adData[i][1],
        'link': adData[i][2],
        'isEnabled': adToggles[i],
      });
    }
  }

  void _onSaveFeatures() async {
    final nameRegExp = RegExp(r'^[a-zA-Z0-9 _-]+$');
    final urlRegExp = RegExp(r'^(https?:\/\/)[\w\-]+(\.[\w\-]+)+([\/\w\-\.\?\=\&\#]*)?$');
    for (int i = 0; i < featureData.length; i++) {
      final name = featureControllers[i][0].text.trim();
      final url = featureControllers[i][1].text.trim();
      String? error;
      if (name.isEmpty) {
        error = 'Feature name cannot be empty (row ${i + 1}).';
      } else if (name.length > 18) {
        error = 'Feature name must be 18 characters or less (row ${i + 1}).';
      } else if (!nameRegExp.hasMatch(name)) {
        error = 'Feature name contains invalid characters (row ${i + 1}).';
      } else if (url.isEmpty) {
        error = 'URL cannot be empty (row ${i + 1}).';
      } else if (!urlRegExp.hasMatch(url)) {
        error = 'Please enter a valid URL (row ${i + 1}).';
      }
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
        return;
      }
    }
    setState(() {
      for (int i = 0; i < featureData.length; i++) {
        for (int j = 0; j < featureData[i].length; j++) {
          featureData[i][j] = featureControllers[i][j].text;
        }
      }
      isEditingFeatures = false;
      _saveLastState();
    });
    await _syncFeaturesToPocketBase();
  }

  void _onSaveAds() async {
    final nameRegExp = RegExp(r'^[a-zA-Z0-9 _-]+$');
    final urlRegExp = RegExp(r'^(https?:\/\/)[\w\-]+(\.[\w\-]+)+([\/\w\-\.\?\=\&\#]*)?$');
    for (int i = 0; i < adData.length; i++) {
      final name = adControllers[i][0].text.trim();
      final freqRaw = adControllers[i][1].text.trim();
      final url = adControllers[i][2].text.trim();
      String? error;
      if (name.isEmpty) {
        error = 'Ad name cannot be empty (row ${i + 1}).';
      } else if (name.length > 18) {
        error = 'Ad name must be 18 characters or less (row ${i + 1}).';
      } else if (!nameRegExp.hasMatch(name)) {
        error = 'Ad name contains invalid characters (row ${i + 1}).';
      } else if (freqRaw.isEmpty) {
        error = 'Frequency cannot be empty (row ${i + 1}).';
      } else if (int.tryParse(freqRaw) == null || int.parse(freqRaw) < 1 || int.parse(freqRaw) > 15) {
        error = 'Frequency must be an integer between 1 and 15 (row ${i + 1}).';
      } else if (url.isEmpty) {
        error = 'URL cannot be empty (row ${i + 1}).';
      } else if (!urlRegExp.hasMatch(url)) {
        error = 'Please enter a valid URL (row ${i + 1}).';
      }
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
        return;
      }
    }
    setState(() {
      for (int i = 0; i < adData.length; i++) {
        adData[i][0] = adControllers[i][0].text;
        adData[i][1] = '${adControllers[i][1].text} Seconds';
        adData[i][2] = adControllers[i][2].text;
      }
      isEditingAds = false;
      _saveLastState();
    });
    await _syncAdsToPocketBase();
  }

  void _onAddFeaturePressed() {
    setState(() {
      isAddingFeature = true;
      newFeatureControllers = [
        TextEditingController(), // Feature Name
        TextEditingController(), // Link
      ];
    });
  }

  void _onDoneAddFeature() async {
    final name = newFeatureControllers[0].text.trim();
    final url = newFeatureControllers[1].text.trim();
    final nameRegExp = RegExp(r'^[a-zA-Z0-9 _-]+$');
    final urlRegExp = RegExp(r'^(https?:\/\/)[\w\-]+(\.[\w\-]+)+([\/\w\-\.\?\=\&\#]*)?$');
    String? error;
    if (name.isEmpty) {
      error = 'Feature name cannot be empty.';
    } else if (name.length > 18) {
      error = 'Feature name must be 18 characters or less.';
    } else if (!nameRegExp.hasMatch(name)) {
      error = 'Feature name contains invalid characters.';
    } else if (url.isEmpty) {
      error = 'URL cannot be empty.';
    } else if (!urlRegExp.hasMatch(url)) {
      error = 'Please enter a valid URL.';
    }
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() {
      featureData.add([
        name,
        url,
      ]);
      featureToggles.add(false); // default to disabled
      isAddingFeature = false;
      newFeatureControllers = [];
      _initControllers();
      _saveLastState();
    });
    await _syncFeaturesToPocketBase();
  }

  void _onCancelAddFeature() {
    setState(() {
      isAddingFeature = false;
      newFeatureControllers = [];
    });
  }

  void _onAddAdPressed() {
    setState(() {
      isAddingAd = true;
      newAdControllers = [
        TextEditingController(), // Ad Name
        TextEditingController(), // Frequency
        TextEditingController(), // Link
      ];
    });
  }

  void _onDoneAddAd() async {
    final name = newAdControllers[0].text.trim();
    final freq = newAdControllers[1].text.trim();
    final url = newAdControllers[2].text.trim();
    final nameRegExp = RegExp(r'^[a-zA-Z0-9 _-]+$');
    final urlRegExp = RegExp(r'^(https?:\/\/)[\w\-]+(\.[\w\-]+)+([\/\w\-\.\?\=\&\#]*)?$');
    String? error;
    if (name.isEmpty) {
      error = 'Ad name cannot be empty.';
    } else if (name.length > 18) {
      error = 'Ad name must be 18 characters or less.';
    } else if (!nameRegExp.hasMatch(name)) {
      error = 'Ad name contains invalid characters.';
    } else if (freq.isEmpty) {
      error = 'Frequency cannot be empty.';
    } else if (int.tryParse(freq) == null || int.parse(freq) < 1 || int.parse(freq) > 15) {
      error = 'Frequency must be an integer between 1 and 15.';
    } else if (url.isEmpty) {
      error = 'URL cannot be empty.';
    } else if (!urlRegExp.hasMatch(url)) {
      error = 'Please enter a valid URL.';
    }
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }
    final freqWithSeconds = '$freq Seconds';
    setState(() {
      adData.add([
        name,
        freqWithSeconds,
        url,
      ]);
      adToggles.add(false); // default to disabled
      isAddingAd = false;
      newAdControllers = [];
      _initControllers();
      _saveLastState();
    });
    await _syncAdsToPocketBase();
  }

  void _onCancelAddAd() {
    setState(() {
      isAddingAd = false;
      newAdControllers = [];
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
                                  if (!isAddingFeature) ...[
                                    IconButton(
                                      icon: const Icon(Icons.add, color: AppColors.accentBlue),
                                      tooltip: 'Add Feature',
                                      onPressed: _onAddFeaturePressed,
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
                                  ] else ...[
                                    ElevatedButton(
                                      onPressed: _onDoneAddFeature,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.accentGreen,
                                        foregroundColor: AppColors.accentBlue,
                                      ),
                                      child: const Text('Done'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: _onCancelAddFeature,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.accentBlue,
                                        foregroundColor: AppColors.accentGreen,
                                      ),
                                      child: const Text('Cancel'),
                                    ),
                                  ]
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
                                ...List<DataRow>.generate(
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
                                                log('Feature \\${i + 1} toggled:  \\${val.toString()}');
                                              }
                                            : null,
                                        activeColor: AppColors.accentGreen,
                                        inactiveThumbColor: AppColors.accentBlue,
                                      ),
                                    ),
                                  ]),
                                ),
                                if (isAddingFeature)
                                  DataRow(cells: [
                                    DataCell(Text('${featureData.length + 1}')),
                                    DataCell(
                                      SizedBox(
                                        width: 160,
                                        child: TextField(
                                          controller: newFeatureControllers[0],
                                          maxLength: 18,
                                          maxLines: 1,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 _\-]')),
                                            LengthLimitingTextInputFormatter(18),
                                          ],
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            counterText: '',
                                          ),
                                          scrollPhysics: AlwaysScrollableScrollPhysics(),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 220,
                                        child: TextField(
                                          controller: newFeatureControllers[1],
                                          maxLines: 1,
                                          keyboardType: TextInputType.url,
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                          ),
                                          scrollPhysics: AlwaysScrollableScrollPhysics(),
                                        ),
                                      ),
                                    ),
                                    const DataCell(SizedBox()), // No enable switch for new row
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
                                  if (!isAddingAd) ...[
                                    IconButton(
                                      icon: const Icon(Icons.add, color: AppColors.accentBlue),
                                      tooltip: 'Add Ad',
                                      onPressed: _onAddAdPressed,
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
                                  ] else ...[
                                    ElevatedButton(
                                      onPressed: _onDoneAddAd,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.accentGreen,
                                        foregroundColor: AppColors.accentBlue,
                                      ),
                                      child: const Text('Done'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: _onCancelAddAd,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.accentBlue,
                                        foregroundColor: AppColors.accentGreen,
                                      ),
                                      child: const Text('Cancel'),
                                    ),
                                  ]
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: Builder(
                              builder: (context) {
                                final List<DataRow> adRows = List<DataRow>.generate(
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
                                          ? Row(
                                              children: [
                                                SizedBox(
                                                  width: 50,
                                                  child: TextField(
                                                    controller: adControllers[i][1],
                                                    maxLines: 1,
                                                    keyboardType: TextInputType.number,
                                                    inputFormatters: [
                                                      FilteringTextInputFormatter.digitsOnly,
                                                      LengthLimitingTextInputFormatter(2),
                                                    ],
                                                    decoration: const InputDecoration(
                                                      border: OutlineInputBorder(),
                                                    ),
                                                    scrollPhysics: AlwaysScrollableScrollPhysics(),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                const Text('Seconds'),
                                              ],
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
                                                log('Ad \\${i + 1} toggled: \\${val.toString()}');
                                              }
                                            : null,
                                        activeColor: AppColors.accentGreen,
                                        inactiveThumbColor: AppColors.accentBlue,
                                      ),
                                    ),
                                  ]),
                                );
                                if (isAddingAd) {
                                  adRows.add(
                                    DataRow(cells: [
                                      DataCell(Text('${adData.length + 1}')),
                                      DataCell(
                                        SizedBox(
                                          width: 160,
                                          child: TextField(
                                            controller: newAdControllers[0],
                                            maxLength: 18,
                                            maxLines: 1,
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 _\-]')),
                                              LengthLimitingTextInputFormatter(18),
                                            ],
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                              counterText: '',
                                            ),
                                            scrollPhysics: AlwaysScrollableScrollPhysics(),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 80,
                                          child: TextField(
                                            controller: newAdControllers[1],
                                            maxLines: 1,
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter.digitsOnly,
                                              LengthLimitingTextInputFormatter(2),
                                            ],
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                            ),
                                            scrollPhysics: AlwaysScrollableScrollPhysics(),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 220,
                                          child: TextField(
                                            controller: newAdControllers[2],
                                            maxLines: 1,
                                            keyboardType: TextInputType.url,
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                            ),
                                            scrollPhysics: AlwaysScrollableScrollPhysics(),
                                          ),
                                        ),
                                      ),
                                      const DataCell(SizedBox()), // No enable switch for new row
                                    ]),
                                  );
                                }
                                return DataTable(
                                  columns: const [
                                    DataColumn(label: Text('S/N')),
                                    DataColumn(label: Text('Ad Name')),
                                    DataColumn(label: Text('Frequency')),
                                    DataColumn(label: Text('Link')),
                                    DataColumn(label: Text('Enable')),
                                  ],
                                  rows: adRows,
                                );
                              },
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
