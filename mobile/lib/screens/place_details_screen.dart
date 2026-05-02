import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const _kPrimary = Color(0xFF6B5EA8);
const _kBaseUrl = 'http://10.0.2.2:8000';

class PlaceDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> place;
  const PlaceDetailsScreen({super.key, required this.place});

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  bool _isLiked = false;
  String _userId = '';
  List<Map<String, dynamic>> _userLists = [];

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _userId = prefs.getString('user_id') ?? '');
    await _checkIfLiked();
    await _loadUserLists();
  }

  Future<void> _checkIfLiked() async {
    try {
      final res = await http.get(
        Uri.parse('$_kBaseUrl/likes/$_userId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final likes = data is List ? data : (data['data'] ?? data['likes'] ?? []);
        final placeName = widget.place['name'];
        setState(() {
          _isLiked = likes.any((l) =>
              l['destination_id'] == placeName ||
              l['destination_name'] == placeName ||
              l['name'] == placeName);
        });
      }
    } catch (e) {
      print('Check liked error: $e');
    }
  }

  Future<void> _loadUserLists() async {
    try {
      final res = await http.get(
        Uri.parse('$_kBaseUrl/lists/$_userId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _userLists = List<Map<String, dynamic>>.from(
            data is List ? data : (data['data'] ?? []),
          );
        });
      }
    } catch (e) {
      print('Load lists error: $e');
    }
  }

  Future<void> _toggleLike() async {
    final name = widget.place['name'];
    try {
      if (_isLiked) {
        await http.delete(
          Uri.parse('$_kBaseUrl/likes'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': _userId,
            'destination_id': widget.place['_id'] ?? widget.place['id'] ?? name,
          }),
        );
      } else {
        await http.post(
          Uri.parse('$_kBaseUrl/likes'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': _userId,
            'destination_id': widget.place['_id'] ?? widget.place['id'] ?? name,
          }),
        );
      }
      setState(() => _isLiked = !_isLiked);
    } catch (e) {
      print('Like error: $e');
    }
  }

  Future<void> _addToList(String listName) async {
    final placeName = widget.place['name'] ?? '';
    try {
      final res = await http.post(
        Uri.parse(
            '$_kBaseUrl/lists/add-place?user_id=$_userId&list_name=${Uri.encodeComponent(listName)}&destination_id=${Uri.encodeComponent(placeName)}'),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added to "$listName" ✅'),
              backgroundColor: _kPrimary,
            ),
          );
        }
        // ✅ نحدث الـ lists بعد الإضافة
        await _loadUserLists();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to add to list'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Add to list error: $e');
    }
  }

  Future<void> _createNewList(String listName) async {
    try {
      final res = await http.post(
        Uri.parse('$_kBaseUrl/lists'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': _userId,
          'list_name': listName,
        }),
      );
      if (res.statusCode == 200) {
        await _loadUserLists();
        await _addToList(listName);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create list'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Create list error: $e');
    }
  }

  void _showAddToListDialog() {
    final TextEditingController newListController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Save to List',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 16),

              // قائمة الـ lists الموجودة
              if (_userLists.isNotEmpty) ...[
                const Text('Your Lists',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 8),
                ..._userLists.map((list) {
                  // ✅ إصلاح: نتعامل مع places سواء كانت maps أو strings
                  final rawPlaces = list['places'] as List? ?? [];
                  final placesCount = rawPlaces.length;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _kPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.bookmark,
                          color: _kPrimary, size: 20),
                    ),
                    title: Text(
                      list['list_name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                        '$placesCount place${placesCount != 1 ? 's' : ''}'),
                    trailing: const Icon(Icons.add, color: _kPrimary),
                    onTap: () {
                      Navigator.pop(context);
                      _addToList(list['list_name'] ?? '');
                    },
                  );
                }),
                const Divider(),
              ],

              // إنشاء list جديدة
              const Text('Create New List',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: newListController,
                decoration: InputDecoration(
                  hintText: 'List name...',
                  filled: true,
                  fillColor: const Color(0xFFF5F3FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final name = newListController.text.trim();
                    if (name.isNotEmpty) {
                      Navigator.pop(context);
                      _createNewList(name);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Create & Save'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final name = place['name'] ?? 'Unknown';
    final city = place['city'] ?? '';
    final category = place['category'] ?? '';

    // ✅ إصلاح: نتعامل مع rating سواء كان num أو String
    final rawRating = place['rating'];
    final rating = rawRating is num
        ? rawRating.toDouble()
        : double.tryParse(rawRating?.toString() ?? '') ?? 0.0;

    // ✅ إصلاح: نتعامل مع reviews سواء كان num أو String
    final rawReviews = place['reviews'];
    final reviews = rawReviews is num
        ? rawReviews.toInt()
        : int.tryParse(rawReviews?.toString() ?? '') ?? 0;

    final price = place['prices'] ?? place['price'] ?? '';
    final description = place['description'] ?? '';

    // ✅ إصلاح: نتعامل مع tags سواء كانت List أو String
    final rawTags = place['tags'];
    final tags = rawTags is List
        ? List<String>.from(rawTags.map((t) => t.toString()))
        : (rawTags is String && rawTags.isNotEmpty
            ? rawTags.split(',').map((t) => t.trim()).toList()
            : <String>[]);

    final time = place['preferred_time'] ?? '';
    final environment = place['environment'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(name,
            style: const TextStyle(
                color: Color(0xFF1A1A2E), fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(
              _isLiked ? Icons.favorite : Icons.favorite_border,
              color: _isLiked ? Colors.red : Colors.grey,
            ),
            onPressed: _toggleLike,
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: Colors.grey),
            onPressed: _showAddToListDialog,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Icon Banner
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: _kPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Icon(Icons.place, size: 80, color: _kPrimary),
            ),
          ),
          const SizedBox(height: 20),

          // Name + Category
          Text(name,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 8),
          if (category.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _kPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(category,
                  style: const TextStyle(color: _kPrimary, fontSize: 13)),
            ),
          const SizedBox(height: 16),

          // Info Row
          Row(
            children: [
              if (city.isNotEmpty) ...[
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(city, style: const TextStyle(color: Colors.grey)),
                const SizedBox(width: 16),
              ],
              if (rating > 0) ...[
                const Icon(Icons.star_rounded,
                    size: 16, color: Color(0xFFFFC107)),
                const SizedBox(width: 4),
                Text('${rating.toStringAsFixed(1)} ($reviews)',
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(width: 16),
              ],
              if (price.isNotEmpty)
                Text(price,
                    style: const TextStyle(
                        color: _kPrimary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (time.isNotEmpty) ...[
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(time, style: const TextStyle(color: Colors.grey)),
                const SizedBox(width: 16),
              ],
              if (environment.isNotEmpty) ...[
                const Icon(Icons.nature, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(environment,
                    style: const TextStyle(color: Colors.grey)),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // Description
          if (description.isNotEmpty) ...[
            const Text('About',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 8),
            Text(description,
                style: const TextStyle(
                    fontSize: 14, color: Colors.grey, height: 1.6)),
            const SizedBox(height: 20),
          ],

          // Tags
          if (tags.isNotEmpty) ...[
            const Text('Tags',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags
                  .map((tag) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Text(tag,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF444444))),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _toggleLike,
                  icon: Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border),
                  label: Text(_isLiked ? 'Liked' : 'Like'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLiked ? Colors.red : _kPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showAddToListDialog,
                  icon: const Icon(Icons.bookmark_border),
                  label: const Text('Save to List'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _kPrimary,
                    minimumSize: const Size(0, 48),
                    side: const BorderSide(color: _kPrimary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}