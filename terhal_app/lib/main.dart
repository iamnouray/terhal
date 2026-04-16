import 'package:flutter/material.dart';
import 'screens/search_screen.dart';
void main() {
  runApp(const TerhalApp());
}

class TerhalApp extends StatelessWidget {
  const TerhalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Terhal - ترحال',
      debugShowCheckedModeBanner: false, // لإخفاء علامة Debug الحمراء
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal), // ألوان هوية ترحال
        useMaterial3: true,
      ),
      // Change this in main.dart
     home: SearchScreen(),
    );
  }
}
