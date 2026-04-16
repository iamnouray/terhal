import 'package:flutter/material.dart';
import 'screens/place_details_screen.dart'; // هذا السطر يستدعي تعبك وشغلك

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
      // هنا نطلب من التطبيق يفتح على شاشتك فوراً
      home: PlaceDetailsScreen(placeName: "Al-Ula"), 
    );
  }
}
