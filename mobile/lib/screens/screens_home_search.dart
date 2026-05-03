import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_screen.dart';
import 'place_details_screen.dart';
import 'survey_screen.dart';

const kPrimary = Color(0xFF6B5EA8);
const kPrimaryLight = Color(0xFFF0EEFF);
const kBaseUrl = 'http://10.0.2.2:8000';
// const kBaseUrl = 'http://172.20.10.3:8000'; // جهاز حقيقي

// ─────────────────────────────────────────
// MAIN SHELL
// ─────────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  List<Widget> get _pages => [
        const HomeScreen(),
        const SearchScreen(),
        ProfileScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: kPrimary.withOpacity(0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: kPrimary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search, color: kPrimary),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person, color: kPrimary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// TRIP PLANNER — مع حفظ تلقائي
// ─────────────────────────────────────────
class TripPlannerScreen extends StatefulWidget {
  const TripPlannerScreen({super.key});

  @override
  State<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends State<TripPlannerScreen> {
  static const _prefsKey = 'trip_planner_data';

  final List<Map<String, dynamic>> _timeSlots = [
    {
      'label': 'Morning',
      'icon': Icons.wb_sunny_outlined,
      'color': const Color(0xFFFF9800),
      'places': <Map<String, dynamic>>[],
      'timeKey': 'Morning',
    },
    {
      'label': 'Afternoon',
      'icon': Icons.wb_cloudy_outlined,
      'color': const Color(0xFF4ECDC4),
      'places': <Map<String, dynamic>>[],
      'timeKey': 'Afternoon',
    },
    {
      'label': 'Evening',
      'icon': Icons.nights_stay_outlined,
      'color': const Color(0xFF6B5EA8),
      'places': <Map<String, dynamic>>[],
      'timeKey': 'Evening',
    },
    {
      'label': 'Late Night',
      'icon': Icons.dark_mode_outlined,
      'color': const Color(0xFF1A1A2E),
      'places': <Map<String, dynamic>>[],
      'timeKey': 'Late Night',
    },
  ];

  bool _loadingData = true;

  @override
  void initState() {
    super.initState();
    _loadSavedTrip();
  }

  // ── تحميل الرحلة المحفوظة ────────────────
  Future<void> _loadSavedTrip() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        final saved = jsonDecode(raw) as Map<String, dynamic>;
        for (final slot in _timeSlots) {
          final key = slot['timeKey'] as String;
          if (saved.containsKey(key)) {
            final list = saved[key] as List<dynamic>;
            slot['places'] = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          }
        }
      }
    } catch (e) {
      debugPrint('Load trip error: $e');
    }
    if (mounted) setState(() => _loadingData = false);
  }

  // ── حفظ الرحلة تلقائياً ──────────────────
  Future<void> _saveTrip() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = <String, dynamic>{};
      for (final slot in _timeSlots) {
        data[slot['timeKey'] as String] = slot['places'];
      }
      await prefs.setString(_prefsKey, jsonEncode(data));
    } catch (e) {
      debugPrint('Save trip error: $e');
    }
  }

  // ── مسح الرحلة ───────────────────────────
  Future<void> _clearTrip() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear Trip?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('This will remove all places from your trip plan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        for (final slot in _timeSlots) {
          (slot['places'] as List).clear();
        }
      });
      await _saveTrip();
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPlacesByTime(String timeKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';
      final encodedTime = Uri.encodeComponent(timeKey);
      final uri = Uri.parse('$kBaseUrl/recommend/$userId?top_n=20&preferred_time=$encodedTime');
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data is List ? data : (data['recommendations'] ?? data['data'] ?? []);
        return List<Map<String, dynamic>>.from(list);
      }
    } catch (e) {
      debugPrint('Fetch error: $e');
    }
    return [];
  }

  void _openPlacePicker(int slotIndex) {
    final slot = _timeSlots[slotIndex];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PlacePickerSheet(
        timeKey: slot['timeKey'] as String,
        label: slot['label'] as String,
        color: slot['color'] as Color,
        icon: slot['icon'] as IconData,
        alreadyAdded: List<Map<String, dynamic>>.from(slot['places'] as List),
        fetchPlaces: _fetchPlacesByTime,
        onAdd: (place) async {
          setState(() {
            final places = _timeSlots[slotIndex]['places'] as List<Map<String, dynamic>>;
            if (!places.any((p) => p['name'] == place['name'])) {
              places.add(place);
            }
          });
          await _saveTrip(); // ← حفظ فوري
        },
      ),
    );
  }

  void _removePlace(int slotIndex, int placeIndex) async {
    setState(() {
      (_timeSlots[slotIndex]['places'] as List<Map<String, dynamic>>).removeAt(placeIndex);
    });
    await _saveTrip(); // ← حفظ بعد الحذف
  }

  int get _totalPlaces => _timeSlots.fold(0, (sum, s) => sum + (s['places'] as List).length);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Plan Your Trip',
              style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.w700, fontSize: 18)),
          if (_totalPlaces > 0)
            Text('$_totalPlaces place${_totalPlaces != 1 ? 's' : ''} added',
                style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
        ]),
        actions: [
          if (_totalPlaces > 0)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _clearTrip,
              tooltip: 'Clear all',
            ),
        ],
      ),
      body: _loadingData
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : Column(children: [
              // ── Banner: محفوظ تلقائياً ────────────
              if (_totalPlaces > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  color: kPrimary.withOpacity(0.06),
                  child: Row(children: [
                    const Icon(Icons.check_circle, color: kPrimary, size: 16),
                    const SizedBox(width: 8),
                    const Text('Your trip is saved automatically',
                        style: TextStyle(fontSize: 13, color: kPrimary, fontWeight: FontWeight.w500)),
                  ]),
                ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _timeSlots.length,
                  itemBuilder: (context, i) {
                    final slot = _timeSlots[i];
                    final places = slot['places'] as List<Map<String, dynamic>>;
                    final color = slot['color'] as Color;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.08),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          child: Row(children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                              child: Icon(slot['icon'] as IconData, color: color, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(slot['label'] as String,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: places.isNotEmpty ? color.withOpacity(0.15) : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${places.length} place${places.length != 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: places.isNotEmpty ? color : Colors.grey,
                                ),
                              ),
                            ),
                          ]),
                        ),

                        // Places list
                        if (places.isNotEmpty)
                          ...places.asMap().entries.map((entry) {
                            final pi = entry.key;
                            final place = entry.value;
                            final placeName = place['name'] ?? '';
                            final placeCity = place['city'] ?? '';
                            final rating = (place['rating'] ?? 0.0);
                            final ratingVal = rating is num ? rating.toDouble() : 0.0;

                            return Container(
                              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: color.withOpacity(0.15)),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                                  child: Center(
                                    child: Text('${pi + 1}',
                                        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(placeName,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
                                  Row(children: [
                                    if (placeCity.isNotEmpty) ...[
                                      const Icon(Icons.location_on, size: 11, color: Color(0xFF888888)),
                                      const SizedBox(width: 2),
                                      Text(placeCity, style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                                    ],
                                    if (ratingVal > 0) ...[
                                      const SizedBox(width: 8),
                                      const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFFC107)),
                                      Text(ratingVal.toStringAsFixed(1),
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                                    ],
                                  ]),
                                ])),
                                IconButton(
                                  onPressed: () => _removePlace(i, pi),
                                  icon: Icon(Icons.close, size: 18, color: color.withOpacity(0.6)),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ]),
                            );
                          }),

                        // Empty state
                        if (places.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Column(children: [
                              Icon(slot['icon'] as IconData, size: 32, color: color.withOpacity(0.3)),
                              const SizedBox(height: 6),
                              Text('No places added yet',
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                            ]),
                          ),

                        // Add button
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                          child: GestureDetector(
                            onTap: () => _openPlacePicker(i),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: color.withOpacity(0.2)),
                              ),
                              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(Icons.add, color: color, size: 18),
                                const SizedBox(width: 6),
                                Text('Add Place', style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
                              ]),
                            ),
                          ),
                        ),
                      ]),
                    );
                  },
                ),
              ),
            ]),
    );
  }
}

