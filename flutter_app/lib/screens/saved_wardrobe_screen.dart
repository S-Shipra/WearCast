import 'package:material_ui/material_ui.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

import '../services/api_config.dart';

class SavedWardrobeScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;

  const SavedWardrobeScreen({
    super.key,
    required this.token,
    required this.user,
  });

  @override
  State<SavedWardrobeScreen> createState() => _SavedWardrobeScreenState();
}

class _SavedWardrobeScreenState extends State<SavedWardrobeScreen> {
  List<dynamic> savedOutfits = [];
  bool isLoading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    fetchSavedOutfits();
  }

  Future<void> fetchSavedOutfits() async {
    try {
      final res = await http
          .get(apiUri('outfits'), headers: apiHeaders(token: widget.token))
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (res.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          savedOutfits = jsonDecode(res.body)['outfits'];
          isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          error = 'Failed to load outfits';
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

  Future<void> deleteOutfit(String outfitId) async {
    try {
      final res = await http
          .delete(
            apiUri('outfits/$outfitId'),
            headers: apiHeaders(token: widget.token),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          savedOutfits.removeWhere((outfit) => outfit['_id'] == outfitId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Outfit removed from wardrobe.')),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete outfit.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Connection error.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "My Saved Wardrobe",
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2C3E50)),
            )
          : error.isNotEmpty
          ? Center(child: Text(error))
          : savedOutfits.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 60,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No outfits saved yet.",
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              itemCount: savedOutfits.length,
              itemBuilder: (context, index) {
                final outfit = savedOutfits[index];
                        final items = (outfit['items'] as List)
                            .whereType<Map<String, dynamic>>()
                            .toList();
                final weather = outfit['weatherSnapshot'] ?? {};

                return Dismissible(
                  key: Key(outfit['_id']),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) => deleteOutfit(outfit['_id']),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Saved on ${DateTime.parse(outfit['dateSaved']).toString().split(' ')[0]}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
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
                                  child: Text(
                                    "${weather['feelsLike'] ?? '--'}°C Snapshot",
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF8B5A40),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                InkWell(
                                  onTap: () => deleteOutfit(outfit['_id']),
                                  borderRadius: BorderRadius.circular(20),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: isMobile
                                ? MainAxisAlignment.start
                                : MainAxisAlignment.center,
                            children: items
                                .map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: Container(
                                      width: isMobile ? 60 : 70,
                                      height: isMobile ? 80 : 90,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF9F8F6),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: item['imageUrl'] != null
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                item['imageUrl'],
                                                fit: BoxFit.contain,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.checkroom,
                                              color: Colors.grey,
                                            ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: items
                              .map(
                                (item) => Text(
                                  item['name'] ?? 'Item',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
