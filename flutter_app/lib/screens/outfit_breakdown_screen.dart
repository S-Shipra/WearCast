import 'package:flutter/material.dart';

class OutfitBreakdownScreen extends StatefulWidget {
  final dynamic outfit;
  final dynamic weather;

  const OutfitBreakdownScreen({super.key, required this.outfit, required this.weather});

  @override
  State<OutfitBreakdownScreen> createState() => _OutfitBreakdownScreenState();
}

class _OutfitBreakdownScreenState extends State<OutfitBreakdownScreen> {
  late dynamic _selectedItem;

  @override
  void initState() {
    super.initState();
    // Default preview: show the top item first (or the first item if no top)
    final items = widget.outfit['items'] as List;
    _selectedItem = items.firstWhere(
      (i) => i['category'] == 'top',
      orElse: () => items.isNotEmpty ? items[0] : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.outfit['items'] as List;
    final topItem       = items.firstWhere((i) => i['category'] == 'top',       orElse: () => null);
    final bottomItem    = items.firstWhere((i) => i['category'] == 'bottom',    orElse: () => null);
    final shoesItem     = items.firstWhere((i) => i['category'] == 'footwear',  orElse: () => null);
    final accessoryItem = items.firstWhere((i) => i['category'] == 'accessory', orElse: () => null);

    final String? previewUrl = _selectedItem?['imageUrl'];

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
                          Text("Your Weather-Smart Wardrobe", style: TextStyle(fontSize: 9, color: Colors.grey)),
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
                      const Text("Outfit Breakdown", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 24),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text("Catalog & Favorites", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text("${widget.weather['feelsLike']}°C", style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                      const SizedBox(width: 16),
                      const CircleAvatar(radius: 14, backgroundColor: Color(0xFF2C3E50), child: Icon(Icons.person, size: 16, color: Colors.white)),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 40),

              // --- TOP NAVIGATION & TITLE ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.arrow_back, size: 16, color: Colors.grey),
                          SizedBox(width: 8),
                          Text("ENSEMBLE DOSSIER · CW-8042 · B",
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.outfit['name'] ?? widget.outfit['title'] ?? "Mediterranean Linen & Tapered Twill",
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.shuffle, size: 14),
                        label: const Text("Shuffle Ensemble", style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                        label: const Text("Save to Profile", style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C3E50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 32),

              // --- MAIN CONTENT GRID ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT COLUMN — Preview image + stats
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F8F6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF2EBE1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text("• Humidity Adaptive Ensemble",
                                        style: TextStyle(fontSize: 10, color: Color(0xFF8B5A40), fontWeight: FontWeight.bold)),
                                  ),
                                  Icon(Icons.bookmark_border, size: 18, color: Colors.grey.shade400),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // ── Active item label ──
                              if (_selectedItem != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    _selectedItem['name'] ?? '',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF2C3E50)),
                                  ),
                                ),

