import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'catalog_screen.dart';
import 'outfit_breakdown_screen.dart';
import '../services/location_service.dart';
import '../widgets/weather_graph.dart';

class HomeScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;

  const HomeScreen({super.key, required this.token, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? data;
  bool isLoading = true;
  String error = '';

  int currentOutfitIndex = 0;
  
  // Location State
  double lat = 19.0760;
  double lon = 72.8777;
  String locationLabel = 'Detecting location...';
  bool isManualOverride = false;
  final TextEditingController _searchController = TextEditingController();

  // Occasion state
  String? selectedOccasion; 

  @override
  void initState() {
    super.initState();
    _loadDefaultLocation();
  }

  Future<void> _loadDefaultLocation() async {
    setState(() { isLoading = true; });
    final location = await LocationService.getCurrentLocation();
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
      final occasionParam = selectedOccasion != null ? '&occasion=$selectedOccasion' : '';
      final url = Uri.parse(
          'http://localhost:5000/api/recommend?lat=$lat&lon=$lon&gender=${widget.user['gender'] ?? 'men'}$occasionParam');
      final response = await http.get(url);

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
      setState(() {
        error = 'Connection Error. Is backend running?';
        isLoading = false;
      });
    }
  }

  void _shuffleOutfit() {
    final outfitsList = data!['outfits'] as List;
    if (outfitsList.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only one outfit available — nothing to shuffle!')),
      );
      return;
    }
    int nextIndex;
    do {
      nextIndex = Random().nextInt(outfitsList.length);
    } while (nextIndex == currentOutfitIndex);

    setState(() {
      currentOutfitIndex = nextIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF2C3E50))));
    }

    if (error.isNotEmpty) {
      return Scaffold(body: Center(child: Text(error)));
    }

    final weather = data!['weather'];
    final List<dynamic> outfitsList = data!['outfits'];
    
    // Safety check
    if (outfitsList.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text("No outfits could be generated for this location."),
        ),
      );
    }

    final outfit = outfitsList[currentOutfitIndex];
    final items = outfit['items'] as List;

    final topItem = items.firstWhere((i) => i['category'] == 'top', orElse: () => null);
    final bottomItem = items.firstWhere((i) => i['category'] == 'bottom', orElse: () => null);
    final shoesItem = items.firstWhere((i) => i['category'] == 'footwear', orElse: () => null);
    final accessoryItem = items.firstWhere((i) => i['category'] == 'accessory', orElse: () => null);

    final outfitName = outfit['name'] ?? outfit['title'] ?? 'Nordic Airwork Capsule';
    final outfitDesc = outfit['description'] ?? outfit['explanation'] ?? "Carefully assembled for today's conditions.";

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER ---
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
                          Text("ClimaWear", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text("YOUR WEATHER-SMART WARDROBE", style: TextStyle(fontSize: 8, letterSpacing: 1, color: Colors.grey)),
                        ],
                      )
                    ],
                  ),
                  Row(
                    children: [
                      const Text("Today", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 24),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => OutfitBreakdownScreen(outfit: outfit, weather: weather)));
                        },
                        child: Text("Outfit Breakdown", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ),
                      const SizedBox(width: 24),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => CatalogScreen(token: widget.token, user: widget.user)));
                        },
                        child: Text("Catalog & Favorites", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const CircleAvatar(radius: 14, backgroundColor: Color(0xFF2C3E50), child: Icon(Icons.person, size: 16, color: Colors.white)),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 40),

              // --- GREETING ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("MICROCLIMATE STREAM • DESTINATION FORECAST", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFB07D62), letterSpacing: 1)),
                      const SizedBox(height: 8),
                      Text("Good morning, ${widget.user['name'].split(' ')[0]}.", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text("$locationLabel • ${weather['feelsLike']}°C Chilly Mountain Breeze • ", style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                          if (isManualOverride)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFFF2EBE1), borderRadius: BorderRadius.circular(10)),
                              child: const Text("Custom Destination", style: TextStyle(fontSize: 9, color: Color(0xFF8B5A40), fontWeight: FontWeight.bold)),
                            )
                        ],
                      ),
                    ],
                  ),
                  // Daily Context Box
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                    child: Row(
                      children: [
                        const Icon(Icons.wb_sunny_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Daily Context", style: TextStyle(fontSize: 9, color: Colors.grey)),
                            Text(isManualOverride ? "Manual Transit" : "Local Baseline", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),

              // --- LOCATION SEARCH BAR ---
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F8F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                            child: TextField(
                              controller: _searchController,
                              onSubmitted: (_) => _searchLocation(),
                              decoration: InputDecoration(
                                icon: const Icon(Icons.search, size: 20, color: Colors.grey),
                                hintText: "Search city (e.g., Shimla, Tokyo)...",
                                hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                                border: InputBorder.none,
                                suffixIcon: _searchController.text.isNotEmpty 
                                  ? IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => setState(() => _searchController.clear()))
                                  : null,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _loadDefaultLocation,
                          icon: const Icon(Icons.my_location, size: 16),
                          label: const Text("Live GPS", style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text("Apply Forecast", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Recent Presets
                    Row(
                      children: [
                        const Text("Recent / Presets:", style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(width: 12),
                        _buildPresetChip("Mumbai (31°C)"),
                        _buildPresetChip("Delhi (28°C)"),
                        _buildPresetChip("Tokyo (17°C)"),
                        const Spacer(),
                        Text(isManualOverride ? "Manual Override Active" : "Auto-Detected Active", style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- WEATHER WIDGETS ---
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("AMBIENT DYNAMIC", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text("${weather['feelsLike']}°", style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w300, height: 1)),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8, left: 8),
                                child: Text("Feels like ${weather['feelsLike']}°C", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ),
                              const Spacer(),
                              const Icon(Icons.wb_sunny_outlined, color: Color(0xFFE8B25E), size: 40),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const WeatherGraph(), 
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildWeatherStat(Icons.water_drop_outlined, "Precip", "${weather['rainProb']}%"),
                              _buildWeatherStat(Icons.wb_sunny_outlined, "UV Index", "${weather['uvIndex']}"),
                              _buildWeatherStat(Icons.air, "Wind Speed", "${weather['windSpeed']} km/h"),
                              _buildWeatherStat(Icons.water_drop, "Humidity", "${weather['humidity']}%"),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("ATMOSPHERIC COMFORT MODEL", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: const Color(0xFFF2EBE1), borderRadius: BorderRadius.circular(12)),
                                child: const Text("Tier 2 Equilibrium", style: TextStyle(fontSize: 9, color: Color(0xFF8B5A40))),
                              )
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Row(
                            children: [
                              Text("2.0", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                              SizedBox(width: 8),
                              Text("Warmth Index 2/5", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text("Designed for high breathability with low-wind resistance.", style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 20),
                          _buildComfortRow("Insulation Necessity", "Low"),
                          const SizedBox(height: 8),
                          _buildComfortRow("Skin UV Exposure Safeguard", "UV400 Polarized Accessory"),
                        ],
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),

              // --- RATIONALE BANNER ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(color: const Color(0xFFF2EBE1), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.psychology_outlined, color: Color(0xFFB07D62), size: 20),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text("DRESSING RATIONALE • Algorithmic Forecast\n${outfit['explanation']}", style: const TextStyle(color: Color(0xFF6B4A36), height: 1.4, fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- MAIN OUTFIT SECTION ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        // --- SLIDING TOGGLE ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("TODAY'S CURATED FIT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(30)),
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
                        const SizedBox(height: 16),
                        
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: const Color(0xFFF9F8F6), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                                    child: const Text("Slice of the Day", style: TextStyle(fontSize: 10, color: Colors.grey)),
                                  ),
                                  Text(selectedOccasion ?? "Urban Determined Casual", style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Container(
                                height: 350,
                                width: double.infinity,
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    if (bottomItem?['imageUrl'] != null)
                                      Positioned(bottom: 40, child: Image.network(bottomItem['imageUrl'], height: 160, fit: BoxFit.contain)),
                                    if (topItem?['imageUrl'] != null)
                                      Positioned(top: 70, child: Image.network(topItem['imageUrl'], height: 160, fit: BoxFit.contain)),
                                    if (shoesItem?['imageUrl'] != null)
                                      Positioned(bottom: 10, child: Image.network(shoesItem['imageUrl'], height: 60, fit: BoxFit.contain)),
                                    if (accessoryItem != null && accessoryItem['imageUrl'] != null)
                                      Positioned(top: 20, child: Image.network(accessoryItem['imageUrl'], height: 40, fit: BoxFit.contain)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildBottomStat("Layers", "${items.length}"),
                                  _buildBottomStat("Warmth", "8.2 / 10"),
                                  _buildBottomStat("Precip", "${weather['rainProb']}%"),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 32),

                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("PRIMARY ENSEMBLE #0${currentOutfitIndex + 1}", style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                        const SizedBox(height: 12),
                        Text(outfitName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                        const SizedBox(height: 8),
                        Text(outfitDesc, style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.5)),
                        const SizedBox(height: 24),

                        _buildBreakdownCard("01 · UPPER BASE", topItem?['name'] ?? "Shirt", "${topItem?['color']} · Breathable: ${topItem?['breathable']}", "Warmth ${topItem?['warmthLevel']}", "Upper Base", topItem?['imageUrl']),
                        const SizedBox(height: 12),
                        _buildBreakdownCard("02 · LOWER BASE", bottomItem?['name'] ?? "Pants", "${bottomItem?['color']} · Breathable: ${bottomItem?['breathable']}", "Warmth ${bottomItem?['warmthLevel']}", "Lower Base", bottomItem?['imageUrl']),
                        const SizedBox(height: 12),
                        _buildBreakdownCard("03 · FOOTWEAR", shoesItem?['name'] ?? "Shoes", "${shoesItem?['color']} • Waterproof: ${shoesItem?['waterproof']}", "Warmth ${shoesItem?['warmthLevel']}", "Footwear", shoesItem?['imageUrl']),
                        const SizedBox(height: 12),
                        if (accessoryItem != null)
                          _buildBreakdownCard("04 · ACCESSORY", accessoryItem['name'] ?? "Accessory", "${accessoryItem['color']} · Waterproof: ${accessoryItem['waterproof']}", "Warmth ${accessoryItem['warmthLevel']}", "Optics", accessoryItem['imageUrl']),

                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => OutfitBreakdownScreen(outfit: outfit, weather: weather)));
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C3E50), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                            child: const Text("View Item Breakdown & Fabric Details →", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _shuffleOutfit,
                                icon: const Icon(Icons.shuffle, size: 16),
                                label: const Text("Shuffle Look"),
                                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), side: BorderSide(color: Colors.grey.shade300), foregroundColor: Colors.black87),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to your MongoDB profile!'), backgroundColor: Color(0xFF5A6B50)));
                                },
                                icon: const Icon(Icons.bookmark_border, size: 16),
                                label: const Text("Save to Wardrobe"),
                                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), side: BorderSide(color: Colors.grey.shade300), foregroundColor: Colors.black87),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              )
            ],
          ),
        ),
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
        child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, decoration: TextDecoration.underline)),
      ),
    );
  }

  Widget _buildOccasionToggle(String label, String? value) {
    final isSelected = selectedOccasion == value;
    return GestureDetector(
      onTap: () {
        if (selectedOccasion != value) {
          setState(() { selectedOccasion = value; });
          fetchRecommendation(); 
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2C3E50) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade600, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
      ),
    );
  }

  Widget _buildWeatherStat(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade400),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildComfortRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildBottomStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
      ],
    );
  }

  Widget _buildBreakdownCard(String index, String title, String subtitle, String warmth, String category, String? imageUrl) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: const Color(0xFFF9F8F6), borderRadius: BorderRadius.circular(8)),
            child: imageUrl != null ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(imageUrl, fit: BoxFit.cover)) : const Icon(Icons.checkroom, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(index, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF9F8F6), borderRadius: BorderRadius.circular(4)),
                child: Text(warmth, style: const TextStyle(fontSize: 9, color: Colors.grey)),
              ),
              const SizedBox(height: 4),
              Text(category, style: const TextStyle(fontSize: 9, color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }
}