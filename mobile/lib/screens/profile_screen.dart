import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const _kPrimary = Color(0xFF6B5EA8);
const _kPrimaryLight = Color(0xFFF0EEFF);
const _kBaseUrl = 'http://10.0.2.2:8000';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  List<dynamic> _likedPlaces = [];
  List<dynamic> _savedLists = [];
  bool _isLoading = true;
  String _userId = '';

  String? _activePanel;

  String _selectedCity = 'Riyadh';
  bool _notificationsEnabled = false;
  bool _savingSettings = false;

  final List<String> _cities = [
    'Riyadh', 'Jeddah', 'Abha', 'AlUla', 'Madinah'
  ];

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
    if (_userId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final results = await Future.wait([
        http.get(Uri.parse('$_kBaseUrl/users/$_userId')),
        http.get(Uri.parse('$_kBaseUrl/likes/$_userId')),
        http.get(Uri.parse('$_kBaseUrl/lists/$_userId')),
      ]);

      final userRes = results[0];
      final likesRes = results[1];
      final listsRes = results[2];

      if (userRes.statusCode == 200) {
        final userData = jsonDecode(userRes.body) as Map<String, dynamic>;
        final prefs2 = userData['preferences'];
        if (prefs2 is Map && prefs2['city'] != null) {
          final city = (prefs2['city'] as String);
          final matched = _cities.firstWhere(
            (c) => c.toLowerCase() == city.toLowerCase(),
            orElse: () => 'Riyadh',
          );
          _selectedCity = matched;
        }

        setState(() {
          _userData = userData;
          if (likesRes.statusCode == 200) {
            final d = jsonDecode(likesRes.body);
            _likedPlaces = d is List ? d : (d['data'] ?? d['likes'] ?? []);
          }
          if (listsRes.statusCode == 200) {
            final d = jsonDecode(listsRes.body);
            _savedLists = d is List ? d : (d['data'] ?? d['lists'] ?? []);
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

  Future<void> _saveSettings() async {
    setState(() => _savingSettings = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', _notificationsEnabled);

      final res = await http.put(
        Uri.parse('$_kBaseUrl/users/$_userId/preferences'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'city': _selectedCity.toLowerCase(),
          'visitor_type': _userData?['preferences']?['visitor_type'],
          'preferred_time': _userData?['preferences']?['preferred_time'],
          'mood': _userData?['preferences']?['mood'],
          'activity': _userData?['preferences']?['activity'],
          'budget': _userData?['preferences']?['budget'],
          'environment': _userData?['preferences']?['environment'],
        }),
      );

      if (res.statusCode == 200) {
        _showSnack('Settings saved ✓', success: true);
      } else {
        _showSnack('Failed to save settings');
      }
    } catch (e) {
      _showSnack('Connection error');
    }
    setState(() => _savingSettings = false);
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? Colors.green : Colors.red,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _toggle(String panel) {
    setState(() => _activePanel = _activePanel == panel ? null : panel);
  }

  void _showListDetails(Map<String, dynamic> list) {
    final listName = list['list_name'] ?? 'Unnamed List';
    final rawPlaces = list['places'] as List? ?? [];

    // ✅ فصل بين maps و strings
    final places = rawPlaces.whereType<Map>().toList();
    final placeIds = rawPlaces.whereType<String>().toList();
    final totalCount = places.isNotEmpty ? places.length : placeIds.length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A90D9).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bookmark_rounded,
                          color: Color(0xFF4A90D9), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            listName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          Text(
                            '$totalCount place${totalCount != 1 ? 's' : ''}',
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: totalCount == 0
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.place_outlined,
                                size: 48,
                                color: _kPrimary.withOpacity(0.3)),
                            const SizedBox(height: 12),
                            const Text(
                              'No places in this list yet',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: controller,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: totalCount,
                        itemBuilder: (_, i) {
                          // ✅ لو places عبارة عن maps كاملة
                          if (places.isNotEmpty) {
                            final p = places[i];
                            final placeName = p['name'] ??
                                p['destination_id'] ??
                                'Unknown';
                            final category = p['category'] ?? '';
                            final city = p['city'] ?? '';
                            final rawRating = p['rating'];
                            final rating = rawRating is num
                                ? rawRating.toDouble()
                                : 0.0;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAF9FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: _kPrimary.withOpacity(0.08)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: _kPrimary.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.place_rounded,
                                        color: _kPrimary, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          placeName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: Color(0xFF1A1A2E),
                                          ),
                                        ),
                                        if (city.isNotEmpty ||
                                            category.isNotEmpty)
                                          Text(
                                            [city, category]
                                                .where((s) => s.isNotEmpty)
                                                .join(' · '),
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (rating > 0)
                                    Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star_rounded,
                                              color: Color(0xFFFFC107),
                                              size: 15),
                                          const SizedBox(width: 2),
                                          Text(
                                            rating.toStringAsFixed(1),
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight:
                                                    FontWeight.w600),
                                          ),
                                        ]),
                                ],
                              ),
                            );
                          }

                          // ✅ لو places عبارة عن string IDs فقط
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF9FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: _kPrimary.withOpacity(0.08)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: _kPrimary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.place_rounded,
                                      color: _kPrimary, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    placeIds[i],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Color(0xFF1A1A2E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F7FF),
        body: Center(child: CircularProgressIndicator(color: _kPrimary)),
      );
    }

    if (_userData == null) {
      return Scaffold(
        body: Center(
          child:
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Failed to load profile'),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _loadProfile, child: const Text('Retry')),
          ]),
        ),
      );
    }

    final name = _userData!['name'] ?? 'Explorer';
    final email = _userData!['email'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProfile,
          color: _kPrimary,
          child: ListView(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              _buildHeader(name, email),
              const SizedBox(height: 20),
              _buildPanelButton(
                icon: Icons.favorite_rounded,
                iconColor: const Color(0xFFE85D75),
                label: 'Liked Places',
                count: _likedPlaces.length,
                panel: 'liked',
              ),
              if (_activePanel == 'liked') _buildLikedPanel(),
              const SizedBox(height: 10),
              _buildPanelButton(
                icon: Icons.bookmark_rounded,
                iconColor: const Color(0xFF4A90D9),
                label: 'Saved List',
                count: _savedLists.length,
                panel: 'saved',
              ),
              if (_activePanel == 'saved') _buildSavedPanel(),
              const SizedBox(height: 10),
              _buildPanelButton(
                icon: Icons.settings_rounded,
                iconColor: const Color(0xFF6B5EA8),
                label: 'Settings',
                panel: 'settings',
              ),
              if (_activePanel == 'settings') _buildSettingsPanel(),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _logout,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded,
                          color: Colors.red.shade400, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Sign Out',
                        style: TextStyle(
                          color: Colors.red.shade400,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name, String email) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: _kPrimary,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'T',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 4),
                Text(email,
                    style: const TextStyle(
                        fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 10),
                Row(children: [
                  _buildStatChip(Icons.favorite,
                      '${_likedPlaces.length}', 'Liked'),
                  const SizedBox(width: 8),
                  _buildStatChip(
                      Icons.bookmark, '${_savedLists.length}', 'Lists'),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String count, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _kPrimaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: _kPrimary),
        const SizedBox(width: 4),
        Text('$count $label',
            style: const TextStyle(
                fontSize: 12,
                color: _kPrimary,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildPanelButton({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String panel,
    int? count,
  }) {
    final isOpen = _activePanel == panel;
    return GestureDetector(
      onTap: () => _toggle(panel),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isOpen ? _kPrimaryLight : Colors.white,
          borderRadius: isOpen
              ? const BorderRadius.vertical(top: Radius.circular(16))
              : BorderRadius.circular(16),
          border: Border.all(
            color:
                isOpen ? _kPrimary.withOpacity(0.3) : Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isOpen ? _kPrimary : const Color(0xFF1A1A2E),
              ),
            ),
          ),
          if (count != null)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isOpen ? _kPrimary : const Color(0xFFE8E8E8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color:
                      isOpen ? Colors.white : const Color(0xFF666666),
                ),
              ),
            ),
          const SizedBox(width: 8),
          Icon(
            isOpen
                ? Icons.keyboard_arrow_up
                : Icons.keyboard_arrow_down,
            color: isOpen ? _kPrimary : Colors.grey,
            size: 22,
          ),
        ]),
      ),
    );
  }

  Widget _buildLikedPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kPrimary.withOpacity(0.2)),
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: _likedPlaces.isEmpty
          ? _emptyState('No liked places yet', Icons.favorite_border)
          : Column(
              children: _likedPlaces.map((place) {
                final name = place['name'] ??
                    place['destination_id'] ??
                    'Unknown';
                final city = place['city'] ?? '';
                final category = place['category'] ?? '';
                final rawRating = place['rating'];
                final rating =
                    rawRating is num ? rawRating.toDouble() : 0.0;
                return _listTileItem(
                  icon: Icons.favorite,
                  iconColor: const Color(0xFFE85D75),
                  title: name,
                  subtitle: [city, category]
                      .where((s) => s.isNotEmpty)
                      .join(' · '),
                  trailing: rating > 0
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Color(0xFFFFC107), size: 14),
                            const SizedBox(width: 2),
                            Text(rating.toStringAsFixed(1),
                                style:
                                    const TextStyle(fontSize: 13)),
                          ])
                      : null,
                );
              }).toList(),
            ),
    );
  }

  Widget _buildSavedPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kPrimary.withOpacity(0.2)),
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: _savedLists.isEmpty
          ? Column(children: [
              _emptyState('No saved lists yet', Icons.bookmark_border),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton.icon(
                  onPressed: _showCreateListDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create New List'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ])
          : Column(
              children: [
                ..._savedLists.map((list) {
                  final listMap = list as Map<String, dynamic>;
                  final listName =
                      listMap['list_name'] ?? 'Unnamed List';
                  final rawPlaces = listMap['places'] as List? ?? [];
                  final totalCount = rawPlaces.length;
                  return _listTileItem(
                    icon: Icons.bookmark,
                    iconColor: const Color(0xFF4A90D9),
                    title: listName,
                    subtitle:
                        '$totalCount place${totalCount != 1 ? 's' : ''}',
                    onTap: () => _showListDetails(listMap),
                  );
                }),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: GestureDetector(
                    onTap: _showCreateListDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _kPrimaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: _kPrimary, size: 18),
                          SizedBox(width: 6),
                          Text('Create New List',
                              style: TextStyle(
                                  color: _kPrimary,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSettingsPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kPrimary.withOpacity(0.2)),
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('City',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _cities.map((city) {
              final isSelected = _selectedCity == city;
              return GestureDetector(
                onTap: () => setState(() => _selectedCity = city),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? _kPrimary : _kPrimaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    city,
                    style: TextStyle(
                      color: isSelected ? Colors.white : _kPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 8),
          Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _kPrimaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_outlined,
                  color: _kPrimary, size: 20),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notifications',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E))),
                  Text('Receive updates and recommendations',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Switch(
              value: _notificationsEnabled,
              onChanged: (v) =>
                  setState(() => _notificationsEnabled = v),
              activeColor: _kPrimary,
            ),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _savingSettings ? null : _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _savingSettings
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Save Settings',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateListDialog() {
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('New List',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameCtrl,
          decoration: InputDecoration(
            hintText: 'List name (e.g. My Trip to AlUla)',
            filled: true,
            fillColor: _kPrimaryLight,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                final res = await http.post(
                  Uri.parse('$_kBaseUrl/lists'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'user_id': _userId,
                    'list_name': nameCtrl.text.trim(),
                  }),
                );
                if (res.statusCode == 200) {
                  _showSnack('List created ✓', success: true);
                  _loadProfile();
                } else {
                  _showSnack('Failed to create list');
                }
              } catch (_) {
                _showSnack('Connection error');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Widget _listTileItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    String subtitle = '',
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF9FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF1A1A2E))),
                    if (subtitle.isNotEmpty)
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                  ]),
            ),
            if (trailing != null) trailing,
            if (onTap != null)
              const Icon(Icons.chevron_right,
                  color: Colors.grey, size: 18),
          ]),
        ),
      ),
    );
  }

  Widget _emptyState(String msg, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(children: [
          Icon(icon, size: 40, color: _kPrimary.withOpacity(0.3)),
          const SizedBox(height: 8),
          Text(msg,
              style:
                  const TextStyle(color: Colors.grey, fontSize: 14)),
        ]),
      ),
    );
  }
}