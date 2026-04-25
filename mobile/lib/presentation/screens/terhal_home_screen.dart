import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../providers/profile_providers.dart';
import '../providers/session.dart';
import 'explore_screen.dart';

/// Map-first home: greeting, search, map preview, "Plan your trip".
class TerhalHomeScreen extends ConsumerWidget {
  const TerhalHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).valueOrNull;
    final profile = ref.watch(currentUserProfileProvider);
    final name = session?.name ?? 'Traveler';
    final city = profile.maybeWhen(
      data: (u) => u.preferences?['city']?.toString(),
      orElse: () => null,
    ) ??
        'Riyadh';

    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Terhal',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.deepPurple,
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hello, $name 👋',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppColors.textDark),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                            Text(
                              city,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_none_rounded),
                    color: AppColors.textDark,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                readOnly: true,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ExploreScreen(),
                    ),
                  );
                },
                decoration: InputDecoration(
                  hintText: 'Search for a destination, event',
                  prefixIcon: const Icon(Icons.menu_rounded),
                  suffixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Map-style placeholder (swap for google_maps_flutter later).
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFE8E0E6),
                              Color(0xFFD5C9D4),
                              Color(0xFFC4B8C9),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.map_rounded,
                            size: 80,
                            color: AppColors.deepPurple.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 20,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/survey');
                          },
                          icon: const Icon(Icons.route_rounded),
                          label: const Text('Plan Your Trip'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
