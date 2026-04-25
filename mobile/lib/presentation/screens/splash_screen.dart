import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../providers/session.dart';

/// Chooses the first route based on stored session + onboarding flag.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _route());
  }

  Future<void> _route() async {
    await ref.read(sessionProvider.notifier).refreshFromStorage();
    if (!mounted) return;

    final session = ref.read(sessionProvider).valueOrNull;
    if (session == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    if (!session.onboardingComplete) {
      Navigator.pushReplacementNamed(context, '/survey');
      return;
    }
    Navigator.pushReplacementNamed(context, '/main');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lavenderLight,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Terhal',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppColors.deepPurple,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
