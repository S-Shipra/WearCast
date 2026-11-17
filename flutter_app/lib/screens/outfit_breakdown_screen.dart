import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

import '../services/api_config.dart';

class OutfitBreakdownScreen extends StatefulWidget {
  final dynamic outfit;
  final dynamic weather;
  final String token;
  final Map<String, dynamic> user;
  final VoidCallback? onShuffle;
  final Future<void> Function()? onThermalPreferenceChanged;
  final Future<void> Function(Map<String, dynamic>, Map<String, dynamic>)?
  onSave;
  final Future<void> Function(String)? onFeedback;

  const OutfitBreakdownScreen({
    super.key,
    required this.outfit,
    required this.weather,
    required this.token,
    required this.user,
    this.onShuffle,
    this.onThermalPreferenceChanged,
    this.onSave,
    this.onFeedback,
  });

  @override
  State<OutfitBreakdownScreen> createState() => _OutfitBreakdownScreenState();
}

class _OutfitBreakdownScreenState extends State<OutfitBreakdownScreen> {
  late dynamic _selectedItem;
  bool _isFabricCareExpanded = false;
  String _thermalPreference = 'Balanced';
  bool _isSavingThermalPreference = false;
  String? _feedbackRating;

  @override
  void initState() {
    super.initState();
    _feedbackRating = widget.outfit['feedbackRating'] as String?;
    _thermalPreference = switch (widget.user['thermalPreference']) {
      'cold' => 'Cold',
      'hot' => 'Hot',
      _ => 'Balanced',
    };
    final items = widget.outfit['items'] as List;
    _selectedItem = items.firstWhere(
      (i) => i['category'] == 'top',
      orElse: () => items.isNotEmpty ? items[0] : null,
    );
  }

  String _getFabricCareTip() {
    final weatherTemp = widget.weather['feelsLike'] as num;
    final items = widget.outfit['items'] as List;

    String tip = "";
    if (weatherTemp > 25) {
      tip += "High ambient heat detected. Wash in cold water and air-dry in the shade to prevent UV fading and preserve breathable fibers. ";
    } else if (weatherTemp < 15) {
      tip += "Low temperatures. Use a gentle, lukewarm cycle with a wool-safe detergent to maintain insulation loft. ";
    } else {
      tip += "Moderate climate. Standard cold-water wash is recommended to prevent thermal shock to the fibers. ";
    }

    final hasWaterproof = items.any((i) => i['waterproof'] == true);
    if (hasWaterproof) {
      tip += "Do not iron the specialized waterproof outer layers — heat will compromise the synthetic membrane.";
    }

    return tip.trim();
  }

  String _getAlgorithmicIntelligenceText() {
    final explanation = widget.outfit['explanation'];
    if (explanation is String && explanation.isNotEmpty) return explanation;
    final description = _getWeatherIntelligenceText();
    if (_thermalPreference == 'Cold') {
      return '$description Adjusted warmer for your cold-sensitive preference.';
    }
    if (_thermalPreference == 'Hot') {
      return '$description Adjusted lighter for your heat-sensitive preference.';
    }
    return description;
  }

  String _getWeatherIntelligenceText() {
    final temp = widget.weather['feelsLike'] as num;
    final humidity = widget.weather['humidity'] ?? 50;

    if (temp > 28) {
      return "Optimized for high heat ($temp°C) and humidity ($humidity%). Prioritizing extreme breathability and moisture-wicking.";
    } else if (temp < 15) {
      return "Adapted for cold ambient temperatures ($temp°C). Prioritizing thermal retention and wind resistance.";
    } else {
      return "Tuned for moderate conditions ($temp°C). A baseline comfortable ensemble for standard daily wear.";
    }
  }

