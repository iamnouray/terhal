import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_screen.dart';
import 'place_details_screen.dart';


// ─────────────────────────────────────────
// MAIN SHELL — Bottom Nav (Home + Search)
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
        indicatorColor: const Color(0xFF6B5EA8).withOpacity(0.12),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFF6B5EA8)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search, color: Color(0xFF6B5EA8)),
            label: 'Search',
          ),
          NavigationDestination(
  icon: Icon(Icons.person_outlined),
  selectedIcon: Icon(Icons.person, color: Color(0xFF6B5EA8)),
  label: 'Profile',
),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────
const kPrimary = Color(0xFF6B5EA8);
const kPrimaryLight = Color(0xFFF0EEFF);
const kBaseUrl = 'http://10.0.2.2:8000';

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

  // Mood filter chips
  final List<String> _moods = ['All', 'Relaxed', 'Adventurous', 'Energetic', 'Calm & quiet'];
  int _selectedMood = 0;

  // Category icons
  final Map<String, IconData> _categoryIcons = {
    'restaurant': Icons.restaurant,
    'cafe': Icons.coffee,
    'park': Icons.park,
    'attraction': Icons.attractions,
    'shopping': Icons.shopping_bag,
    'museum': Icons.museum,
  };

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('username') ?? 'Explorer';
    _userId = prefs.getString('user_id') ?? '';
    await _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    setState(() => _isLoading = true);
    try {
      final uri = Uri.parse('$kBaseUrl/recommend/$_userId?top_n=10');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
         _recommendations = List<Map<String, dynamic>>.from(
  data is List ? data : (data['recommendations'] ?? []),
);
        });
      }
    } catch (_) {
      // fallback — show empty state
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _getGreeting();
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ─────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greeting,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF888888),
                              ),
                            ),
                            Text(
                              _username,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                          ],
                        ),
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: kPrimary,
                          child: Text(
                            _username.isNotEmpty ? _username[0].toUpperCase() : 'T',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Search bar shortcut
                    GestureDetector(
                      onTap: () {
                        // navigate to search tab
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.search, color: Color(0xFF888888)),
                            SizedBox(width: 10),
                            Text(
                              'Search destinations, cafes...',
                              style: TextStyle(
                                color: Color(0xFF888888),
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ── Category Cards ──────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Explore by Category',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 90,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildCategoryChip('Restaurants', Icons.restaurant, const Color(0xFFFF6B6B)),
                          _buildCategoryChip('Cafes', Icons.coffee, const Color(0xFF4ECDC4)),
                          _buildCategoryChip('Parks', Icons.park, const Color(0xFF45B7D1)),
                          _buildCategoryChip('Shopping', Icons.shopping_bag, const Color(0xFFF7DC6F)),
                          _buildCategoryChip('Museums', Icons.museum, const Color(0xFFBB8FCE)),
                          _buildCategoryChip('Attractions', Icons.attractions, const Color(0xFF82E0AA)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ── Mood Filter ─────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'For You',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _moods.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final selected = _selectedMood == i;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedMood = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: selected ? kPrimary : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selected ? kPrimary : const Color(0xFFE0E0E0),
                                ),
                              ),
                              child: Text(
                                _moods[i],
                                style: TextStyle(
                                  color: selected ? Colors.white : const Color(0xFF666666),
                                  fontSize: 13,
                                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // ── Recommendations ─────────────────────
            _isLoading
                ? const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(
                        child: CircularProgressIndicator(color: kPrimary),
                      ),
                    ),
                  )
                : _recommendations.isEmpty
                    ? SliverToBoxAdapter(
                        child: _buildEmptyState(),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final place = _recommendations[index];
                              return _buildPlaceCard(place);
                            },
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  Widget _buildCategoryChip(String label, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        // filter by category
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF555555)),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceCard(Map<String, dynamic> place) {
    final name = place['name'] ?? 'Unknown';
    final city = place['city'] ?? '';
    final category = (place['category'] ?? 'attraction').toString().toLowerCase();
    final rating = (place['rating'] ?? 0.0).toDouble();
    final reviews = place['reviews'] ?? 0;
    final price = place['prices'] ?? '';
    final time = place['preferred_time'] ?? '';
    final icon = _categoryIcons[category] ?? Icons.place;

    // pick card accent color based on category
    final Color accent;
    switch (category) {
      case 'restaurant':
        accent = const Color(0xFFFF6B6B);
        break;
      case 'cafe':
        accent = const Color(0xFF4ECDC4);
        break;
      case 'park':
        accent = const Color(0xFF45B7D1);
        break;
      case 'shopping':
        accent = const Color(0xFFF7DC6F);
        break;
      default:
        accent = kPrimary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
         onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PlaceDetailsScreen(place: place),
    ),
  );
},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon thumbnail
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accent, size: 28),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 13,
                            color: Color(0xFF888888),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            city,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF888888),
                            ),
                          ),
                          if (time.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.access_time,
                              size: 13,
                              color: Color(0xFF888888),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              time,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF888888),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Rating
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 15,
                                color: Color(0xFFFFC107),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A2E),
                                ),
                              ),
                              Text(
                                ' ($reviews)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF888888),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Price badge
                          if (price.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: kPrimaryLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                price,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: kPrimary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFFCCCCCC),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.explore_outlined,
            size: 64,
            color: kPrimary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'No recommendations yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete your preferences to get personalized suggestions',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF888888), fontSize: 14),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _fetchRecommendations,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Refresh'),
          ),
        ],
      ),
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

  // Filters
  String _selectedCity = 'All';
  String _selectedCategory = 'All';
  final List<String> _cities = ['All', 'Riyadh', 'Jeddah', 'Abha', 'AlUla', 'Madinah'];
  final List<String> _categories = ['All', 'Restaurant', 'Cafe', 'Park', 'Shopping', 'Museum'];

  // Popular searches
  final List<String> _popular = [
    'Al-Ula Heritage',
    'Riyadh cafes',
    'Jeddah restaurants',
    'Abha nature',
    'Desert safari',
  ];

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });
    try {
      final cityParam = _selectedCity == 'All' ? '' : _selectedCity;
      final catParam = _selectedCategory == 'All' ? '' : _selectedCategory.toLowerCase();
      final uri = Uri.parse(
        '$kBaseUrl/destinations/search?city=$cityParam&category=$catParam',
      );
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final all = List<Map<String, dynamic>>.from(
  data is List ? data : (data['data'] ?? []),
);
        // Client-side filter by query text
        final q = query.toLowerCase();
        setState(() {
          _results = all
              .where((p) =>
                  (p['name'] ?? '').toString().toLowerCase().contains(q) ||
                  (p['city'] ?? '').toString().toLowerCase().contains(q) ||
                  (p['category'] ?? '').toString().toLowerCase().contains(q))
              .toList();
        });
      }
    } catch (_) {
      setState(() => _results = []);
    }
    setState(() => _isSearching = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Search Header ───────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Discover',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Search field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
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
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _results = [];
                                    _hasSearched = false;
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onChanged: (val) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ),

            // ── Filter Row ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      'City',
                      _selectedCity,
                      _cities,
                      (v) => setState(() => _selectedCity = v!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDropdown(
                      'Category',
                      _selectedCategory,
                      _categories,
                      (v) => setState(() => _selectedCategory = v!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => _search(_searchController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Icon(Icons.tune),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Body ────────────────────────────────
            Expanded(
              child: _isSearching
                  ? const Center(
                      child: CircularProgressIndicator(color: kPrimary),
                    )
                  : !_hasSearched
                      ? _buildPopularSearches()
                      : _results.isEmpty
                          ? _buildNoResults()
                          : _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String hint,
    String value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF333333),
          ),
          onChanged: onChanged,
          items: items
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildPopularSearches() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Popular searches',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _popular
                .map(
                  (p) => GestureDetector(
                    onTap: () {
                      _searchController.text = p;
                      _search(p);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.trending_up,
                            size: 14,
                            color: kPrimary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            p,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF444444),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 28),
          const Text(
            'Browse by City',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: [
              _buildCityCard('Riyadh', Icons.location_city, const Color(0xFF6B5EA8)),
              _buildCityCard('Jeddah', Icons.waves, const Color(0xFF2196F3)),
              _buildCityCard('Abha', Icons.landscape, const Color(0xFF4CAF50)),
              _buildCityCard('AlUla', Icons.holiday_village, const Color(0xFFFF9800)),
              _buildCityCard('Madinah', Icons.mosque, const Color(0xFF009688)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCityCard(String city, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCity = city);
        _searchController.text = city;
        _search(city);
      },
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              city,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: kPrimary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'No results found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try a different keyword or filter',
            style: TextStyle(color: Color(0xFF888888)),
          ),
        ],
      ),
    );
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
        final rating = (place['rating'] ?? 0.0).toDouble();
        final price = place['prices'] ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: kPrimaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.place, color: kPrimary, size: 24),
            ),
            title: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Color(0xFF1A1A2E),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 12,
                      color: Color(0xFF888888),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '$city · $category',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: Color(0xFFFFC107),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (price.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 12,
                          color: kPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: Color(0xFFCCCCCC),
            ),
           onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PlaceDetailsScreen(place: place),
    ),
  );
},
          ),
        );
      },
    );
  }
}