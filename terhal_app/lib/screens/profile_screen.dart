import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatelessWidget {
  final ApiService apiService = ApiService();
  final String userId = "user_123";

  ProfileScreen({super.key}); // مؤقتاً

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Profile"), backgroundColor: Colors.teal),
      body: FutureBuilder<Map<String, dynamic>>(
        future: apiService.getUserProfile(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData) return const Center(child: Text("Error loading profile"));

          final user = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
                const SizedBox(height: 20),
                Text("Name: ${user['full_name']}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text("Email: ${user['email']}", style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const Divider(height: 40),
                const Text("My Saved Lists", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                // هنا يمكن إضافة قائمة الـ Lists لاحقاً
                const Expanded(child: Center(child: Text("Your saved places will appear here."))),
              ],
            ),
          );
        },
      ),
    );
  }
}