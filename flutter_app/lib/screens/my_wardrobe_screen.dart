import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

import '../services/api_config.dart';

class MyWardrobeScreen extends StatefulWidget {
  final String token;
  const MyWardrobeScreen({super.key, required this.token});
  @override
  State<MyWardrobeScreen> createState() => _MyWardrobeScreenState();
}

class _MyWardrobeScreenState extends State<MyWardrobeScreen> {
  List<dynamic> items = [];
  bool loading = true;
  static const ink = Color(0xFF2C3E50);
  static const categories = [
    'top',
    'bottom',
    'outerwear',
    'footwear',
    'accessory',
  ];
  static const colors = [
    'black',
    'white',
    'blue',
    'navy',
    'red',
    'green',
    'brown',
    'beige',
    'grey',
    'pink',
    'purple',
    'yellow',
    'orange',
  ];
  static const sleeves = [
    'not_applicable',
    'sleeveless',
    'short',
    'long',
    'unknown',
  ];
  static const weights = [
    'not_applicable',
    'light',
    'midweight',
    'heavy',
    'unknown',
  ];
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await http
          .get(
            apiUri('user/wardrobe'),
            headers: apiHeaders(token: widget.token),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200 && mounted)
        setState(() {
          items = jsonDecode(response.body)['items'];
          loading = false;
        });
      else if (mounted)
        setState(() => loading = false);
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _add() async {
    final name = TextEditingController();
    final image = TextEditingController();
    String category = 'top',
        color = 'black',
        sleeve = 'short',
        weight = 'light',
        coverage = 'not_applicable',
        occasion = 'Casual';
    int warmth = 2;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, refresh) => Container(
          height: MediaQuery.of(ctx).size.height * .88,
          padding: EdgeInsets.fromLTRB(
            22,
            16,
            22,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFFFAF9F7),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Add to my wardrobe',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: ink,
                ),
              ),
              const Text(
                'A few details help Wearcast match it to the weather.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(controller: name, decoration: _decoration('Item name')),
              const SizedBox(height: 10),
              _select(
                'Category',
                category,
                categories,
                (v) => refresh(() {
                  category = v;
                  if (category == 'footwear') {
                    sleeve = 'not_applicable';
                    weight = 'not_applicable';
                    coverage = 'covered';
                  }
                }),
              ),
              _select('Color', color, colors, (v) => refresh(() => color = v)),
              Row(
                children: [
                  Expanded(
                    child: _select('Warmth', '$warmth / 5', [
                      '1 / 5',
                      '2 / 5',
                      '3 / 5',
                      '4 / 5',
                      '5 / 5',
                    ], (v) => refresh(() => warmth = int.parse(v[0]))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _select('Occasion', occasion, [
                      'Casual',
                      'Formal',
                      'Sports',
                    ], (v) => refresh(() => occasion = v)),
                  ),
                ],
              ),
              if (category == 'top' || category == 'outerwear')
                _select(
                  'Sleeves',
                  sleeve,
                  sleeves,
                  (v) => refresh(() => sleeve = v),
                ),
              if (category != 'footwear')
                _select(
                  'Fabric weight',
                  weight,
                  weights,
                  (v) => refresh(() => weight = v),
                ),
              if (category == 'footwear')
                _select('Foot coverage', coverage, [
                  'open',
                  'covered',
                ], (v) => refresh(() => coverage = v)),
              TextField(
                controller: image,
                decoration: _decoration('Image URL (optional)'),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ink,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(ctx, {
                    'name': name.text.trim(),
                    'category': category,
                    'color': color,
                    'warmthLevel': warmth,
                    'sleeveLength': sleeve,
                    'fabricWeight': weight,
                    'footwearCoverage': coverage,
                    'occasion': occasion,
                    'imageUrl': image.text.trim(),
                    'breathable': weight == 'light',
                  }),
                  child: const Text('Add clothing item'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    name.dispose();
    image.dispose();
    if (result == null) return;
    try {
      final response = await http
          .post(
            apiUri('user/wardrobe'),
            headers: apiHeaders(token: widget.token, json: true),
            body: jsonEncode(result),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 201) {
        await _load();
      } else if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not add item. Check the details and try again.',
            ),
          ),
        );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not reach the server.')),
        );
    }
  }

  Future<void> _delete(String id) async {
    try {
      final r = await http.delete(
        apiUri('user/wardrobe/$id'),
        headers: apiHeaders(token: widget.token),
      );
      if (r.statusCode == 200) await _load();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not remove item.')));
    }
  }

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
  );
  Widget _select(
    String label,
    String value,
    List<String> options,
    ValueChanged<String> onChanged,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: DropdownButtonFormField<String>(
      value: value,
      decoration: _decoration(label),
      items: options
          .map(
            (v) =>
                DropdownMenuItem(value: v, child: Text(v.replaceAll('_', ' '))),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    Widget wardrobeBody;
    if (loading) {
      wardrobeBody = const Center(child: CircularProgressIndicator());
    } else if (items.isEmpty) {
      wardrobeBody = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.checkroom, size: 58, color: ink),
              const SizedBox(height: 16),
              const Text(
                'Your wardrobe starts here',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add a few pieces you own and recommendations can include them.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _add,
                child: const Text('Add your first item'),
              ),
            ],
          ),
        ),
      );
    } else {
      wardrobeBody = ListView.separated(
        padding: const EdgeInsets.all(18),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final item = items[i];
          final url = item['imageUrl'] as String? ?? '';
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListTile(
              leading: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2EBE1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: url.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.checkroom, color: ink),
                        ),
                      )
                    : const Icon(Icons.checkroom, color: ink),
              ),
              title: Text(
                item['name'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.w600, color: ink),
              ),
              subtitle: Text(
                '${item['color']} • ${item['category']} • warmth ${item['warmthLevel']}/5',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => _delete(item['_id']),
              ),
            ),
          );
        },
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: ink,
        title: const Text(
          'My Clothes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        backgroundColor: ink,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add clothes'),
      ),
      body: wardrobeBody,
    );
  }
}
