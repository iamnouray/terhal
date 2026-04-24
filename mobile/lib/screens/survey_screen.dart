import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  int _currentStep = 0;
  bool _isLoading = false;

  String? _mood;
  String? _visitorType;
  String? _preferredTime;
  String? _activity;
  String? _city;
  double _budget = 200;

  Future<void> _submitSurvey() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      String budgetLevel;
      if (_budget < 150) {
        budgetLevel = '\$';
      } else if (_budget < 350) {
        budgetLevel = '\$\$';
      } else {
        budgetLevel = '\$\$\$';
      }

      final response = await http.put(
        Uri.parse('https://terhal-bapl.onrender.com/users/$userId/preferences'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mood': _mood,
          'visitor_type': _visitorType,
          'preferred_time': _preferredTime,
          'activity': _activity,
          'city': _city,
          'budget': budgetLevel,
          'environment': null,
        }),
      );
      final data = jsonDecode(response.body);
      if (data['error'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'])),
        );
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server connection error')),
      );
    }
    setState(() => _isLoading = false);
  }

  Widget _buildOption(String label, String? selected, Function(String) onTap) {
    final isSelected = selected == label;
    return GestureDetector(
      onTap: () => onTap(label),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6B5EA8) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('How are you feeling today?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        for (final o in ['Relaxed', 'Adventurous', 'Energetic', 'Calm & quiet'])
          _buildOption(o, _mood, (v) => setState(() => _mood = v)),
        const SizedBox(height: 24),
        const Text('Who are you going with?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        for (final o in ['Solo', 'Family', 'Friends', 'Couple'])
          _buildOption(o, _visitorType, (v) => setState(() => _visitorType = v)),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('When is the plan for?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        for (final o in ['Morning', 'Afternoon', 'Evening', 'Late Night'])
          _buildOption(
              o, _preferredTime, (v) => setState(() => _preferredTime = v)),
        const SizedBox(height: 24),
        const Text('What are you in the mood for?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        for (final o in [
          'Breakfast',
          'Lunch / Dinner',
          'Coffee',
          'Shopping',
          'Scenic drive & views'
        ])
          _buildOption(o, _activity, (v) => setState(() => _activity = v)),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Which city?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        for (final o in ['Riyadh', 'Jeddah', 'Abha', 'AlUla', 'Madinah'])
          _buildOption(o, _city,
                  (v) => setState(() => _city = v.toLowerCase())),
        const SizedBox(height: 24),
        const Text('How much is your budget?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Center(
          child: Text(
            '${_budget.round()} SAR',
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
          ),
        ),
        Slider(
          value: _budget,
          min: 50,
          max: 500,
          divisions: 45,
          activeColor: const Color(0xFF6B5EA8),
          onChanged: (v) => setState(() => _budget = v),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = [_buildStep1(), _buildStep2(), _buildStep3()];
    final isLastStep = _currentStep == steps.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  steps.length,
                      (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _currentStep ? 32 : 8,
                    height: 4,
                    decoration: BoxDecoration(
                      color: i == _currentStep
                          ? const Color(0xFF6B5EA8)
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Step ${_currentStep + 1} of ${steps.length}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tell us about your trip!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Text(
                "We'll personalize places for you",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(child: steps[_currentStep]),
              ),
              const SizedBox(height: 16),
              if (_currentStep > 0)
                TextButton(
                  onPressed: () => setState(() => _currentStep--),
                  child: const Text('Back'),
                ),
              if (!isLastStep)
                ElevatedButton(
                  onPressed: () => setState(() => _currentStep++),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B5EA8),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('Continue',
                      style: TextStyle(color: Colors.white)),
                ),
              if (isLastStep)
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _submitSurvey,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B5EA8),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('Done',
                      style: TextStyle(color: Colors.white)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}