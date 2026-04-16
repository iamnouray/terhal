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

  // Function to fetch and filter places
  void _fetchPlaces(String value) async {
    try {
      final data = await apiService.searchDestinations(value);
      setState(() {
        if (selectedCategory == "All") {
          results = data;
        } else {
          // Filter results based on the selected category
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
    _fetchPlaces(""); // Load all places initially
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Explore Destinations"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. Search Bar Section
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.teal.withOpacity(0.1),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search for a city or place...",
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search, color: Colors.teal),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _fetchPlaces("");
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _fetchPlaces,
            ),
          ),

          // 2. Category Filters Section
          const Padding(
            padding: EdgeInsets.only(top: 15, left: 15),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Categories", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: ["All", "Historical", "Nature", "Entertainment"].map((category) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: ChoiceChip(
                  label: Text(category),
                  selected: selectedCategory == category,
                  selectedColor: Colors.teal,
                  labelStyle: TextStyle(color: selectedCategory == category ? Colors.white : Colors.black),
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

          // 3. Results List Section
          Expanded(
            child: results.isEmpty
                ? const Center(child: Text("No destinations found. Try another search!"))
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final place = results[index];
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(10),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.teal.shade50, shape: BoxShape.circle),
                            child: const Icon(Icons.map, color: Colors.teal),
                          ),
                          title: Text(place['name'] ?? "Unknown Place", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          subtitle: Text(place['category'] ?? "General"),
                          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.teal, size: 18),
                          onTap: () {
                            // Navigate to the Details Screen (Person 4 task)
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlaceDetailsScreen(placeName: place['name']),
                              ),
                            );
                          },
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