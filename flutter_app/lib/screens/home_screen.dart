import 'package:material_ui/material_ui.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';
import 'dart:math';

import 'catalog_screen.dart';
import 'outfit_breakdown_screen.dart';
import '../services/location_service.dart';
import '../widgets/weather_graph.dart';
import 'saved_wardrobe_screen.dart';
import 'my_wardrobe_screen.dart';
import 'profile_screen.dart';
import '../services/api_config.dart';

class HomeScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;

  const HomeScreen({super.key, required this.token, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  Map<String, dynamic>? data;
  bool isLoading = true;
  String error = '';

  int currentOutfitIndex = 0;

  double lat = 19.0760;
  double lon = 72.8777;
  String locationLabel = 'Detecting location...';
  bool isManualOverride = false;
  final TextEditingController _searchController = TextEditingController();

  String? selectedOccasion;

  late AnimationController _skeletonController;
  late Animation<double> _skeletonAnimation;

  @override
  void initState() {
    super.initState();

    _skeletonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _skeletonAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _skeletonController, curve: Curves.easeInOut),
    );

    _loadDefaultLocation();
  }

  @override
  void dispose() {
    _skeletonController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDefaultLocation() async {
    setState(() => isLoading = true);
    final location = await LocationService.getCurrentLocation();
    if (!mounted) return;
    setState(() {
      lat = location['lat'];
      lon = location['lon'];
      locationLabel = location['city'];
      isManualOverride = false;
      _searchController.clear();
    });
    fetchRecommendation();
  }

  Future<void> _searchLocation() async {
    if (_searchController.text.isEmpty) return;
    setState(() => isLoading = true);
    final location = await LocationService.searchCity(_searchController.text);
    if (!mounted) return;
    if (location != null) {
      setState(() {
        lat = location['lat'];
        lon = location['lon'];
        locationLabel = location['city'];
        isManualOverride = true;
      });
      fetchRecommendation();
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('City not found. Please try again.')),
      );
    }
  }

  Future<void> fetchRecommendation() async {
    setState(() {
      isLoading = true;
      error = '';
    });
    try {
      final query = <String, String>{'lat': '$lat', 'lon': '$lon'};
      final occasion = selectedOccasion;
      if (occasion != null) query['occasion'] = occasion;
      final url = apiUri('recommend', query);
      final response = await http
          .get(url, headers: apiHeaders(token: widget.token))
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          data = jsonDecode(response.body);
          currentOutfitIndex = 0;
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load data';
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = 'Connection Error. Is backend running?';
        isLoading = false;
      });
    }
  }

  Future<void> _submitFeedback(
    Map<String, dynamic> outfit,
    String rating,
  ) async {
    try {
      final response = await http
          .post(
            apiUri('user/recommendation-feedback'),
            headers: apiHeaders(token: widget.token, json: true),
            body: jsonEncode({
              'itemIds': (outfit['items'] as List)
                  .map((item) => item['_id'])
                  .toList(),
              'rating': rating,
            }),
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        if (mounted) setState(() => outfit['feedbackRating'] = rating);
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                rating == 'like'
                    ? 'Got it — we’ll learn from this outfit.'
                    : 'Thanks — we’ll avoid similar choices.',
              ),
            ),
          );
      } else {
        throw StateError('Feedback could not be saved');
      }
    } catch (_) {
      rethrow;
    }
  }

  void _shuffleOutfit() {
    final outfitsList = data!['outfits'] as List;
    if (outfitsList.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only one outfit available — nothing to shuffle!'),
        ),
      );
      return;
    }
    int nextIndex;
    do {
      nextIndex = Random().nextInt(outfitsList.length);
    } while (nextIndex == currentOutfitIndex);
    setState(() => currentOutfitIndex = nextIndex);
  }

  Future<void> _saveOutfit(
    Map<String, dynamic> outfit,
    Map<String, dynamic> weather,
  ) async {
    final itemIds = (outfit['items'] as List)
        .map((i) => i['_id'])
        .where((id) => id != null)
        .toList();

    if (itemIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot save: outfit has no valid items.'),
        ),
      );
      return;
    }

    try {
      final response = await http
          .post(
            apiUri('outfits/save'),
            headers: apiHeaders(token: widget.token, json: true),
            body: jsonEncode({
              'items': itemIds,
              'weatherSnapshot': {
                'feelsLike': weather['feelsLike'],
                'rainProb': weather['rainProb'],
                'uvIndex': weather['uvIndex'],
                'windSpeed': weather['windSpeed'],
                'humidity': weather['humidity'],
              },
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved to your wardrobe ✓'),
            backgroundColor: Color(0xFF5A6B50),
          ),
        );
      } else {
        final err = jsonDecode(response.body)['error'] ?? 'Unknown error';
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $err'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not save this outfit. Check your connection and try again.',
            ),
          ),
        );
      }
    }
  }

  String _weatherDescriptor(num feelsLike) {
    if (feelsLike <= 10) return 'Frigid Breeze';
    if (feelsLike <= 18) return 'Cool Air';
    if (feelsLike <= 24) return 'Mild Conditions';
    if (feelsLike <= 30) return 'Warm Breeze';
    return 'Hot Conditions';
  }

  int _warmthIndex(num feelsLike) {
    if (feelsLike <= 10) return 5;
    if (feelsLike <= 18) return 4;
    if (feelsLike <= 24) return 3;
    if (feelsLike <= 30) return 2;
    return 1;
  }

  String _insulationNeed(num feelsLike) {
    if (feelsLike <= 10) return 'High';
    if (feelsLike <= 18) return 'Moderate';
    if (feelsLike <= 24) return 'Low';
    return 'Minimal';
  }

  String _insulationBlurb(int warmth) {
    switch (warmth) {
      case 5:
        return 'Engineered for heavy insulation and cold-wind resistance.';
      case 4:
        return 'Balanced insulation for cool, breezy conditions.';
      case 3:
        return 'Moderate breathability with light layering.';
      case 2:
        return 'Designed for high breathability with low-wind resistance.';
      default:
        return 'Maximum breathability — cooling-focused ensemble.';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAF9F7),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: AnimatedBuilder(
              animation: _skeletonAnimation,
              builder: (context, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSkeletonBox(width: 150, height: 40),
                        _buildSkeletonBox(width: 200, height: 20),
                        _buildSkeletonBox(width: 30, height: 30, radius: 15),
                      ],
                    ),
                    const SizedBox(height: 40),
                    _buildSkeletonBox(width: 300, height: 40),
                    const SizedBox(height: 8),
                    _buildSkeletonBox(width: 250, height: 20),
                    const SizedBox(height: 32),
                    _buildSkeletonBox(
                      width: double.infinity,
                      height: 70,
                      radius: 12,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: _buildSkeletonBox(
                            width: double.infinity,
                            height: 250,
                            radius: 16,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 4,
                          child: _buildSkeletonBox(
                            width: double.infinity,
                            height: 250,
                            radius: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: _buildSkeletonBox(
                            width: double.infinity,
                            height: 400,
                            radius: 16,
                          ),
                        ),
                        const SizedBox(width: 32),
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              _buildSkeletonBox(
                                width: double.infinity,
                                height: 20,
                              ),
                              const SizedBox(height: 12),
                              _buildSkeletonBox(
                                width: double.infinity,
                                height: 20,
                              ),
                              const SizedBox(height: 12),
                              _buildSkeletonBox(
                                width: 200,
                                height: 60,
                                radius: 12,
                              ),
                              const SizedBox(height: 12),
                              _buildSkeletonBox(
                                width: 200,
                                height: 60,
                                radius: 12,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    }
    if (error.isNotEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAF9F7),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 42,
                      color: Color(0xFF5A6B50),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Couldn’t load today’s forecast',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: fetchRecommendation,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final Map<String, dynamic> weather = Map<String, dynamic>.from(
      data!['weather'],
    );
    final List<dynamic> outfitsList = data!['outfits'];

    if (outfitsList.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAF9F7),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.checkroom, size: 44, color: Color(0xFF5A6B50)),
              const SizedBox(height: 12),
              const Text('No outfits match these conditions.'),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: fetchRecommendation,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    final outfit = outfitsList[currentOutfitIndex];
    final items = outfit['items'] as List;

    final topItem = items.firstWhere(
      (i) => i['category'] == 'top',
      orElse: () => null,
    );
    final bottomItem = items.firstWhere(
      (i) => i['category'] == 'bottom',
      orElse: () => null,
    );
    final shoesItem = items.firstWhere(
      (i) => i['category'] == 'footwear',
      orElse: () => null,
    );
    final accessoryItem = items.firstWhere(
      (i) => i['category'] == 'accessory',
      orElse: () => null,
    );

    final outfitName =
        outfit['name'] ?? outfit['title'] ?? 'Nordic Airwork Capsule';
    final outfitDesc =
        outfit['description'] ??
        outfit['explanation'] ??
        "Carefully assembled for today's conditions.";

    final num feelsLike = weather['feelsLike'];

    // RESPONSIVE CHECK
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16.0 : 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(outfit, weather, isMobile),
              const SizedBox(height: 40),
              _buildGreeting(weather, feelsLike, isMobile),
              const SizedBox(height: 24),
              _buildSearchBar(isMobile),
              const SizedBox(height: 32),
              _buildWeatherWidgets(weather, isMobile),
              const SizedBox(height: 16),
              _buildRationaleBanner(outfit),
              const SizedBox(height: 32),
              _buildMainOutfitSection(
                outfit: outfit,
                weather: weather,
                items: items,
                topItem: topItem,
                bottomItem: bottomItem,
                shoesItem: shoesItem,
                accessoryItem: accessoryItem,
                outfitName: outfitName,
                outfitDesc: outfitDesc,
                isMobile: isMobile,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    Map<String, dynamic> outfit,
    Map<String, dynamic> weather,
    bool isMobile,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.wb_sunny, color: Color(0xFF2C3E50), size: 24),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Wearcast",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "YOUR WEATHER-SMART WARDROBE",
                      style: TextStyle(
                        fontSize: 8,
                        letterSpacing: 1,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // PROFILE MENU
            PopupMenuButton<String>(
              offset: const Offset(0, 40),
              icon: const CircleAvatar(
                radius: 14,
                backgroundColor: Color(0xFF2C3E50),
                child: Icon(Icons.person, size: 16, color: Colors.white),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                if (value == 'profile') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProfileScreen(token: widget.token, user: widget.user),
                    ),
                  ).then((_) {
                    if (mounted) fetchRecommendation();
                  });
                } else if (value == 'wardrobe') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SavedWardrobeScreen(
                        token: widget.token,
                        user: widget.user,
                      ),
                    ),
                  );
                } else if (value == 'my_clothes') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MyWardrobeScreen(token: widget.token),
                    ),
                  ).then((_) {
                    if (mounted) fetchRecommendation();
                  });
                } else if (value == 'logout') {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/', (route) => false);
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user['name'] ?? 'User',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          widget.user['email'] ?? 'email@example.com',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(
                          Icons.manage_accounts_outlined,
                          size: 16,
                          color: Color(0xFF2C3E50),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'My Profile',
                          style: TextStyle(color: Color(0xFF2C3E50)),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'wardrobe',
                    child: Row(
                      children: [
                        Icon(
                          Icons.bookmarks_outlined,
                          size: 16,
                          color: Color(0xFF2C3E50),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'My Wardrobe',
                          style: TextStyle(color: Color(0xFF2C3E50)),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'my_clothes',
                    child: Row(
                      children: [
                        Icon(
                          Icons.checkroom_outlined,
                          size: 16,
                          color: Color(0xFF2C3E50),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'My Clothes',
                          style: TextStyle(color: Color(0xFF2C3E50)),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Log Out', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
        if (!isMobile) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildNavLink("Today", () {}),
              const SizedBox(width: 24),
              _buildNavLink("Outfit Breakdown", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OutfitBreakdownScreen(
                      outfit: outfit,
                      weather: weather,
                      token: widget.token,
                      user: widget.user,
                      onShuffle: _shuffleOutfit,
                      onThermalPreferenceChanged: fetchRecommendation,
                      onSave: _saveOutfit,
                      onFeedback: (rating) => _submitFeedback(outfit, rating),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 24),
              _buildNavLink("Catalog & Favorites", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CatalogScreen(
                      token: widget.token,
                      user: widget.user,
                      locationLabel: locationLabel,
                      weather: weather,
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
        if (isMobile) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavLink("Breakdown", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OutfitBreakdownScreen(
                      outfit: outfit,
                      weather: weather,
                      token: widget.token,
                      user: widget.user,
                      onShuffle: _shuffleOutfit,
                      onThermalPreferenceChanged: fetchRecommendation,
                      onSave: _saveOutfit,
                      onFeedback: (rating) => _submitFeedback(outfit, rating),
                    ),
                  ),
                );
              }),
              _buildNavLink("Catalog", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CatalogScreen(
                      token: widget.token,
                      user: widget.user,
                      locationLabel: locationLabel,
                      weather: weather,
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildNavLink(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
      ),
    );
  }

  Widget _buildGreeting(
    Map<String, dynamic> weather,
    num feelsLike,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "MICROCLIMATE STREAM • DESTINATION FORECAST",
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Color(0xFFB07D62),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Good morning, ${widget.user['name'].split(' ')[0]}.",
          style: TextStyle(
            fontSize: isMobile ? 24 : 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          children: [
            const Icon(Icons.location_on, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              "$locationLabel • ${weather['feelsLike']}°C ${_weatherDescriptor(feelsLike)} • ",
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isManualOverride)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2EBE1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  "Custom Destination",
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFF8B5A40),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F8F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          if (isMobile) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) => _searchLocation(),
                decoration: const InputDecoration(
                  icon: Icon(Icons.search, size: 20, color: Colors.grey),
                  hintText: "Search city...",
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _searchLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C3E50),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Apply Forecast"),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: (_) => _searchLocation(),
                      decoration: const InputDecoration(
                        icon: Icon(Icons.search, size: 20, color: Colors.grey),
                        hintText: "Search city (e.g., Shimla, Tokyo)...",
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _loadDefaultLocation,
                  icon: const Icon(Icons.my_location, size: 16),
                  label: const Text("Live GPS"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                    foregroundColor: Colors.black87,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _searchLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C3E50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 18,
                    ),
                  ),
                  child: const Text("Apply Forecast"),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text(
                  "Recent / Presets:",
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                _buildPresetChip("Mumbai"),
                _buildPresetChip("Delhi"),
                _buildPresetChip("Tokyo"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherWidgets(Map<String, dynamic> weather, bool isMobile) {
    final num feelsLike = weather['feelsLike'];
    final int warmthIdx = _warmthIndex(feelsLike);
    final int comfortTier = (5 - warmthIdx).clamp(1, 5);

    Widget leftCard = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "AMBIENT DYNAMIC",
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${weather['feelsLike']}°",
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w300,
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 8),
                child: Text(
                  "Feels like ${weather['feelsLike']}°C",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.wb_sunny_outlined,
                color: Color(0xFFE8B25E),
                size: 40,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const WeatherGraph(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildWeatherStat(
                Icons.water_drop_outlined,
                "Precip",
                "${weather['rainProb']}%",
              ),
              _buildWeatherStat(
                Icons.wb_sunny_outlined,
                "UV Index",
                "${weather['uvIndex']}",
              ),
              _buildWeatherStat(
                Icons.air,
                "Wind Speed",
                "${weather['windSpeed']} km/h",
              ),
              _buildWeatherStat(
                Icons.water_drop,
                "Humidity",
                "${weather['humidity']}%",
              ),
            ],
          ),
        ],
      ),
    );

    Widget rightCard = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "ATMOSPHERIC COMFORT",
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2EBE1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Tier $comfortTier",
                  style: const TextStyle(fontSize: 9, color: Color(0xFF8B5A40)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                warmthIdx.toDouble().toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "Warmth Index $warmthIdx/5",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _insulationBlurb(warmthIdx),
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          _buildComfortRow("Insulation", _insulationNeed(feelsLike)),
          const SizedBox(height: 8),
          _buildComfortRow(
            "UV Guard",
            (weather['uvIndex'] as num) >= 3 ? "Required" : "Minimal",
          ),
        ],
      ),
    );

    if (isMobile) {
      return Column(
        children: [leftCard, const SizedBox(height: 16), rightCard],
      );
    }

    return Row(
      children: [
        Expanded(flex: 5, child: leftCard),
        const SizedBox(width: 16),
        Expanded(flex: 4, child: rightCard),
      ],
    );
  }

  Widget _buildRationaleBanner(Map<String, dynamic> outfit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2EBE1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.psychology_outlined,
            color: Color(0xFFB07D62),
            size: 20,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              "DRESSING RATIONALE\n${outfit['explanation']}",
              style: const TextStyle(
                color: Color(0xFF6B4A36),
                height: 1.4,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainOutfitSection({
    required Map<String, dynamic> outfit,
    required Map<String, dynamic> weather,
    required List items,
    required dynamic topItem,
    required dynamic bottomItem,
    required dynamic shoesItem,
    required dynamic accessoryItem,
    required String outfitName,
    required String outfitDesc,
    required bool isMobile,
  }) {
    Widget leftSide = Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "TODAY'S CURATED FIT",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1,
              ),
            ),
            if (!isMobile)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    _buildOccasionToggle("All", null),
                    _buildOccasionToggle("Casual", "Casual"),
                    _buildOccasionToggle("Formal", "Formal"),
                    _buildOccasionToggle("Sports", "Sports"),
                  ],
                ),
              ),
          ],
        ),
        if (isMobile) ...[
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildOccasionToggle("All", null),
                _buildOccasionToggle("Casual", "Casual"),
                _buildOccasionToggle("Formal", "Formal"),
                _buildOccasionToggle("Sports", "Sports"),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F8F6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "Slice of the Day",
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
                  Text(
                    selectedOccasion ?? "Urban Casual",
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                height: 350,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (bottomItem?['imageUrl'] != null)
                      Positioned(
                        bottom: 40,
                        child: _buildNetworkImage(
                          bottomItem['imageUrl'],
                          height: 160,
                        ),
                      ),
                    if (topItem?['imageUrl'] != null)
                      Positioned(
                        top: 70,
                        child: _buildNetworkImage(
                          topItem['imageUrl'],
                          height: 160,
                        ),
                      ),
                    if (shoesItem?['imageUrl'] != null)
                      Positioned(
                        bottom: 10,
                        child: _buildNetworkImage(
                          shoesItem['imageUrl'],
                          height: 60,
                        ),
                      ),
                    if (accessoryItem != null &&
                        accessoryItem['imageUrl'] != null)
                      Positioned(
                        top: 20,
                        child: _buildNetworkImage(
                          accessoryItem['imageUrl'],
                          height: 40,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildBottomStat("Layers", "${items.length}"),
                  _buildBottomStat(
                    "Warmth",
                    "${_warmthIndex(weather['feelsLike'] as num)} / 5",
                  ),
                  _buildBottomStat("Precip", "${weather['rainProb']}%"),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    Widget rightSide = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "PRIMARY ENSEMBLE #0${currentOutfitIndex + 1}",
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          outfitName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          outfitDesc,
          style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
        ),
        const SizedBox(height: 24),
        _buildBreakdownCard(
          "01 · UPPER",
          topItem?['name'] ?? "Shirt",
          "${topItem?['color']} · Breathable: ${topItem?['breathable']}",
          "Warmth ${topItem?['warmthLevel']}",
          "Upper",
          topItem?['imageUrl'],
        ),
        const SizedBox(height: 12),
        _buildBreakdownCard(
          "02 · LOWER",
          bottomItem?['name'] ?? "Pants",
          "${bottomItem?['color']} · Breathable: ${bottomItem?['breathable']}",
          "Warmth ${bottomItem?['warmthLevel']}",
          "Lower",
          bottomItem?['imageUrl'],
        ),
        const SizedBox(height: 12),
        _buildBreakdownCard(
          "03 · FOOTWEAR",
          shoesItem?['name'] ?? "Shoes",
          "${shoesItem?['color']} • WP: ${shoesItem?['waterproof']}",
          "Warmth ${shoesItem?['warmthLevel']}",
          "Footwear",
          shoesItem?['imageUrl'],
        ),
        const SizedBox(height: 12),
        if (accessoryItem != null)
          _buildBreakdownCard(
            "04 · ACCESSORY",
            accessoryItem['name'] ?? "Accessory",
            "${accessoryItem['color']} · WP: ${accessoryItem['waterproof']}",
            "Warmth ${accessoryItem['warmthLevel']}",
            "Optics",
            accessoryItem['imageUrl'],
          ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OutfitBreakdownScreen(
                    outfit: outfit,
                    weather: weather,
                    token: widget.token,
                    user: widget.user,
                    onShuffle: _shuffleOutfit,
                    onThermalPreferenceChanged: fetchRecommendation,
                    onSave: _saveOutfit,
                    onFeedback: (rating) => _submitFeedback(outfit, rating),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C3E50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "View Breakdown →",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _shuffleOutfit,
                icon: const Icon(Icons.shuffle, size: 16),
                label: const Text("Shuffle"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide(color: Colors.grey.shade300),
                  foregroundColor: Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _saveOutfit(outfit, weather),
                icon: const Icon(Icons.bookmark_border, size: 16),
                label: const Text("Save"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide(color: Colors.grey.shade300),
                  foregroundColor: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ],
    );

    if (isMobile) {
      return Column(
        children: [leftSide, const SizedBox(height: 32), rightSide],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 5, child: leftSide),
        const SizedBox(width: 32),
        Expanded(flex: 5, child: rightSide),
      ],
    );
  }

  Widget _buildSkeletonBox({
    required double width,
    required double height,
    double radius = 8,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300.withValues(alpha: _skeletonAnimation.value),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildNetworkImage(
    String url, {
    double? height,
    double? width,
    BoxFit fit = BoxFit.contain,
  }) {
    return Image.network(
      url,
      height: height,
      width: width,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          height: height,
          width: width,
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.grey,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => SizedBox(
        height: height,
        width: width,
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }

  Widget _buildPresetChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () {
          _searchController.text = label.split(' (')[0];
          _searchLocation();
        },
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  Widget _buildOccasionToggle(String label, String? value) {
    final isSelected = selectedOccasion == value;
    return GestureDetector(
      onTap: () {
        if (selectedOccasion != value) {
          setState(() => selectedOccasion = value);
          fetchRecommendation();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2C3E50) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherStat(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade400),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildComfortRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildBottomStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownCard(
    String index,
    String title,
    String subtitle,
    String warmth,
    String category,
    String? imageUrl,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFF9F8F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildNetworkImage(imageUrl, fit: BoxFit.cover),
                  )
                : const Icon(Icons.checkroom, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  index,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F8F6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  warmth,
                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                category,
                style: const TextStyle(fontSize: 9, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
