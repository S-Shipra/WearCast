import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CatalogScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;

  const CatalogScreen({super.key, required this.token, required this.user});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  List<dynamic> clothes = [];
  List<dynamic> favorites = []; 
  bool isLoading = true;
  String error = '';
  String selectedFilter = 'All';
  
  // 1. Added state for the Favorites Only button
  bool showFavoritesOnly = false; 

  @override
  void initState() {
    super.initState();
    fetchCatalogAndFavorites();
  }

  Future<void> fetchCatalogAndFavorites() async {
    try {
      final catalogRes = await http.get(Uri.parse('http://localhost:5000/api/catalog'));
      final favRes = await http.get(Uri.parse('http://localhost:5000/api/user/favorites/${widget.user['id']}'));

      if (catalogRes.statusCode == 200 && favRes.statusCode == 200) {
        setState(() {
          clothes = jsonDecode(catalogRes.body)['items'];
          favorites = jsonDecode(favRes.body);
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

  Future<void> toggleFavorite(String itemId) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/user/favorites/toggle'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': widget.user['id'],
          'itemId': itemId,
        }),
      );

      if (response.statusCode == 200) {
        fetchCatalogAndFavorites(); 
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update favorite')),
      );
    }
  }

  bool isFavorited(String itemId) {
    return favorites.any((fav) => fav['_id'] == itemId);
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> filteredClothes = clothes;
    
    // 2. Filter by Category
    if (selectedFilter != 'All') {
      filteredClothes = filteredClothes.where((item) => 
        item['category'].toString().toLowerCase() == selectedFilter.toLowerCase()
      ).toList();
    }

    // 3. Filter by Favorites (NEW!)
    if (showFavoritesOnly) {
      filteredClothes = filteredClothes.where((item) => 
        isFavorited(item['_id'])
      ).toList();
    }

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
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text("Today", style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ),
                      const SizedBox(width: 24),
                      const Text("Catalog & Favorites", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text("Bengaluru, 28°C", style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                      const SizedBox(width: 16),
                      const CircleAvatar(radius: 14, backgroundColor: Color(0xFF2C3E50), child: Icon(Icons.person, size: 16, color: Colors.white)),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 40),

              const Text("METEOROLOGICAL TAXONOMY SYSTEM", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
              const SizedBox(height: 8),
              const Text("Curated Wardrobe Catalog", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
              const SizedBox(height: 8),
              Text("Browse the full ${clothes.length}-item wardrobe mapped with warmth taxonomy and sensory profiles.", style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 24),

              // --- FILTER BAR ---
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                      child: const TextField(
                        decoration: InputDecoration(
                          icon: Icon(Icons.search, color: Colors.grey, size: 20),
                          hintText: "Filter by garment, color tone, or fabric...",
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // --- FAVORITES ONLY BUTTON (FIXED) ---
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        showFavoritesOnly = !showFavoritesOnly;
                      });
                    },
                    icon: Icon(
                      showFavoritesOnly ? Icons.favorite : Icons.favorite_border, 
                      size: 16,
                      color: showFavoritesOnly ? Colors.red : Colors.black87,
                    ),
                    label: Text(
                      "Favorites Only", 
                      style: TextStyle(
                        fontSize: 12,
                        color: showFavoritesOnly ? Colors.red : Colors.black87,
                        fontWeight: showFavoritesOnly ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: BorderSide(color: showFavoritesOnly ? Colors.red.withOpacity(0.5) : Colors.grey.shade300),
                      backgroundColor: showFavoritesOnly ? Colors.red.withOpacity(0.05) : Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),

              // --- CATEGORY CHIPS ---
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip("All Items", "All"),
                    _buildFilterChip("Tops", "Top"),
                    _buildFilterChip("Bottoms", "Bottom"),
                    _buildFilterChip("Footwear", "Footwear"),
                    _buildFilterChip("Outerwear", "Outerwear"),
                    _buildFilterChip("Accessories", "Accessory"),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- CATALOG GRID ---
              if (isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
              else if (error.isNotEmpty)
                Center(child: Text(error))
              else if (filteredClothes.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("No items found.")))
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: filteredClothes.length,
                  itemBuilder: (context, index) {
                    final item = filteredClothes[index];
                    return _buildCatalogCard(item);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () => setState(() => selectedFilter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2C3E50) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? const Color(0xFF2C3E50) : Colors.grey.shade300),
          ),
          child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey.shade700)),
        ),
      ),
    );
  }

  Widget _buildCatalogCard(dynamic item) {
    final isFav = isFavorited(item['_id']);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9F8F6),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(item['imageUrl'], fit: BoxFit.contain),
                  ),
                ),
                Positioned(
                  top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(4)),
                    child: Text(item['category'].toString().toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                ),
                
                // HEART BUTTON
                Positioned(
                  top: 8, right: 8,
                  child: GestureDetector(
                    onTap: () => toggleFavorite(item['_id']),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white.withOpacity(0.9),
                      child: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        size: 16, 
                        color: isFav ? Colors.red : Colors.grey
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item['category'].toString().toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFF9F8F6), borderRadius: BorderRadius.circular(4)),
                      child: Text("Warmth ${item['warmthLevel']}", style: const TextStyle(fontSize: 8, color: Colors.grey)),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Text(item['name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(item['articleType'].toString().toUpperCase(), style: const TextStyle(fontSize: 9, color: Colors.grey)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("22-30°C Optimal", style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                    Text(item['color'].toString().toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}