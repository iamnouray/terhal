import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_model.dart';
import '../providers/dependencies.dart';
import '../providers/session.dart';

/// Onboarding survey — matches design steps; submits [PUT /users/{id}/preferences].
class SurveyScreen extends ConsumerStatefulWidget {
  const SurveyScreen({super.key});

  @override
  ConsumerState<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends ConsumerState<SurveyScreen> {
  int _step = 0;
  bool _loading = false;

  String? _mood;
  String? _visitorType;
  String? _preferredTime;
  String? _activity;
  String? _city;
  double _budget = 400;

  String _budgetSymbol() {
    if (_budget < 150) return r'$';
    if (_budget < 350) return r'$$';
    return r'$$$';
  }

  String _environmentValue() {
    final parts = <String>[];
    if (_mood != null) parts.add(_mood!);
    if (_activity != null) parts.add(_activity!);
    return parts.join(' · ');
  }

  Future<void> _submit() async {
    final session = ref.read(sessionProvider).valueOrNull;
    if (session == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in again.')),
      );
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    if (_visitorType == null ||
        _preferredTime == null ||
        _city == null ||
        (_mood == null && _activity == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all questions before continuing.'),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final payload = UserPreferencesPayload(
        city: _city!,
        visitorType: _visitorType!,
        preferredTime: _preferredTime!,
        environment: _environmentValue(),
        budget: _budgetSymbol(),
      );

      await ref.read(terhalRepositoryProvider).updatePreferences(
            session.userId,
            payload,
          );

      await ref.read(sessionProvider.notifier).setOnboardingComplete(true);

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/main', (_) => false);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _skipForNow() async {
    await ref.read(sessionProvider.notifier).setOnboardingComplete(true);
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/main', (_) => false);
  }

  Widget _progressBar() {
    return Row(
      children: List.generate(3, (i) {
        final filled = i <= _step;
        return Expanded(
          child: Container(
            height: 6,
            margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
            decoration: BoxDecoration(
              color: filled
                  ? AppColors.deepPurple
                  : AppColors.lavender.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }),
    );
  }

  Widget _radioRow(String label, String? group, void Function(String) onPick) {
    final selected = group == label;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected
            ? AppColors.deepPurple
            : AppColors.lavender.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => setState(() => onPick(label)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? AppColors.white : AppColors.deepPurple,
                      width: 2,
                    ),
                    color: selected ? AppColors.white : Colors.transparent,
                  ),
                  child: selected
                      ? const Icon(Icons.circle, size: 12, color: AppColors.deepPurple)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.white : AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = [_step1(), _step2(), _step3()];
    final isLast = _step == 2;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _progressBar(),
              const SizedBox(height: 20),
              Text(
                'Tell us about your trip!',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                "We'll personalize places for you",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Expanded(child: SingleChildScrollView(child: steps[_step])),
              if (_step == 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _skipForNow,
                      child: const Text('Skip for now'),
                    ),
                    FilledButton(
                      onPressed: () => setState(() => _step++),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                      ),
                      child: const Text('continue'),
                    ),
                  ],
                )
              else if (!isLast)
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => setState(() => _step++),
                    child: const Text('Next'),
                  ),
                )
              else if (_loading)
                const Center(child: CircularProgressIndicator())
              else ...[
                OutlinedButton(
                  onPressed: _submit,
                  child: const Text('Done'),
                ),
                TextButton(
                  onPressed: () => setState(() => _step--),
                  child: const Text('Back'),
                ),
              ],
              if (_step > 0 && !isLast)
                TextButton(
                  onPressed: () => setState(() => _step--),
                  child: const Text('Back'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _step1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('How are you feeling today?', style: _heading(context)),
        const SizedBox(height: 10),
        for (final o in ['Relaxed', 'Adventurous', 'Energetic', 'Calm & quiet'])
          _radioRow(o, _mood, (v) => _mood = v),
        const SizedBox(height: 18),
        Text('Who are you going with?', style: _heading(context)),
        const SizedBox(height: 10),
        for (final o in ['Solo', 'Family', 'Friends', 'Couple'])
          _radioRow(o, _visitorType, (v) => _visitorType = v),
      ],
    );
  }

  Widget _step2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('When is the plan for ?', style: _heading(context)),
        const SizedBox(height: 10),
        for (final o in ['Morning', 'Afternoon', 'Evening', 'Late Night'])
          _radioRow(o, _preferredTime, (v) => _preferredTime = v),
        const SizedBox(height: 18),
        Text('What Are You in the Mood For?', style: _heading(context)),
        const SizedBox(height: 10),
        for (final o in [
          'Breakfast',
          'Lunch / Dinner',
          'Coffee',
          'Shopping',
          'Scenic drive & views',
        ])
          _radioRow(o, _activity, (v) => _activity = v),
      ],
    );
  }

  Widget _step3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Which city?', style: _heading(context)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in ['Riyadh', 'Jeddah', 'Abha', 'AlUla', 'Madinah'])
              FilterChip(
                label: Text(o),
                selected: _city == o.toLowerCase(),
                onSelected: (_) =>
                    setState(() => _city = o.toLowerCase()),
                selectedColor: AppColors.deepPurple.withValues(alpha: 0.2),
                checkmarkColor: AppColors.deepPurple,
              ),
          ],
        ),
        const SizedBox(height: 28),
        Text('How much is Your Budget?', style: _heading(context)),
        const SizedBox(height: 16),
        Text(
          '${_budget.round()} ﷼',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.deepPurple,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: () => setState(
                () => _budget = (_budget - 25).clamp(50, 800),
              ),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.budgetGreen,
                  inactiveTrackColor: AppColors.lavender,
                  thumbColor: AppColors.deepPurple,
                  overlayColor:
                      AppColors.deepPurple.withValues(alpha: 0.12),
                ),
                child: Slider(
                  value: _budget,
                  min: 50,
                  max: 800,
                  onChanged: (v) => setState(() => _budget = v),
                ),
              ),
            ),
            IconButton(
              onPressed: () => setState(
                () => _budget = (_budget + 25).clamp(50, 800),
              ),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ],
    );
  }

  TextStyle? _heading(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          );
}
