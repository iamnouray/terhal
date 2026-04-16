import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/destination.dart';

class ApiService {
  // Base URL for your project's backend on Render
  final String baseUrl = "https://terhal-bapl.onrender.com";

  // 1. Task (Person 4): Fetch details for a specific destination
  Future<Destination> getDestinationDetails(String name) async {
    final response = await http.get(Uri.parse("$baseUrl/destinations/$name"));
    
    if (response.statusCode == 200) {
      // Decode the response using UTF-8 to support Arabic text correctly
      return Destination.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to load destination data from the server');
    }
  }

  // 2. Task (Person 4): Toggle the Like button (Add/Remove Favorite)
  Future<void> toggleLike(String userId, String destId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/likes"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId, "dest_id": destId}),
    );
    
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to send like interaction');
    }
  }

  // 3. Task (Person 4): Fetch reviews for a specific destination
  Future<List<dynamic>> getReviews(String destId) async {
    final response = await http.get(Uri.parse("$baseUrl/reviews/$destId"));
    
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      // Return an empty list if no reviews are found
      return []; 
    }
  }
}