import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/destination.dart';

class ApiService {
  // Base URL
  final String baseUrl = "https://terhal-bapl.onrender.com";

  // --- User Login ---
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse("$baseUrl/users/login");
    
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      print("Login Status: ${response.statusCode}");
      print("Login Response: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } catch (e) {
      print("💥 Login Error: $e");
      throw Exception('Connection error: $e');
    }
  }

  // 1. Fetch details for a specific destination
  Future<Destination> getDestinationDetails(String name) async {
    // Corrected path based on your router prefix /destinations
    final response = await http.get(Uri.parse("$baseUrl/destinations/$name"));
    
    if (response.statusCode == 200) {
      return Destination.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to load destination data from the server');
    }
  }

  // 2. Toggle the Like button (Add/Remove Favorite)
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

  // 3. Fetch reviews for a specific destination
  Future<List<dynamic>> getReviews(String destId) async {
    final response = await http.get(Uri.parse("$baseUrl/reviews/$destId"));
    
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      return []; 
    }
  }

  // 4. Search destinations by name or category
  Future<List<dynamic>> searchDestinations(String query) async {
    // IMPORTANT FIX: Added /destinations/ prefix to match your router
    final response = await http.get(Uri.parse("$baseUrl/destinations/search?city=$query"));

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['data']; 
    } else {
      return [];
    }
  }

  // 5. Add a New Review
  Future<void> addReview(String destId, String userName, double rating, String comment) async {
    final response = await http.post(
      Uri.parse("$baseUrl/reviews/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "destination_id": destId,
        "user_name": userName,
        "rating": rating,
        "comment": comment
      }),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception("Failed to post review");
    }
  }

  // 6. Get User Profile Data
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final response = await http.get(Uri.parse("$baseUrl/users/$userId"));
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception("Failed to load profile");
    }
  }

  // 7. Get User's Saved Lists
  Future<List<dynamic>> getUserLists(String userId) async {
    final response = await http.get(Uri.parse("$baseUrl/lists/$userId"));
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      return [];
    }
  }

  // Add a place to list
  Future<void> addToList(String userId, String destName) async {
    await http.post(
      Uri.parse("$baseUrl/lists"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId, "destination_name": destName}),
    );
  }

  // Remove a place from list
  Future<void> removeFromList(String userId, String destName) async {
    await http.delete(
      Uri.parse("$baseUrl/lists"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId, "destination_name": destName}),
    );
  }
}