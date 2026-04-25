import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/review_model.dart';
import '../providers/profile_providers.dart';
import '../providers/session.dart';
import '../widgets/async_body.dart';
import 'profile_lists_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider);
    final myReviews = ref.watch(myReviewsProvider);

    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(currentUserProfileProvider);
            ref.invalidate(myReviewsProvider);
            ref.invalidate(myLikesProvider);
            await ref.read(currentUserProfileProvider.future);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: AsyncBody(
                    asyncValue: profile,
                    onRetry: () => ref.invalidate(currentUserProfileProvider),
                    data: (context, user) => Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.lavender.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: AppColors.white,
                            child: Text(
                              user.name.isNotEmpty
                                  ? user.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepPurple,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: const [
                              _Stat(label: 'followers', value: '24'),
                              _Stat(label: 'lists', value: '3'),
                              _Stat(label: 'Following', value: '60'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ProfileListsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.shield_outlined),
                    label: const Text('Saved List'),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _ProfileMenuCard(
                      icon: Icons.history_rounded,
                      title: 'History',
                      subtitle: 'My trips / My bookings',
                      onTap: () {},
                    ),
                    _ProfileMenuCard(
                      icon: Icons.favorite_border_rounded,
                      title: 'Favorites',
                      subtitle: 'Saved places and tours',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ProfileListsScreen(),
                          ),
                        );
                      },
                    ),
                    _ProfileMenuCard(
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      subtitle: 'Language, notifications, more',
                      onTap: () {},
                    ),
                    _ProfileMenuCard(
                      icon: Icons.dark_mode_outlined,
                      title: 'Night mode',
                      subtitle: 'Switch between light and dark mode',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Theme toggle can be wired later.'),
                          ),
                        );
                      },
                    ),
                    _ProfileMenuCard(
                      icon: Icons.logout_rounded,
                      title: 'Sign out',
                      subtitle: 'Log out from this account',
                      onTap: () async {
                        await ref.read(sessionProvider.notifier).logout();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (_) => false,
                          );
                        }
                      },
                    ),
                  ]),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Text(
                    'My reviews',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AsyncBody<List<ReviewModel>>(
                    asyncValue: myReviews,
                    emptyMessage: 'No reviews yet.',
                    onRetry: () => ref.invalidate(myReviewsProvider),
                    data: (context, list) => Column(
                      children: list
                          .map(
                            (r) => Card(
                              child: ListTile(
                                title: Text(
                                  r.comment,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text('${r.rating}/5'),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: profile.maybeWhen(
                  data: (u) {
                    if (u.preferences == null) {
                      return const SizedBox(height: 100);
                    }
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      child: ExpansionTile(
                        title: const Text('API preferences (debug)'),
                        children: [
                          SelectableText(
                            JsonEncoder.withIndent('  ')
                                .convert(u.preferences!),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  },
                  orElse: () => const SizedBox(height: 100),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ProfileMenuCard extends StatelessWidget {
  const _ProfileMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lavenderLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: AppColors.deepPurple),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
