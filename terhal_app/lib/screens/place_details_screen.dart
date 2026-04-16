import 'package:flutter/material.dart';
import '../models/destination.dart';
import '../services/api_service.dart';

class PlaceDetailsScreen extends StatefulWidget {
  final String placeName;
  PlaceDetailsScreen({required this.placeName});

  @override
  _PlaceDetailsScreenState createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  final ApiService apiService = ApiService();
  bool isLiked = false;
  int reviewLimit = 5; // Default limit for reviews

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.placeName),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Destination>(
        future: apiService.getDestinationDetails(widget.placeName),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData) {
            return const Center(child: Text("No data found."));
          }

          final place = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Destination Info Section
                Text(place.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Chip(label: Text(place.category), backgroundColor: Colors.teal.shade50),
                    const Spacer(),
                    const Icon(Icons.star, color: Colors.amber, size: 24),
                    Text(" ${place.rating}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Divider(),
                ),
                const Text("About Destination", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
                const SizedBox(height: 10),
                Text(place.description, style: const TextStyle(fontSize: 16, height: 1.5)),

                const SizedBox(height: 30),

                // 2. Like Button Section
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await apiService.toggleLike("user_123", place.name);
                        setState(() { isLiked = !isLiked; });
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Updated Favorites!")));
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Like service unavailable")));
                      }
                    },
                    icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: Colors.white),
                    label: Text(isLiked ? "Saved to Favorites" : "Add to Favorites"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLiked ? Colors.red : Colors.teal,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // 3. Reviews Section (The 5/10/15 Task)
                const Text("User Reviews", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                
                // Toggle Buttons for Limit
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [5, 10, 15].map((limit) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: ChoiceChip(
                      label: Text("Show $limit"),
                      selected: reviewLimit == limit,
                      onSelected: (selected) {
                        setState(() { reviewLimit = limit; });
                      },
                    ),
                  )).toList(),
                ),

                const SizedBox(height: 15),

                // List of Reviews
                FutureBuilder<List<dynamic>>(
                  future: apiService.getReviews(place.name), 
                  builder: (context, reviewSnapshot) {
                    if (reviewSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    // Filter the list based on the selected limit
                    final reviews = reviewSnapshot.data?.take(reviewLimit).toList() ?? [];

                    if (reviews.isEmpty) {
                      return const Text("No reviews yet. Be the first to review!");
                    }

                    return ListView.builder(
                      shrinkWrap: true, // Important for scrollable layouts
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: reviews.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.person)),
                            title: Text(reviews[index]['user_name'] ?? "Anonymous"),
                            subtitle: Text(reviews[index]['comment'] ?? "No comment provided"),
                            trailing: Text("⭐ ${reviews[index]['rating']}"),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}