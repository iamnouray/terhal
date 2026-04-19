import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/destination.dart';

class ApiService {
  // Base URL
  final String baseUrl = "https://terhal-bapl.onrender.com";

  // --- دالة تسجيل الدخول (تم تصحيح المسار هنا) ---
  Future<Map<String, dynamic>> login(String email, String password) async {
    // تم تغيير الرابط ليطابق ما هو موجود في routes/users.py
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

  // 1. Task (Person 4): Fetch details for a specific destination
  Future<Destination> getDestinationDetails(String name) async {
    final response = await http.get(Uri.parse("$baseUrl/destinations/$name"));
    
    if (response.statusCode == 200) {
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
      return []; 
    }
  }

  // Task (Person 5): Search destinations by name or category
  Future<List<dynamic>> searchDestinations(String query) async {
    final response = await http.get(Uri.parse("$baseUrl/search?city=$query"));

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['data']; 
    } else {
      return [];
    }
  }

  // 5. Add a New Review (Person 4)
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

  // 6. Get User Profile Data (Person 5)
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final response = await http.get(Uri.parse("$baseUrl/users/$userId"));
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception("Failed to load profile");
    }
  }

  // 7. Get User's Saved Lists (Person 4 & 5)
  Future<List<dynamic>> getUserLists(String userId) async {
    final response = await http.get(Uri.parse("$baseUrl/lists/$userId"));
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      return [];
    }
  }

  // إضافة مكان إلى قائمة (Person 4)
  Future<void> addToList(String userId, String destName) async {
    await http.post(
      Uri.parse("$baseUrl/lists"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId, "destination_name": destName}),
    );
  }

  // حذف مكان من القائمة (Person 4/5)
  Future<void> removeFromList(String userId, String destName) async {
    await http.delete(
      Uri.parse("$baseUrl/lists"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId, "destination_name": destName}),
    );
  }
}