                              // ── Main preview image — updates on tap ──
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: Container(
                                  key: ValueKey(previewUrl ?? 'no-image'),
                                  height: 320,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: previewUrl != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            previewUrl,
                                            fit: BoxFit.contain,
                                            width: double.infinity,
                                          ),
                                        )
                                      : const Center(
                                          child: Icon(Icons.checkroom, size: 100, color: Colors.grey),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 20),
                              const Text("METEOROLOGICAL TARGET",
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildStatBlock(Icons.thermostat, "${widget.weather['feelsLike']}°C", "Feels like"),
                                  _buildStatBlock(Icons.layers_outlined, "Layer 2/5", "Low-to-Med"),
                                  _buildStatBlock(Icons.check_circle_outline, "Casual", "Studio / Daily"),
                                ],
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Humidity alert
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F8F6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.water_drop_outlined, size: 20, color: Color(0xFF5A6B50)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("High Microclimate Ventilation Required",
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF2C3E50))),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Humidity at ${widget.weather['humidity']}%. The unbleached linen weave permits passive vapor escape without wind chill exposure.",
                                      style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(width: 24),

                  // RIGHT COLUMN — Tappable breakdown cards
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("DECONSTRUCTED BLUEPRINT",
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFF2EBE1), borderRadius: BorderRadius.circular(4)),
                              child: const Text("Thermal Index: 0.38 clo",
                                  style: TextStyle(fontSize: 9, color: Color(0xFF8B5A40))),
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text("4 Cohesive Components",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),

                        if (topItem != null)
                          _buildDetailedCard("01 · TORSO SHIELD", topItem, "High Aeration", "320 GSM Poplin"),
                        if (bottomItem != null)
                          _buildDetailedCard("02 · LOWER LEG MATRIX", bottomItem, "Mid-Vent Weave", "Tapered Ankle Crop"),
                        if (shoesItem != null)
                          _buildDetailedCard("03 · GROUND INTERFACE", shoesItem, "Dry Surface Certified", "Open-Cell Ortholite"),
                        if (accessoryItem != null)
                          _buildDetailedCard("04 · OPTICAL SHIELD", accessoryItem, "UV Index > 6 Triggered", "Cat. 3 Lens"),

                        const SizedBox(height: 16),

                        // Fabric care row
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F8F6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.spa_outlined, size: 18, color: Color(0xFF2C3E50)),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("In-Depth Fabric Care & Thermal Science",
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      Text("Nordic sustainable fiber maintenance guidelines",
                                          style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                                    ],
                                  )
                                ],
                              ),
                              const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey),
                            ],
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 40),

              // --- BOTTOM BANNER ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F8F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.psychology_outlined, size: 20, color: Color(0xFFB07D62)),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Wardrobe Algorithmic Intelligence",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                            Text("Recommended based on historical personal comfort preferences logged in warm-humid settings.",
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          ],
                        )
                      ],
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text("Adjust Thermal Preferences",
                          style: TextStyle(fontSize: 11, color: Color(0xFF2C3E50), fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBlock(IconData icon, String main, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(main, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
          ],
        ),
        const SizedBox(height: 2),
        Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildDetailedCard(String index, dynamic item, String tag, String extra) {
    final bool isSelected = _selectedItem != null &&
        _selectedItem['_id']?.toString() == item['_id']?.toString();

    return GestureDetector(
      // ✅ Tap → update the preview image on the left
      onTap: () {
        setState(() {
          _selectedItem = item;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F4F8) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            // Highlighted border when this card is active
            color: isSelected ? const Color(0xFF2C3E50) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF2C3E50) : const Color(0xFFF9F8F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item['category'] == 'top'
                            ? Icons.checkroom
                            : item['category'] == 'bottom'
                                ? Icons.straighten
                                : item['category'] == 'footwear'
                                    ? Icons.directions_walk
                                    : Icons.visibility,
                        size: 18,
                        color: isSelected ? Colors.white : const Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(index,
                                style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                    letterSpacing: 1)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFF2EBE1),
                                  borderRadius: BorderRadius.circular(4)),
                              child: Text(tag,
                                  style: const TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF8B5A40))),
                            )
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(item['name'],
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        Text(
                          "${item['color']} · ${item['breathable'] == true ? 'Breathable' : 'Insulated'} · ${item['waterproof'] == true ? 'Waterproof' : 'Standard'}",
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    )
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("Thermal Rat.", style: TextStyle(fontSize: 9, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          Icons.circle,
                          size: 8,
                          color: i < item['warmthLevel']
                              ? const Color(0xFF2C3E50)
                              : Colors.grey.shade300,
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
            const SizedBox(height: 16),
            // Bottom data grid
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                  color: const Color(0xFFF9F8F6), borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildGridData("Composition", extra),
                  _buildGridData("Ventilation", item['breathable'] == true ? "High" : "Low"),
                  _buildGridData("Occasion", item['occasion'] ?? "Casual"),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildGridData(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
      ],
    );
  }
}
