import 'package:flutter/material.dart';
import 'package:dashboard/Theme/app_colors.dart';
import 'package:pocketbase/pocketbase.dart';
import 'dart:async';
import 'package:pocketbase/pocketbase.dart' as pocketbase;
import 'package:url_launcher/url_launcher.dart';

final pb = PocketBase('http://10.0.2.2:8090');

void main() {
  runApp(const MyApp());
}

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
      title: 'Dummy Verify Halal',
      theme: AppTheme.lightTheme,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, dynamic>> extraFeatures = [];
  List<Map<String, dynamic>> stayConnectedFeatures = [];
  Map<String, dynamic>? bannerAd;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFeaturesAndAds();
  }

  Future<void> _loadFeaturesAndAds() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final featuresRecords = await pb.collection('features').getFullList(
        headers: {
          'Cache-Control': 'no-cache',
        },
      );
      final enabled = featuresRecords.where((r) => r.data['isEnabled'] == true).toList();
      final extra = enabled.where((r) => r.data['section'] == 'extraFeatures').map((r) => r.data).toList();
      final stay = enabled.where((r) => r.data['section'] == 'stayConnected').map((r) => r.data).toList();

      // Fetch ads
      final adsRecords = await pb.collection('ads').getFullList(
        headers: {
          'Cache-Control': 'no-cache',
        },
      );
      final bannerList = adsRecords.where(
        (r) => r.data['adPlacement'] == 'Banner' && r.data['isEnabled'] == true,
      ).toList();
      setState(() {
        extraFeatures = extra;
        stayConnectedFeatures = stay;
        bannerAd = bannerList.isNotEmpty ? bannerList.first.data : null;
        isLoading = false;
        if (extraFeatures.isEmpty && stayConnectedFeatures.isEmpty && featuresRecords.isNotEmpty) {
          errorMessage = 'No Features Enabled.';
        } else if (featuresRecords.isEmpty) {
          errorMessage = 'Feature List Empty.';
        }
      });
    } on pocketbase.ClientException catch (e) {
      setState(() {
        isLoading = false;
        if (e.toString().contains('Connection refused')) {
          errorMessage = 'Connection Error: Could not connect to the PocketBase server. Please ensure the server is running and the URL is correct.';
        } else if (e.statusCode == 404) {
          errorMessage = 'Collection Not Found: The "features" or "ads" collection does not exist in PocketBase. Please check the collection name in your admin dashboard.';
        } else {
          errorMessage = 'A network error occurred: ${e.originalError}';
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'An unexpected error occurred. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'More',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: AppColors.mainBackground,
        child: RefreshIndicator(
          onRefresh: _loadFeaturesAndAds,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Text(
                    'Extra Features',
                    style: TextStyle(
                      color: AppColors.accentBlue,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: _buildSectionGrid(extraFeatures),
              ),
              if (bannerAd != null) // Insert ad card if available
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Container(
                      width: double.infinity,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        bannerAd!['adName'] ?? 'Ad',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Text(
                    'Stay Connected',
                    style: TextStyle(
                      color: AppColors.accentBlue,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: _buildSectionGrid(stayConnectedFeatures),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionGrid(List<Map<String, dynamic>> features) {
    if (isLoading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (errorMessage != null && features.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: ErrorDisplayCard(message: errorMessage!)),
      );
    }
    if (features.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.95,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final feature = features[index];
          final imageUrl = feature['image'] ?? '';
          return Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final link = feature['link']?.toString() ?? '';
                if (link.isNotEmpty && isValidUrl(link)) {
                  final uri = Uri.parse(link);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not open the link.'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (imageUrl != null && imageUrl.toString().trim().isNotEmpty)
                        Container(
                          height: 60,
                          width: 60,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, color: Colors.grey, size: 30),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        feature['featureName'] ?? 'Unknown Feature',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        childCount: features.length,
      ),
    );
  }

  bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

class ErrorDisplayCard extends StatelessWidget {
  final String message;

  const ErrorDisplayCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 40,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}