import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const _kPrimary = Color(0xFF6B5EA8);

class PlaceDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> place;
  const PlaceDetailsScreen({super.key, required this.place});

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  bool _isLiked = false;
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() => _userId = prefs.getString('user_id') ?? '');
  await _checkIfLiked(); // أضيفي هذا
}

Future<void> _checkIfLiked() async {
  try {
    final res = await http.get(
      Uri.parse('http://10.0.2.2:8000/likes/$_userId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final likes = data is List ? data : (data['likes'] ?? []);
      final placeName = widget.place['name'];
      setState(() {
        _isLiked = likes.any((l) =>
            l['destination_name'] == placeName ||
            l['name'] == placeName);
      });
    }
  } catch (e) {
    print('Check liked error: $e');
  }
}

 Future<void> _toggleLike() async {
  final name = widget.place['name'];
  print('Toggle like: $_userId — $name');
  try {
    if (_isLiked) {
      final res = await http.delete(
        Uri.parse('http://10.0.2.2:8000/likes'),
        headers: {'Content-Type': 'application/json'},
       body: jsonEncode({'user_id': _userId, 'destination_id': widget.place['_id'] ?? widget.place['id'] ?? name}),
      );
      print('Unlike status: ${res.statusCode} — ${res.body}');
    } else {
      final res = await http.post(
        Uri.parse('http://10.0.2.2:8000/likes'),
        headers: {'Content-Type': 'application/json'},
       body: jsonEncode({'user_id': _userId, 'destination_id': widget.place['_id'] ?? widget.place['id'] ?? name}),
      );
      print('Like status: ${res.statusCode} — ${res.body}');
    }
    setState(() => _isLiked = !_isLiked);
  } catch (e) {
    print('Like error: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final name = place['name'] ?? 'Unknown';
    final city = place['city'] ?? '';
    final category = place['category'] ?? '';
    final rating = (place['rating'] ?? 0.0).toDouble();
    final reviews = place['reviews'] ?? 0;
    final price = place['prices'] ?? '';
    final description = place['description'] ?? '';
    final rawTags = place['tags'];
final tags = rawTags is List 
    ? List<String>.from(rawTags) 
    : (rawTags is String ? rawTags.split(',') : <String>[]);
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(city, style: const TextStyle(color: Colors.grey)),
              const SizedBox(width: 16),
              const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFC107)),
              const SizedBox(width: 4),
              Text('${rating.toStringAsFixed(1)} ($reviews)',
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(width: 16),
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
                Text(environment, style: const TextStyle(color: Colors.grey)),
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
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Text(tag,
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF444444))),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],

          // Like Button
          ElevatedButton.icon(
            onPressed: _toggleLike,
            icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border),
            label: Text(_isLiked ? 'Saved to Liked' : 'Add to Liked'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isLiked ? Colors.red : _kPrimary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}