// ─────────────────────────────────────────
// PLACE PICKER BOTTOM SHEET
// ─────────────────────────────────────────
class _PlacePickerSheet extends StatefulWidget {
  final String timeKey;
  final String label;
  final Color color;
  final IconData icon;
  final List<Map<String, dynamic>> alreadyAdded;
  final Future<List<Map<String, dynamic>>> Function(String) fetchPlaces;
  final void Function(Map<String, dynamic>) onAdd;

  const _PlacePickerSheet({
    required this.timeKey,
    required this.label,
    required this.color,
    required this.icon,
    required this.alreadyAdded,
    required this.fetchPlaces,
    required this.onAdd,
  });

  @override
  State<_PlacePickerSheet> createState() => _PlacePickerSheetState();
}

class _PlacePickerSheetState extends State<_PlacePickerSheet> {
  List<Map<String, dynamic>> _places = [];
  bool _loading = true;
  final Set<String> _addedNames = {};

  @override
  void initState() {
    super.initState();
    _addedNames.addAll(widget.alreadyAdded.map((p) => p['name']?.toString() ?? ''));
    _load();
  }

  Future<void> _load() async {
    final result = await widget.fetchPlaces(widget.timeKey);
    if (mounted) setState(() { _places = result; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: Color(0xFFF8F7FF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(children: [
        Container(
          margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(children: [
            Container(width: 44, height: 44,
                decoration: BoxDecoration(color: widget.color.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(widget.icon, color: widget.color, size: 22)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Add to ${widget.label}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
              Text('Places open during ${widget.label}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
            ]),
            const Spacer(),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Color(0xFF888888)),
            ),
          ]),
        ),
        const Divider(height: 1),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: kPrimary))
              : _places.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.explore_off_outlined, size: 52, color: kPrimary.withOpacity(0.3)),
                      const SizedBox(height: 12),
                      const Text('No places found for this time',
                          style: TextStyle(color: Color(0xFF888888))),
                    ]))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: _places.length,
                      itemBuilder: (ctx, i) {
                        final place = _places[i];
                        final name = place['name'] ?? 'Unknown';
                        final city = place['city'] ?? '';
                        final category = place['category'] ?? '';
                        final rawRating = place['rating'];
                        final rating = rawRating is num
                            ? rawRating.toDouble()
                            : double.tryParse(rawRating?.toString() ?? '') ?? 0.0;
                        final price = place['prices'] ?? '';
                        final isAdded = _addedNames.contains(name.toString());

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: isAdded ? widget.color.withOpacity(0.05) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: isAdded ? Border.all(color: widget.color.withOpacity(0.35), width: 1.5) : null,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            leading: Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                  color: widget.color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Icon(widget.icon, color: widget.color, size: 22),
                            ),
                            title: Text(name,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1A1A2E))),
                            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const SizedBox(height: 2),
                              Text('$city · $category',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                              const SizedBox(height: 4),
                              Row(children: [
                                const Icon(Icons.star_rounded, size: 13, color: Color(0xFFFFC107)),
                                const SizedBox(width: 2),
                                Text(rating.toStringAsFixed(1),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                if (price.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Text(price, style: const TextStyle(
                                      fontSize: 12, color: kPrimary, fontWeight: FontWeight.w600)),
                                ],
                              ]),
                            ]),
                            trailing: isAdded
                                ? Icon(Icons.check_circle, color: widget.color, size: 26)
                                : Icon(Icons.add_circle_outline, color: widget.color, size: 26),
                            onTap: isAdded ? null : () {
                              widget.onAdd(place);
                              setState(() => _addedNames.add(name.toString()));
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('$name added ✓'),
                                duration: const Duration(seconds: 1),
                                backgroundColor: widget.color,
                                behavior: SnackBarBehavior.floating,
                              ));
                            },
                          ),
                        );
                      },
                    ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────
