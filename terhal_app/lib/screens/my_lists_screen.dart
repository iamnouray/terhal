import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MyListsScreen extends StatefulWidget {
  const MyListsScreen({super.key});

  @override
  _MyListsScreenState createState() => _MyListsScreenState();
}

class _MyListsScreenState extends State<MyListsScreen> {
  final ApiService apiService = ApiService();
  final String userId = "user_123";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Saved Lists"), backgroundColor: Colors.teal),
      body: FutureBuilder<List<dynamic>>(
        future: apiService.getUserLists(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final list = snapshot.data ?? [];
          if (list.isEmpty) return const Center(child: Text("Your list is empty."));

          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(Icons.bookmark, color: Colors.teal),
                title: Text(list[index]['destination_name']),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await apiService.removeFromList(userId, list[index]['destination_name']);
                    setState(() {}); // تحديث القائمة بعد الحذف
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}