  void _showPreferencesBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thermal Preference',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'How do you usually feel in these temperatures?',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ListTile(
                enabled: !_isSavingThermalPreference,
                leading: const Icon(Icons.ac_unit, color: Colors.blue),
                title: const Text('I run cold'),
                trailing: _thermalPreference == 'Cold'
                    ? _thermalPreferenceTrailing()
                    : null,
                onTap: () => _persistThermalPreference(
                  'Cold',
                  sheetContext,
                  setSheetState,
                ),
              ),
              ListTile(
                enabled: !_isSavingThermalPreference,
                leading: const Icon(Icons.thermostat, color: Colors.green),
                title: const Text('Balanced'),
                trailing: _thermalPreference == 'Balanced'
                    ? _thermalPreferenceTrailing()
                    : null,
                onTap: () => _persistThermalPreference(
                  'Balanced',
                  sheetContext,
                  setSheetState,
                ),
              ),
              ListTile(
                enabled: !_isSavingThermalPreference,
                leading: const Icon(Icons.wb_sunny, color: Colors.orange),
                title: const Text('I run hot'),
                trailing: _thermalPreference == 'Hot'
                    ? _thermalPreferenceTrailing()
                    : null,
                onTap: () => _persistThermalPreference(
                  'Hot',
                  sheetContext,
                  setSheetState,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendFeedback(String rating) async {
    final callback = widget.onFeedback;
    if (callback == null) return;
    try {
      await callback(rating);
      if (mounted) setState(() => _feedbackRating = rating);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save your feedback.')),
        );
    }
  }

  Widget _thermalPreferenceTrailing() => _isSavingThermalPreference
      ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : const Icon(Icons.check, color: Color(0xFF2C3E50));

  Future<void> _persistThermalPreference(
    String preference,
    BuildContext sheetContext,
    StateSetter setSheetState,
  ) async {
    if (_isSavingThermalPreference) return;
    if (preference == _thermalPreference) {
      Navigator.pop(sheetContext);
      return;
    }

    setState(() => _isSavingThermalPreference = true);
    setSheetState(() {});

    try {
      final response = await http
          .put(
            apiUri('user/thermal-preference'),
            headers: apiHeaders(token: widget.token, json: true),
            body: jsonEncode({'thermalPreference': preference.toLowerCase()}),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw StateError(body['error'] ?? 'Preference could not be saved');
      }

      final savedPreference =
          jsonDecode(response.body)['thermalPreference'] as String;
      if (!mounted) return;

      setState(() {
        _thermalPreference = switch (savedPreference) {
          'cold' => 'Cold',
          'hot' => 'Hot',
          _ => 'Balanced',
        };
        _isSavingThermalPreference = false;
        widget.user['thermalPreference'] = savedPreference;
      });

      final onChanged = widget.onThermalPreferenceChanged;
      if (sheetContext.mounted) Navigator.pop(sheetContext);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preference saved. Updating your outfit…'),
        ),
      );
      Navigator.pop(context);
      if (onChanged != null) await onChanged();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSavingThermalPreference = false);
      if (sheetContext.mounted) setSheetState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save preference: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.outfit['items'] as List;
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

    final String? previewUrl = _selectedItem?['imageUrl'];
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16.0 : 40.0),
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
                          Text(
                            "Wearcast",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Your Weather-Smart Wardrobe",
                            style: TextStyle(fontSize: 9, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (!isMobile)
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            "Today",
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 24),
                        const Text(
                          "Outfit Breakdown",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 24),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            "Catalog & Favorites",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${widget.weather['feelsLike']}°C",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      if (!isMobile) const SizedBox(width: 16),
                      if (!isMobile)
                        const CircleAvatar(
                          radius: 14,
                          backgroundColor: Color(0xFF2C3E50),
                          child: Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // --- TOP NAVIGATION & TITLE ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isMobile)
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Padding(
                              padding: EdgeInsets.only(bottom: 12.0),
                              child: Text(
                                "← Back to Today",
                                style: TextStyle(
                                  color: Color(0xFF2C3E50),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        const Text(
                          "ENSEMBLE DOSSIER · CW-8042 · B",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.outfit['name'] ??
                              widget.outfit['title'] ??
                              "Mediterranean Linen",
                          style: TextStyle(
                            fontSize: isMobile ? 22 : 28,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2C3E50),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isMobile)
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            if (widget.onShuffle != null) widget.onShuffle!();
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.shuffle, size: 14),
                          label: const Text("Shuffle"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            side: BorderSide(color: Colors.grey.shade300),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (widget.onSave != null) {
                              widget.onSave!(widget.outfit, widget.weather);
                            }
                          },
                          icon: const Icon(
                            Icons.bookmark_add_outlined,
                            size: 16,
                          ),
                          label: const Text("Save"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2C3E50),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              if (isMobile) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (widget.onShuffle != null) widget.onShuffle!();
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.shuffle, size: 14),
                        label: const Text("Shuffle"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (widget.onSave != null) {
                            widget.onSave!(widget.outfit, widget.weather);
                          }
                        },
                        icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                        label: const Text("Save"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C3E50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),

              // --- MAIN CONTENT ---
              if (isMobile) ...[
                _buildLeftColumn(previewUrl),
                const SizedBox(height: 32),
                _buildRightColumn(
                  topItem,
                  bottomItem,
                  shoesItem,
                  accessoryItem,
                  isMobile,
                ),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: _buildLeftColumn(previewUrl)),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 5,
                      child: _buildRightColumn(
                        topItem,
                        bottomItem,
                        shoesItem,
                        accessoryItem,
                        isMobile,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 40),

              // --- BOTTOM BANNER ---
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F8F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.psychology_outlined,
                                size: 20,
                                color: Color(0xFFB07D62),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Wardrobe Algorithmic Intelligence ($_thermalPreference Profile)",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getAlgorithmicIntelligenceText(),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _showPreferencesBottomSheet,
                              child: const Text(
                                "Adjust Preferences",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF2C3E50),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.psychology_outlined,
                                  size: 20,
                                  color: Color(0xFFB07D62),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Wardrobe Algorithmic Intelligence ($_thermalPreference Profile)",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2C3E50),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _getAlgorithmicIntelligenceText(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          TextButton(
                            onPressed: _showPreferencesBottomSheet,
                            child: const Text(
                              "Adjust Thermal Preferences",
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF2C3E50),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Was this helpful?',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: 'I like this outfit',
                    visualDensity: VisualDensity.compact,
                    onPressed: _feedbackRating == 'like'
                        ? null
                        : () => _sendFeedback('like'),
                    icon: Icon(
                      Icons.thumb_up_alt_outlined,
                      size: 18,
                      color: _feedbackRating == 'like'
                          ? const Color(0xFF5A6B50)
                          : const Color(0xFF2C3E50),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Suggest something different',
                    visualDensity: VisualDensity.compact,
                    onPressed: _feedbackRating == 'dislike'
                        ? null
                        : () => _sendFeedback('dislike'),
                    icon: Icon(
                      Icons.thumb_down_alt_outlined,
                      size: 18,
                      color: _feedbackRating == 'dislike'
                          ? Colors.redAccent
                          : const Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeftColumn(String? previewUrl) {
    return Column(
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2EBE1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "• Humidity Adaptive",
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF8B5A40),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.bookmark_border,
                    size: 18,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_selectedItem != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedItem['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      if ((widget.outfit['itemReasons']
                              as Map?)?[_selectedItem['_id']?.toString()] !=
                          null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            (widget.outfit['itemReasons']
                                    as Map)[_selectedItem['_id']?.toString()]
                                .toString(),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
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
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.grey,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(
                                  child: Icon(
                                    Icons.checkroom,
                                    size: 100,
                                    color: Colors.grey,
                                  ),
                                ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.checkroom,
                            size: 100,
                            color: Colors.grey,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "METEOROLOGICAL TARGET",
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatBlock(
                    Icons.thermostat,
                    "${widget.weather['feelsLike']}°C",
                    "Feels like",
                  ),
                  _buildStatBlock(
                    Icons.layers_outlined,
                    "Layer 2/5",
                    "Low-to-Med",
                  ),
                  _buildStatBlock(
                    Icons.check_circle_outline,
                    "Casual",
                    "Daily",
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
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
              const Icon(
                Icons.water_drop_outlined,
                size: 20,
                color: Color(0xFF5A6B50),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "High Microclimate Ventilation Required",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Humidity at ${widget.weather['humidity']}%. The unbleached linen weave permits passive vapor escape.",
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightColumn(
    dynamic topItem,
    dynamic bottomItem,
    dynamic shoesItem,
    dynamic accessoryItem,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "DECONSTRUCTED BLUEPRINT",
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
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                "Thermal Index: 0.38",
                style: TextStyle(fontSize: 9, color: Color(0xFF8B5A40)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          "4 Cohesive Components",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),

        if (topItem != null)
          _buildDetailedCard(
            "01 · TORSO SHIELD",
            topItem,
            "High Aeration",
            "320 GSM Poplin",
            isMobile,
          ),
        if (bottomItem != null)
          _buildDetailedCard(
            "02 · LOWER LEG MATRIX",
            bottomItem,
            "Mid-Vent Weave",
            "Tapered Ankle Crop",
            isMobile,
          ),
        if (shoesItem != null)
          _buildDetailedCard(
            "03 · GROUND INTERFACE",
            shoesItem,
            "Dry Surface Certified",
            "Open-Cell Ortholite",
            isMobile,
          ),
        if (accessoryItem != null)
          _buildDetailedCard(
            "04 · OPTICAL SHIELD",
            accessoryItem,
            "UV Index > 6 Triggered",
            "Cat. 3 Lens",
            isMobile,
          ),

        const SizedBox(height: 16),

        // FABRIC CARE
        GestureDetector(
          onTap: () =>
              setState(() => _isFabricCareExpanded = !_isFabricCareExpanded),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F8F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isFabricCareExpanded
                    ? const Color(0xFF2C3E50)
                    : Colors.grey.shade200,
                width: _isFabricCareExpanded ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.spa_outlined,
                          size: 18,
                          color: Color(0xFF2C3E50),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "In-Depth Fabric Care & Thermal Science",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Nordic sustainable fiber maintenance",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    AnimatedRotation(
                      turns: _isFabricCareExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox(width: double.infinity, height: 0),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 16.0, left: 30.0),
                    child: Text(
                      _getFabricCareTip(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                  ),
                  crossFadeState: _isFabricCareExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
              ],
            ),
          ),
        ),
      ],
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
            Text(
              main,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildDetailedCard(
    String index,
    dynamic item,
    String tag,
    String extra,
    bool isMobile,
  ) {
    final bool isSelected =
        _selectedItem != null &&
        _selectedItem['_id']?.toString() == item['_id']?.toString();

    return GestureDetector(
      onTap: () => setState(() => _selectedItem = item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F4F8) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF2C3E50) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF2C3E50)
                              : const Color(0xFFF9F8F6),
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
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  index,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (!isMobile)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF2EBE1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      tag,
                                      style: const TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF8B5A40),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['name'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              "${item['color']} · ${item['breathable'] == true ? 'Breathable' : 'Insulated'}",
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isMobile)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "Thermal Rat.",
                        style: TextStyle(fontSize: 9, color: Colors.grey),
                      ),
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
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F8F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildGridData("Composition", extra),
                  _buildGridData(
                    "Ventilation",
                    item['breathable'] == true ? "High" : "Low",
                  ),
                  if (!isMobile)
                    _buildGridData("Occasion", item['occasion'] ?? "Casual"),
                ],
              ),
            ),
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
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
