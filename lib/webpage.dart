import 'package:flutter/material.dart';
import 'package:dashboard/Theme/app_colors.dart';
import 'package:pocketbase/pocketbase.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

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
  List<List<String>> featureData = [];
  List<List<String>> adData = [
    ['Promotion Ads', 'Banner', 'ca-app-pub-1234567890123456/1234567890', 'Banner'],
    ['Game Ads', 'Interstitial', 'ca-app-pub-1234567890123456/0987654321', 'Video'],
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

  // Add this constant for dropdown options
  static const List<Map<String, String>> sectionOptions = [
    {'label': 'Extra Features', 'value': 'extraFeatures'},
    {'label': 'Stay Connected', 'value': 'stayConnected'},
  ];

  // Add these state variables:
  bool newFeatureEnabled = false;
  bool newAdEnabled = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _saveLastState();
  }

  void _initControllers() {
    featureControllers = featureData
        .map((row) => [
              TextEditingController(text: row[0]), // Feature Name
              TextEditingController(text: row[1]), // Image URL
              TextEditingController(text: row[2]), // Link
              TextEditingController(text: row.length > 3 ? row[3] : sectionOptions[0]['value']!), // Section
            ])
        .toList();
    adControllers = adData
        .map((row) => [
              TextEditingController(text: row[0]), // Ad Name
              TextEditingController(text: row[1]), // Ad Placement
              TextEditingController(text: row[2]), // Ad ID
              TextEditingController(text: row[3]), // Ad Type
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
      // Ensure section is always the value, not the label
      String sectionValue = (featureData[i].length > 3 ? featureData[i][3] : sectionOptions[0]['value']) ?? sectionOptions[0]['value']!;
      // If it's a label, convert to value
      final found = sectionOptions.firstWhere(
        (opt) => opt['value'] == sectionValue || opt['label'] == sectionValue,
        orElse: () => sectionOptions[0],
      );
      sectionValue = found['value'] ?? sectionOptions[0]['value']!;
      await pb.collection('features').create(body: {
        'featureName': featureData[i][0],
        'image': featureData[i][1],
        'link': featureData[i][2],
        'section': sectionValue,
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
        'adPlacement': adData[i][1],
        'adID': adData[i][2],
        'adType': adData[i][3],
        'isEnabled': adToggles[i],
      });
    }
  }

  bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _onSaveFeatures() async {
    final nameRegExp = RegExp(r'^[a-zA-Z0-9 _-]+$');
    for (int i = 0; i < featureData.length; i++) {
      final name = featureControllers[i][0].text.trim();
      final imageUrl = featureControllers[i][1].text.trim();
      final url = featureControllers[i][2].text.trim();
      String? error;
      if (name.isEmpty) {
        error = 'Feature name cannot be empty (row ${i + 1}).';
      } else if (name.length > 18) {
        error = 'Feature name must be 18 characters or less (row ${i + 1}).';
      } else if (!nameRegExp.hasMatch(name)) {
        error = 'Feature name contains invalid characters (row ${i + 1}).';
      } else if (url.isEmpty) {
        error = 'URL cannot be empty (row ${i + 1}).';
      } else if (!isValidUrl(url)) {
        error = 'Please enter a valid URL (row ${i + 1}).';
      } else if (imageUrl.isNotEmpty && !isValidUrl(imageUrl)) {
        error = 'Please enter a valid Image URL (row ${i + 1}).';
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
        featureData[i][0] = featureControllers[i][0].text;
        featureData[i][1] = featureControllers[i][1].text;
        featureData[i][2] = featureControllers[i][2].text;
        featureData[i][3] = featureControllers[i][3].text;
      }
      isEditingFeatures = false;
      _saveLastState();
    });
    await _syncFeaturesToPocketBase();
  }

  void _onSaveAds() async {
    final nameRegExp = RegExp(r'^[a-zA-Z0-9 _-]+$');
    final adIDRegExp = RegExp(r'^ca-app-pub-\d{16}/\d{10}$');
    for (int i = 0; i < adData.length; i++) {
      final name = adControllers[i][0].text.trim();
      final adID = adControllers[i][2].text.trim();
      String? error;
      if (name.isEmpty) {
        error = 'Ad name cannot be empty (row ${i + 1}).';
      } else if (name.length > 18) {
        error = 'Ad name must be 18 characters or less (row ${i + 1}).';
      } else if (!nameRegExp.hasMatch(name)) {
        error = 'Ad name contains invalid characters (row ${i + 1}).';
      } else if (adID.isEmpty) {
        error = 'Ad ID cannot be empty (row ${i + 1}).';
      } else if (!adIDRegExp.hasMatch(adID)) {
        error = 'Ad ID must be in AdMob format: ca-app-pub-1234567890123456/1234567890 (row ${i + 1}).';
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
        TextEditingController(), // Image URL
        TextEditingController(), // Link
        TextEditingController(text: sectionOptions[0]['value']!), // Section (default)
      ];
      newFeatureEnabled = false;
    });
  }

  void _onDoneAddFeature() async {
    final name = newFeatureControllers[0].text.trim();
    final imageUrl = newFeatureControllers[1].text.trim();
    final url = newFeatureControllers[2].text.trim();
    final section = newFeatureControllers[3].text.trim();
    final nameRegExp = RegExp(r'^[a-zA-Z0-9 _-]+$');
    String? error;
    if (name.isEmpty) {
      error = 'Feature name cannot be empty.';
    } else if (name.length > 18) {
      error = 'Feature name must be 18 characters or less.';
    } else if (!nameRegExp.hasMatch(name)) {
      error = 'Feature name contains invalid characters.';
    } else if (url.isEmpty) {
      error = 'URL cannot be empty.';
    } else if (!isValidUrl(url)) {
      error = 'Please enter a valid URL.';
    } else if (imageUrl.isNotEmpty && !isValidUrl(imageUrl)) {
      error = 'Please enter a valid Image URL.';
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
        imageUrl,
        url,
        section,
      ]);
      featureToggles.add(newFeatureEnabled); // use toggle value
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
      newFeatureEnabled = false;
    });
  }

  Future<bool> showDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Row'),
        content: const Text('Are you sure you want to delete this row? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
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
                                  if (!isAddingFeature && !isEditingFeatures) ...[
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
                                  ],
                                  if (!isAddingFeature)
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
                                  if (isAddingFeature) ...[
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
                          child: LayoutBuilder(
                            builder: (context, constraints) => SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                  child: DataTable(
                                    columns: [
                                      DataColumn(label: SizedBox(width: 32, child: Text('S/N'))),
                                      DataColumn(label: Text('Feature Name')),
                                      DataColumn(label: Text('Image')),
                                      DataColumn(label: Text('Link')),
                                      DataColumn(label: Text('Section')),
                                      DataColumn(label: Text('Enable')),
                                      if (isEditingFeatures)
                                        DataColumn(label: SizedBox(width: 36)),
                                    ],
                                    rows: [
                                      ...List<DataRow>.generate(
                                        featureData.length,
                                        (i) => DataRow(cells: [
                                          DataCell(SizedBox(width: 32, child: Text('${i + 1}'))),
                                          DataCell(
                                            isEditingFeatures
                                                ? SizedBox(
                                                    width: 160,
                                                    child: TextField(
                                                      controller: featureControllers[i][0],
                                                      decoration: const InputDecoration(
                                                        border: OutlineInputBorder(),
                                                        counterText: '',
                                                      ),
                                                      maxLength: 18,
                                                      maxLines: 1,
                                                      scrollPhysics: AlwaysScrollableScrollPhysics(),
                                                      keyboardType: TextInputType.text,
                                                      textInputAction: TextInputAction.next,
                                                      expands: false,
                                                      scrollPadding: EdgeInsets.all(8),
                                                      style: TextStyle(overflow: TextOverflow.ellipsis),
                                                    ),
                                                  )
                                                : Text(featureData[i][0]),
                                          ),
                                          DataCell(
                                            isEditingFeatures
                                                ? SizedBox(
                                                    width: 220,
                                                    child: TextField(
                                                      controller: featureControllers[i][1],
                                                      decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Image URL (optional)'),
                                                      maxLines: 1,
                                                      scrollPhysics: AlwaysScrollableScrollPhysics(),
                                                      keyboardType: TextInputType.url,
                                                      textInputAction: TextInputAction.next,
                                                      expands: false,
                                                      scrollPadding: EdgeInsets.all(8),
                                                      style: TextStyle(overflow: TextOverflow.ellipsis),
                                                    ),
                                                  )
                                                : GestureDetector(
                                                    onTap: featureData[i][1].isNotEmpty && isValidUrl(featureData[i][1])
                                                        ? () async {
                                                            final url = featureData[i][1];
                                                            final uri = Uri.parse(url);
                                                            if (await canLaunchUrl(uri)) {
                                                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                                                            } else {
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                SnackBar(content: Text('Could not open the image URL.'), backgroundColor: Colors.red),
                                                              );
                                                            }
                                                          }
                                                        : null,
                                                    child: Container(
                                                      width: 48,
                                                      height: 48,
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius: BorderRadius.circular(8),
                                                        border: Border.all(color: Colors.grey),
                                                      ),
                                                      alignment: Alignment.center,
                                                      child: featureData[i][1].isNotEmpty && isValidUrl(featureData[i][1])
                                                          ? ClipRRect(
                                                              borderRadius: BorderRadius.circular(6),
                                                              child: Image.network(
                                                                featureData[i][1],
                                                                fit: BoxFit.cover,
                                                                width: 44,
                                                                height: 44,
                                                                loadingBuilder: (context, child, loadingProgress) {
                                                                  if (loadingProgress == null) return child;
                                                                  return const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)));
                                                                },
                                                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey, size: 32),
                                                              ),
                                                            )
                                                          : const Icon(Icons.broken_image, color: Colors.grey, size: 32),
                                                    ),
                                                  ),
                                          ),
                                          DataCell(
                                            isEditingFeatures
                                                ? SizedBox(
                                                    width: 220,
                                                    child: TextField(
                                                      controller: featureControllers[i][2],
                                                      decoration: const InputDecoration(border: OutlineInputBorder()),
                                                      maxLines: 1,
                                                      scrollPhysics: AlwaysScrollableScrollPhysics(),
                                                      keyboardType: TextInputType.url,
                                                      textInputAction: TextInputAction.next,
                                                      expands: false,
                                                      scrollPadding: EdgeInsets.all(8),
                                                      style: TextStyle(overflow: TextOverflow.ellipsis),
                                                    ),
                                                  )
                                                : GestureDetector(
                                                    onTap: () async {
                                                      final url = featureData[i][2];
                                                      if (url.isNotEmpty && isValidUrl(url)) {
                                                        final uri = Uri.parse(url);
                                                        if (await canLaunchUrl(uri)) {
                                                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                                                        } else {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(content: Text('Could not open the link.'), backgroundColor: Colors.red),
                                                          );
                                                        }
                                                      }
                                                    },
                                                    child: Text(
                                                      featureData[i][2].length > 30
                                                          ? featureData[i][2].substring(0, 30) + '...'
                                                          : featureData[i][2],
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        color: Colors.blue,
                                                        decoration: TextDecoration.underline,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                          ),
                                          DataCell(
                                            isEditingFeatures
                                                ? DropdownButton<String>(
                                                    value: featureControllers[i][3].text,
                                                    items: sectionOptions
                                                        .map((opt) => DropdownMenuItem<String>(
                                                              value: opt['value'],
                                                              child: Text(opt['label']!),
                                                            ))
                                                        .toList(),
                                                    onChanged: (val) {
                                                      setState(() {
                                                        featureControllers[i][3].text = val!;
                                                      });
                                                    },
                                                  )
                                                : Text(
                                                    sectionOptions.firstWhere(
                                                      (opt) => opt['value'] == (featureData[i].length > 3 ? featureData[i][3] : sectionOptions[0]['value']),
                                                      orElse: () => sectionOptions[0],
                                                    )['label']!,
                                                  ),
                                          ),
                                          DataCell(
                                            Switch(
                                              value: featureToggles[i],
                                              onChanged: isEditingFeatures
                                                  ? (val) {
                                                      setState(() {
                                                        featureToggles[i] = val;
                                                      });
                                                    }
                                                  : null,
                                              activeColor: AppColors.accentGreen,
                                              inactiveThumbColor: AppColors.accentBlue,
                                            ),
                                          ),
                                          if (isEditingFeatures)
                                            DataCell(
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.red),
                                                tooltip: 'Delete Row',
                                                onPressed: () async {
                                                  final confirm = await showDeleteConfirmationDialog(context);
                                                  if (confirm) {
                                                    setState(() {
                                                      featureData.removeAt(i);
                                                      featureToggles.removeAt(i);
                                                      featureControllers.removeAt(i);
                                                    });
                                                  }
                                                },
                                              ),
                                            ),
                                        ]),
                                      ),
                                      if (isAddingFeature)
                                        DataRow(cells: [
                                          DataCell(SizedBox(width: 32, child: Text('${featureData.length + 1}'))),
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
                                                keyboardType: TextInputType.text,
                                                textInputAction: TextInputAction.next,
                                                expands: false,
                                                scrollPadding: EdgeInsets.all(8),
                                                style: TextStyle(overflow: TextOverflow.ellipsis),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            SizedBox(
                                              width: 220,
                                              child: TextField(
                                                controller: newFeatureControllers[1],
                                                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Image URL (optional)'),
                                                maxLines: 1,
                                                scrollPhysics: AlwaysScrollableScrollPhysics(),
                                                keyboardType: TextInputType.url,
                                                textInputAction: TextInputAction.next,
                                                expands: false,
                                                scrollPadding: EdgeInsets.all(8),
                                                style: TextStyle(overflow: TextOverflow.ellipsis),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            SizedBox(
                                              width: 220,
                                              child: TextField(
                                                controller: newFeatureControllers[2],
                                                maxLines: 1,
                                                keyboardType: TextInputType.url,
                                                decoration: const InputDecoration(
                                                  border: OutlineInputBorder(),
                                                ),
                                                scrollPhysics: AlwaysScrollableScrollPhysics(),
                                                textInputAction: TextInputAction.next,
                                                expands: false,
                                                scrollPadding: EdgeInsets.all(8),
                                                style: TextStyle(overflow: TextOverflow.ellipsis),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            DropdownButton<String>(
                                              value: newFeatureControllers[3].text,
                                              items: sectionOptions
                                                  .map((opt) => DropdownMenuItem<String>(
                                                        value: opt['value'],
                                                        child: Text(opt['label']!),
                                                      ))
                                                  .toList(),
                                              onChanged: (val) {
                                                setState(() {
                                                  newFeatureControllers[3].text = val!;
                                                });
                                              },
                                            ),
                                          ),
                                          DataCell(
                                            Switch(
                                              value: newFeatureEnabled,
                                              onChanged: (val) {
                                                setState(() {
                                                  newFeatureEnabled = val;
                                                });
                                              },
                                              activeColor: AppColors.accentGreen,
                                              inactiveThumbColor: AppColors.accentBlue,
                                            ),
                                          ),
                                        ]),
                                    ],
                                    columnSpacing: 10,
                                  ),
                                ),
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
                          child: LayoutBuilder(
                            builder: (context, constraints) => SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                  child: Builder(
                                    builder: (context) {
                                      final List<DataRow> adRows = List<DataRow>.generate(
                                        adData.length,
                                        (i) => DataRow(cells: [
                                          DataCell(SizedBox(width: 32, child: Text('${i + 1}'))),
                                          DataCell(
                                            isEditingAds
                                                ? SizedBox(
                                                    width: 160,
                                                    child: TextField(
                                                      controller: adControllers[i][0],
                                                      decoration: const InputDecoration(
                                                        border: OutlineInputBorder(),
                                                        counterText: '',
                                                      ),
                                                      maxLength: 18,
                                                      maxLines: 1,
                                                      inputFormatters: [
                                                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 _\-]')),
                                                        LengthLimitingTextInputFormatter(18),
                                                      ],
                                                      scrollPhysics: AlwaysScrollableScrollPhysics(),
                                                      keyboardType: TextInputType.text,
                                                      textInputAction: TextInputAction.next,
                                                      expands: false,
                                                      scrollPadding: EdgeInsets.all(8),
                                                      style: TextStyle(overflow: TextOverflow.ellipsis),
                                                    ),
                                                  )
                                                : Text(adData[i][0]),
                                          ),
                                          DataCell(
                                            Text(adData[i][1]),
                                          ),
                                          DataCell(
                                            isEditingAds
                                                ? SizedBox(
                                                    width: 160,
                                                    child: TextField(
                                                      controller: adControllers[i][2],
                                                      decoration: const InputDecoration(
                                                        border: OutlineInputBorder(),
                                                      ),
                                                      maxLines: 1,
                                                      scrollPhysics: AlwaysScrollableScrollPhysics(),
                                                      keyboardType: TextInputType.text,
                                                      textInputAction: TextInputAction.next,
                                                      expands: false,
                                                      scrollPadding: EdgeInsets.all(8),
                                                      style: TextStyle(overflow: TextOverflow.ellipsis),
                                                    ),
                                                  )
                                                : Text(adData[i][2]),
                                          ),
                                          DataCell(
                                            Text(adData[i][3]),
                                          ),
                                          DataCell(
                                            Switch(
                                              value: adToggles[i],
                                              onChanged: isEditingAds
                                                  ? (val) {
                                                      setState(() {
                                                        adToggles[i] = val;
                                                      });
                                                    }
                                                  : null,
                                              activeColor: AppColors.accentGreen,
                                              inactiveThumbColor: AppColors.accentBlue,
                                            ),
                                          ),
                                        ]),
                                      );
                                      return DataTable(
                                        columns: [
                                          DataColumn(label: SizedBox(width: 32, child: Text('S/N'))),
                                          DataColumn(label: Text('Ad Name')),
                                          DataColumn(label: Text('Ad Placement')),
                                          DataColumn(label: Text('Ad ID')),
                                          DataColumn(label: Text('Ad Type')),
                                          DataColumn(label: Text('Enable')),
                                        ],
                                        rows: adRows,
                                        columnSpacing: 10,
                                      );
                                    },
                                  ),
                                ),
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
