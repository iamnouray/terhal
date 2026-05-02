import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
  setState(() => _isLoading = true);
  try {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/users/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
  'username': _nameController.text.toLowerCase().replaceAll(' ', '_'),
  'name': _nameController.text,
  'email': _emailController.text,
  'password': _passwordController.text,
}),
    );
    print('Register status: ${response.statusCode}'); // ← أضفنا
    print('Register body: ${response.body}'); // ← أضفنا
    if (response.statusCode == 200 || response.statusCode == 201) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.body)), // ← نعرض الخطأ الحقيقي
      );
    }
  } catch (e) {
    print('Register error: $e'); // ← أضفنا
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Server connection error')),
    );
  }
  setState(() => _isLoading = false);
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _register,
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}