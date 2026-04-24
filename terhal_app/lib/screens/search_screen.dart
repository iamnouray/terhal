import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'place_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiService apiService = ApiService();
  List<dynamic> results = [];
  String selectedCategory = "All";
  final TextEditingController _searchController = TextEditingController();

  // Function to fetch and filter places from the API
  void _fetchPlaces(String value) async {
    try {
      final data = await apiService.searchDestinations(value);
      setState(() {
        if (selectedCategory == "All") {
          results = data;
        } else {
          // Filter results based on the selected category (Person 5 Task)
          results = data.where((p) => p['category'] == selectedCategory).toList();
        }
      });
    } catch (e) {
      debugPrint("Error fetching places: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchPlaces(""); // Load all destinations when the screen opens
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Explore Saudi Arabia"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. Professional Search Bar with Shadow
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.teal.withOpacity(0.05),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search for Al-Ula, Riyadh, Diriyah...",
                  prefixIcon: const Icon(Icons.search, color: Colors.teal),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _fetchPlaces("");
                    },
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onChanged: _fetchPlaces,
              ),
            ),
          ),

          // 2. Category Filters
          const Padding(
            padding: EdgeInsets.only(top: 20, left: 20, bottom: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Popular Categories",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: ["All", "Historical", "Nature", "Entertainment"].map((category) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: ChoiceChip(
                  label: Text(category),
                  selected: selectedCategory == category,
                  selectedColor: Colors.teal,
                  labelStyle: TextStyle(
                    color: selectedCategory == category ? Colors.white : Colors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Colors.teal),
                  ),
                  onSelected: (bool selected) {
                    setState(() {
                      selectedCategory = category;
                      _fetchPlaces(_searchController.text);
                    });
                  },
                ),
              )).toList(),
            ),
          ),

          const SizedBox(height: 10),

          // 3. Destinations List (Professional Image Cards)
          Expanded(
            child: results.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_outlined, size: 70, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("Searching for amazing spots..."),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final place = results[index];
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            // Linking Person 5 to Person 4
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlaceDetailsScreen(placeName: place['name']),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Destination Image
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                child: Image.network(
                                  "https://images.unsplash.com/photo-1589308078059-be1415eab4c3?q=80&w=800",
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    height: 180,
                                    color: Colors.teal.shade50,
                                    child: const Icon(Icons.image, size: 50, color: Colors.teal),
                                  ),
                                ),
                              ),
                              // Destination Details
                              Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          place['name'] ?? "Unknown Place",
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          place['category'] ?? "General",
                                          style: TextStyle(color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                    const Icon(Icons.arrow_forward_ios, color: Colors.teal, size: 20),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}