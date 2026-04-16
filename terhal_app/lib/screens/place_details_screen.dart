import 'package:flutter/material.dart';
import '../models/destination.dart';
import '../services/api_service.dart';

class PlaceDetailsScreen extends StatefulWidget {
  final String placeName;
  const PlaceDetailsScreen({super.key, required this.placeName});

  @override
  _PlaceDetailsScreenState createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  final ApiService apiService = ApiService();
  final TextEditingController _commentController = TextEditingController();
  bool isLiked = false;
  int reviewLimit = 5;
  double userRating = 5.0;

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
                // 1. معلومات الوجهة الأساسية
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
                const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider()),
                
                const Text("About Destination", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
                const SizedBox(height: 10),
                Text(place.description, style: const TextStyle(fontSize: 16, height: 1.5)),

                const SizedBox(height: 30),

                // 2. أزرار التفاعل (إعجاب وحفظ في القائمة)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // زر الإعجاب (Person 4)
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await apiService.toggleLike("user_123", place.name);
                          setState(() { isLiked = !isLiked; });
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Updated Favorites!")));
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Service unavailable")));
                        }
                      },
                      icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: Colors.white),
                      label: Text(isLiked ? "Liked" : "Like"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLiked ? Colors.red : Colors.teal,
                      ),
                    ),
                    // زر الحفظ في القائمة (Person 4 & 5)
                    OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          await apiService.addToList("user_123", place.name);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Added to My Lists!")));
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to save to list")));
                        }
                      },
                      icon: const Icon(Icons.bookmark_add, color: Colors.teal),
                      label: const Text("Save to List", style: TextStyle(color: Colors.teal)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.teal)),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // 3. عرض المراجعات بنظام 5/10/15 (Person 4)
                const Text("User Reviews", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
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
                FutureBuilder<List<dynamic>>(
                  future: apiService.getReviews(place.name),
                  builder: (context, reviewSnapshot) {
                    if (reviewSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    final reviews = reviewSnapshot.data?.take(reviewLimit).toList() ?? [];
                    if (reviews.isEmpty) return const Text("No reviews yet.");

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: reviews.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.person)),
                            title: Text(reviews[index]['user_name'] ?? "Anonymous"),
                            subtitle: Text(reviews[index]['comment'] ?? ""),
                            trailing: Text("⭐ ${reviews[index]['rating']}"),
                          ),
                        );
                      },
                    );
                  },
                ),

                const Divider(height: 50),

                // 4. نموذج إضافة مراجعة جديدة (Person 4)
                const Text("Share Your Experience", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
                const SizedBox(height: 15),
                TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: "Write your comment...",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text("Rating: ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Slider(
                        value: userRating,
                        min: 1, max: 5, divisions: 4,
                        label: userRating.toInt().toString(),
                        activeColor: Colors.teal,
                        onChanged: (val) => setState(() => userRating = val),
                      ),
                    ),
                    Text("${userRating.toInt()} ⭐", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_commentController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please write a comment")));
                        return;
                      }
                      try {
                        await apiService.addReview(place.name, "Elaf", userRating, _commentController.text);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Review submitted!")));
                        _commentController.clear();
                        setState(() {}); // لتحديث القائمة بعد الإضافة
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to submit review")));
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                    child: const Text("Submit Review"),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}