import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/destination_model.dart';
import '../../data/models/user_model.dart';
import '../providers/dependencies.dart';
import '../providers/destinations_providers.dart';
import '../providers/profile_providers.dart';
import '../providers/recommendations_provider.dart';
import '../providers/session.dart';
import '../widgets/async_body.dart';

/// "Smart Guide" — quick tour preferences + recommendations + categories.
class SmartGuideScreen extends ConsumerStatefulWidget {
  const SmartGuideScreen({super.key});

  @override
  ConsumerState<SmartGuideScreen> createState() => _SmartGuideScreenState();
}

class _SmartGuideScreenState extends ConsumerState<SmartGuideScreen> {
  String _timeLabel = 'Afternoon tour (3 hours)';
  String _visitorLabel = 'Family tour';
  String _environmentLabel = 'A historical tour';

  static const _timeApi = {
    'Morning tour (3 hours)': 'Morning',
    'Afternoon tour (3 hours)': 'Afternoon',
    'Evening tour (3 hours)': 'Evening',
    'Late Night tour': 'Late Night',
  };
  static const _visitorApi = {
    'Solo tour': 'Solo',
    'Family tour': 'Family',
    'Friends tour': 'Friends',
    'Couple tour': 'Couple',
  };

  Future<void> _pushPrefsToApi() async {
    final session = ref.read(sessionProvider).valueOrNull;
    if (session == null) return;
    final profile = await ref.read(currentUserProfileProvider.future);
    final prefs = profile.preferences;
    final city = (prefs?['city'] ?? 'riyadh').toString();
    final budget = (prefs?['budget'] ?? r'$$').toString();

    final payload = UserPreferencesPayload(
      city: city,
      visitorType: _visitorApi[_visitorLabel] ?? 'Family',
      preferredTime: _timeApi[_timeLabel] ?? 'Afternoon',
      environment: _environmentLabel,
      budget: budget,
    );

    try {
      await ref.read(terhalRepositoryProvider).updatePreferences(
            session.userId,
            payload,
          );
      ref.invalidate(recommendationsProvider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reco = ref.watch(recommendationsProvider);
    final categories = ref.watch(destinationsListProvider);

    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(recommendationsProvider);
            ref.invalidate(destinationsListProvider);
            await ref.read(recommendationsProvider.future);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    children: [
                      Text(
                        'Smart Guide',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose your preferences and the guide will suggest a '
                        'sightseeing plan for the day.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'choose the tour type',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 12),
                        _TourDropdown(
                          value: _timeLabel,
                          color: AppColors.lavenderLight,
                          items: _timeApi.keys.toList(),
                          onChanged: (v) {
                            setState(() => _timeLabel = v!);
                            _pushPrefsToApi();
                          },
                        ),
                        const SizedBox(height: 10),
                        _TourDropdown(
                          value: _visitorLabel,
                          color: AppColors.lavender,
                          items: _visitorApi.keys.toList(),
                          onChanged: (v) {
                            setState(() => _visitorLabel = v!);
                            _pushPrefsToApi();
                          },
                        ),
                        const SizedBox(height: 10),
                        _TourDropdown(
                          value: _environmentLabel,
                          color: AppColors.deepPurple,
                          textOnDark: true,
                          items: const [
                            'A historical tour',
                            'Nature & outdoors',
                            'Shopping & dining',
                            'Relaxing day',
                          ],
                          onChanged: (v) {
                            setState(() => _environmentLabel = v!);
                            _pushPrefsToApi();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Text(
                    'Suggestions for you',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 220,
                  child: AsyncBody<List<DestinationModel>>(
                    asyncValue: reco,
                    emptyMessage: 'No suggestions yet.',
                    onRetry: () => ref.invalidate(recommendationsProvider),
                    data: (context, list) => ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (context, i) {
                        final d = list[i];
                        return _SuggestionCard(
                          destination: d,
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/destination',
                            arguments: d,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Text(
                        'Popular categories',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () =>
                            ref.invalidate(destinationsListProvider),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 140,
                  child: AsyncBody<List<DestinationModel>>(
                    asyncValue: categories,
                    emptyMessage: 'No categories to show.',
                    onRetry: () => ref.invalidate(destinationsListProvider),
                    data: (context, list) => ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: list.length.clamp(0, 8),
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) {
                        final d = list[i];
                        return _CategoryChip(
                          label: d.category ?? d.name,
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/destination',
                            arguments: d,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TourDropdown extends StatelessWidget {
  const _TourDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.color,
    this.textOnDark = false,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final Color color;
  final bool textOnDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: items.contains(value) ? value : items.first,
            borderRadius: BorderRadius.circular(16),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: textOnDark ? AppColors.white : AppColors.deepPurple,
            ),
            dropdownColor: AppColors.white,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: textOnDark ? AppColors.white : AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
            items: items
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.destination,
    required this.onTap,
  });

  final DestinationModel destination;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          width: 280,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.deepPurple.withValues(alpha: 0.75),
                      AppColors.lavender.withValues(alpha: 0.9),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    destination.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '4.8 · Close to you',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.white,
                            shadows: const [
                              Shadow(color: Colors.black45, blurRadius: 6),
                            ],
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 0.72,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Container(
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.lavenderLight,
                  AppColors.lavender.withValues(alpha: 0.9),
                ],
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.deepPurple,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
