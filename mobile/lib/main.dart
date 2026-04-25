import 'package:flutter/material.dart';

import 'screens/register_screen.dart';
import 'screens/login_screen.dart';
import 'screens/survey_screen.dart';
import 'screens/screens_home_search.dart'; // 👈 الصحيح
import 'screens/profile_screen.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Terhal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B5EA8),
        ),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/register': (context) => const RegisterScreen(),
        '/login': (context) => const LoginScreen(),
        '/survey': (context) => const SurveyScreen(),

        // 👇 يروح لواجهة الجديدة
        '/home': (context) => const MainShell(),
'/profile': (context) => ProfileScreen(),
      },
    );
  }
}