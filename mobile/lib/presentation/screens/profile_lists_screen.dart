import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/like_model.dart';
import '../providers/profile_providers.dart';
import '../widgets/async_body.dart';

/// Saved + Liked lists (likes from API; saved is UI placeholder until backend exists).
class ProfileListsScreen extends ConsumerWidget {
  const ProfileListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likes = ref.watch(myLikesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lists'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Text(
                'Saved List',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              Icon(Icons.menu_rounded, color: AppColors.textMuted),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 56,
                  height: 56,
                  color: AppColors.lavender,
                  child: const Icon(Icons.collections_bookmark_outlined),
                ),
              ),
              title: const Text('My trips'),
              subtitle: const Text('Connect a “saved lists” API when ready'),
              trailing: const Icon(Icons.lock_outline, size: 20),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: AppColors.deepPurple),
              const SizedBox(width: 8),
              Text(
                'Liked List',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 12),
          AsyncBody<List<LikeModel>>(
            asyncValue: likes,
            emptyMessage: 'No liked places yet.',
            onRetry: () => ref.invalidate(myLikesProvider),
            data: (context, list) => Column(
              children: list
                  .map(
                    (l) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.favorite, color: Colors.pinkAccent),
                        title: Text(l.destinationId),
                        subtitle: const Text('Open destination search to explore'),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