// HOME SCREEN
// ─────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _username = '';
  String _userId = '';
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = true;
  String? _errorMsg;

  final List<String> _moods = ['All', 'Relaxed', 'Adventurous', 'Energetic', 'Calm & quiet'];
  int _selectedMood = 0;

  final Map<String, IconData> _categoryIcons = {
    'restaurant': Icons.restaurant,
    'cafe': Icons.coffee,
    'park': Icons.park,
    'attraction': Icons.attractions,
    'shopping': Icons.shopping_bag,
    'museum': Icons.museum,
    'entertainment': Icons.theater_comedy,
  };

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? 'Explorer';
      _userId = prefs.getString('user_id') ?? '';
    });
    await _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    if (_userId.isEmpty) {
      setState(() { _isLoading = false; _errorMsg = 'No user ID found'; });
      return;
    }
    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      final uri = Uri.parse('$kBaseUrl/recommend/$_userId?top_n=10');
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        List<dynamic> rawList = [];
        if (data is List) {
          rawList = data;
        } else if (data is Map) {
          rawList = data['recommendations'] ?? data['data'] ?? data['results'] ?? [];
        }
        setState(() {
          _recommendations = rawList.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() { _isLoading = false; _errorMsg = 'Server error: ${res.statusCode}'; });
      }
    } catch (e) {
      setState(() { _isLoading = false; _errorMsg = 'Connection failed'; });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_getGreeting(), style: const TextStyle(fontSize: 14, color: Color(0xFF888888))),
                      Text(_username, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                    ]),
                    CircleAvatar(
                      radius: 22, backgroundColor: kPrimary,
                      child: Text(_username.isNotEmpty ? _username[0].toUpperCase() : 'T',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
                    ),
                    child: const Row(children: [
                      Icon(Icons.search, color: Color(0xFF888888)),
                      SizedBox(width: 10),
                      Text('Search destinations, cafes...', style: TextStyle(color: Color(0xFF888888), fontSize: 15)),
                    ]),
                  ),
                  const SizedBox(height: 24),
                ]),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Update Preferences',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const SurveyScreen()));
                      _fetchRecommendations();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6B5EA8), Color(0xFF8B7FD4)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Row(children: [
                        Container(width: 48, height: 48,
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                            child: const Icon(Icons.tune_rounded, color: Colors.white, size: 24)),
                        const SizedBox(width: 14),
                        const Expanded(child: Text('Retake the Survey',
                            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 24),
                ]),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Plan Your Trip',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TripPlannerScreen())),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Row(children: [
                        ...[
                          {'icon': Icons.wb_sunny_outlined, 'color': const Color(0xFFFF9800), 'label': 'Morning'},
                          {'icon': Icons.wb_cloudy_outlined, 'color': const Color(0xFF4ECDC4), 'label': 'Afternoon'},
                          {'icon': Icons.nights_stay_outlined, 'color': const Color(0xFF6B5EA8), 'label': 'Evening'},
                          {'icon': Icons.dark_mode_outlined, 'color': const Color(0xFF1A1A2E), 'label': 'Late Night'},
                        ].map((slot) => Expanded(child: Column(children: [
                          Container(width: 44, height: 44,
                              decoration: BoxDecoration(color: (slot['color'] as Color).withOpacity(0.12), shape: BoxShape.circle),
                              child: Icon(slot['icon'] as IconData, color: slot['color'] as Color, size: 20)),
                          const SizedBox(height: 6),
                          Text(slot['label'] as String,
                              style: const TextStyle(fontSize: 10, color: Color(0xFF888888), fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center),
                        ]))),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios, color: Color(0xFFCCCCCC), size: 16),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 24),
                ]),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('For You',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _moods.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final selected = _selectedMood == i;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedMood = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected ? kPrimary : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: selected ? kPrimary : const Color(0xFFE0E0E0)),
                            ),
                            child: Text(_moods[i], style: TextStyle(
                              color: selected ? Colors.white : const Color(0xFF666666),
                              fontSize: 13,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            )),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ]),
              ),
            ),

            if (_isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: CircularProgressIndicator(color: kPrimary)),
                ),
              )
            else if (_errorMsg != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(children: [
                    Icon(Icons.wifi_off_outlined, size: 48, color: kPrimary.withOpacity(0.3)),
                    const SizedBox(height: 12),
                    Text(_errorMsg!, style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchRecommendations,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary, foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Try Again'),
                    ),
                  ]),
                ),
              )
            else if (_recommendations.isEmpty)
              SliverToBoxAdapter(child: _buildEmptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildPlaceCard(_recommendations[index]),
                    childCount: _recommendations.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceCard(Map<String, dynamic> place) {
    final name = place['name'] ?? 'Unknown';
    final city = place['city'] ?? '';
    final category = (place['category'] ?? 'attraction').toString().toLowerCase();
    final rawRating = place['rating'];
    final rating = rawRating is num ? rawRating.toDouble() : double.tryParse(rawRating?.toString() ?? '') ?? 0.0;
    final rawReviews = place['reviews'];
    final reviews = rawReviews is num ? rawReviews.toInt() : int.tryParse(rawReviews?.toString() ?? '') ?? 0;
    final price = place['prices'] ?? '';
    final time = place['preferred_time'] ?? '';
    final icon = _categoryIcons[category] ?? Icons.place;

    final Color accent;
    switch (category) {
      case 'restaurant': accent = const Color(0xFFFF6B6B); break;
      case 'cafe': accent = const Color(0xFF4ECDC4); break;
      case 'park': accent = const Color(0xFF45B7D1); break;
      case 'shopping': accent = const Color(0xFFF7DC6F); break;
      case 'entertainment': accent = const Color(0xFFBB8FCE); break;
      default: accent = kPrimary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlaceDetailsScreen(place: place))),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(width: 60, height: 60,
                  decoration: BoxDecoration(color: accent.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                  child: Icon(icon, color: accent, size: 28)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on, size: 13, color: Color(0xFF888888)),
                  const SizedBox(width: 2),
                  Text(city, style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
                  if (time.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.access_time, size: 13, color: Color(0xFF888888)),
                    const SizedBox(width: 2),
                    Flexible(child: Text(time, style: const TextStyle(fontSize: 13, color: Color(0xFF888888)), overflow: TextOverflow.ellipsis)),
                  ],
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.star_rounded, size: 15, color: Color(0xFFFFC107)),
                  const SizedBox(width: 2),
                  Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
                  Text(' ($reviews)', style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                  const Spacer(),
                  if (price.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(8)),
                      child: Text(price, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kPrimary)),
                    ),
                ]),
              ])),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(children: [
        Icon(Icons.explore_outlined, size: 64, color: kPrimary.withOpacity(0.3)),
        const SizedBox(height: 16),
        const Text('No recommendations yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 8),
        const Text('Complete your preferences to get personalized suggestions',
            textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF888888), fontSize: 14)),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _fetchRecommendations,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Refresh'),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────
// SEARCH SCREEN
// ─────────────────────────────────────────
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  String _selectedCity = 'All';
  String _selectedCategory = 'All';
  final List<String> _cities = ['All', 'Riyadh', 'Jeddah', 'Abha', 'AlUla', 'Madinah'];
  final List<String> _categories = ['All', 'Restaurant', 'Cafe', 'Park', 'Shopping', 'Museum'];
  final List<String> _popular = [
    'Al-Ula Heritage', 'Riyadh cafes', 'Jeddah restaurants', 'Abha nature', 'Desert safari',
  ];

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() { _isSearching = true; _hasSearched = true; });
    try {
      final cityParam = _selectedCity == 'All' ? '' : _selectedCity;
      final catParam = _selectedCategory == 'All' ? '' : _selectedCategory.toLowerCase();
      final uri = Uri.parse('$kBaseUrl/destinations/search?city=$cityParam&category=$catParam');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final all = List<Map<String, dynamic>>.from(data is List ? data : (data['data'] ?? []));
        final q = query.toLowerCase();
        setState(() {
          _results = all.where((p) =>
            (p['name'] ?? '').toString().toLowerCase().contains(q) ||
            (p['city'] ?? '').toString().toLowerCase().contains(q) ||
            (p['category'] ?? '').toString().toLowerCase().contains(q)
          ).toList();
        });
      }
    } catch (e) {
      setState(() => _results = []);
    }
    setState(() => _isSearching = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Discover', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 2))],
                ),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: _search,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search places, cities...',
                    hintStyle: const TextStyle(color: Color(0xFFBBBBBB)),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF888888)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Color(0xFF888888)),
                            onPressed: () { _searchController.clear(); setState(() { _results = []; _hasSearched = false; }); })
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onChanged: (val) => setState(() {}),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Expanded(child: _buildDropdown('City', _selectedCity, _cities, (v) => setState(() => _selectedCity = v!))),
              const SizedBox(width: 10),
              Expanded(child: _buildDropdown('Category', _selectedCategory, _categories, (v) => setState(() => _selectedCategory = v!))),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => _search(_searchController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Icon(Icons.tune),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator(color: kPrimary))
                : !_hasSearched ? _buildPopularSearches()
                : _results.isEmpty ? _buildNoResults()
                : _buildResults(),
          ),
        ]),
      ),
    );
  }

  Widget _buildDropdown(String hint, String value, List<String> items, void Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8E8E8))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value, isExpanded: true,
          style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
          onChanged: onChanged,
          items: items.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
        ),
      ),
    );
  }

  Widget _buildPopularSearches() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Popular searches', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: _popular.map((p) => GestureDetector(
          onTap: () { _searchController.text = p; _search(p); },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE0E0E0))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.trending_up, size: 14, color: kPrimary),
              const SizedBox(width: 6),
              Text(p, style: const TextStyle(fontSize: 13, color: Color(0xFF444444))),
            ]),
          ),
        )).toList()),
        const SizedBox(height: 28),
        const Text('Browse by City', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 2.2,
          children: [
            _buildCityCard('Riyadh', Icons.location_city, const Color(0xFF6B5EA8)),
            _buildCityCard('Jeddah', Icons.waves, const Color(0xFF2196F3)),
            _buildCityCard('Abha', Icons.landscape, const Color(0xFF4CAF50)),
            _buildCityCard('AlUla', Icons.holiday_village, const Color(0xFFFF9800)),
            _buildCityCard('Madinah', Icons.mosque, const Color(0xFF009688)),
          ],
        ),
      ]),
    );
  }

  Widget _buildCityCard(String city, IconData icon, Color color) {
    return GestureDetector(
      onTap: () { setState(() => _selectedCity = city); _searchController.text = city; _search(city); },
      child: Container(
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.2))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(city, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.search_off, size: 64, color: kPrimary.withOpacity(0.3)),
      const SizedBox(height: 16),
      const Text('No results found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
      const SizedBox(height: 8),
      const Text('Try a different keyword or filter', style: TextStyle(color: Color(0xFF888888))),
    ]));
  }

  Widget _buildResults() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final place = _results[index];
        final name = place['name'] ?? 'Unknown';
        final city = place['city'] ?? '';
        final category = (place['category'] ?? 'attraction').toString();
        final rawRating = place['rating'];
        final rating = rawRating is num ? rawRating.toDouble() : double.tryParse(rawRating?.toString() ?? '') ?? 0.0;
        final price = place['prices'] ?? '';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(width: 48, height: 48,
                decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.place, color: kPrimary, size: 24)),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1A1A2E))),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.location_on, size: 12, color: Color(0xFF888888)),
                const SizedBox(width: 2),
                Text('$city · $category', style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFC107)),
                const SizedBox(width: 2),
                Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                if (price.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(price, style: const TextStyle(fontSize: 12, color: kPrimary, fontWeight: FontWeight.w600)),
                ],
              ]),
            ]),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlaceDetailsScreen(place: place))),
          ),
        );
      },
    );
  }
}