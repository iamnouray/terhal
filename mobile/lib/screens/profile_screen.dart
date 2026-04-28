import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const _kPrimary = Color(0xFF6B5EA8);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  List<dynamic> _likedPlaces = [];
  bool _isLoading = true;
  String _userId = '';

 @override
void initState() {
  super.initState();
  _loadProfile();
}

@override
void didChangeDependencies() {
  super.didChangeDependencies();
  _loadProfile();
}

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id') ?? '';

    print('Profile userId: $_userId');

    if (_userId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final userRes = await http.get(
        Uri.parse('http://10.0.2.2:8000/users/$_userId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      print('Profile status: ${userRes.statusCode}');
      print('Profile body: ${userRes.body}');

      final likesRes = await http.get(
        Uri.parse('http://10.0.2.2:8000/likes/$_userId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      print('Likes status: ${likesRes.statusCode}');
print('Likes body: ${likesRes.body}');

      if (userRes.statusCode == 200) {
        setState(() {
          _userData = jsonDecode(userRes.body);
          if (likesRes.statusCode == 200) {
            final likesData = jsonDecode(likesRes.body);
            _likedPlaces = likesData is List ? likesData : (likesData['likes'] ?? []);
          }
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Profile error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: _kPrimary)),
      );
    }

    if (_userData == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Failed to load profile'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final name = _userData!['name'] ?? 'Explorer';
    final email = _userData!['email'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Header ──────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                IconButton(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Avatar + Info ────────────────────────
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: _kPrimary,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'T',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Liked Places ─────────────────────────
            Row(
              children: [
                const Icon(Icons.favorite, color: _kPrimary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Liked Places (${_likedPlaces.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_likedPlaces.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'No liked places yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ..._likedPlaces.map((place) {
                final placeName = place['name'] ?? place['destination_id'] ?? 'Unknown';
                final city = place['city'] ?? '';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFF0EEFF),
                      child: Icon(Icons.favorite, color: _kPrimary, size: 18),
                    ),
                    title: Text(
                      placeName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: city.isNotEmpty ? Text(city) : null,
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  ),
                );
              }),

            const SizedBox(height: 32),

            // ── Logout Button ────────────────────────
            ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red,
                elevation: 0,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}