import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../data/models/destination_model.dart';
import '../../data/models/review_model.dart';
import '../providers/dependencies.dart';
import '../providers/destinations_providers.dart';
import '../providers/profile_providers.dart';
import '../providers/session.dart';
import '../widgets/async_body.dart';

/// Destination detail, reviews, and like action.
class DestinationDetailScreen extends ConsumerWidget {
  const DestinationDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is! DestinationModel) {
      return const Scaffold(
        body: Center(child: Text('Missing destination')),
      );
    }
    final seed = arg;

    final detailAsync = ref.watch(destinationByNameProvider(seed.name));
    final reviewsAsync =
        ref.watch(destinationReviewsProvider(seed.id));
    final likesAsync = ref.watch(myLikesProvider);

    final liked = likesAsync.maybeWhen(
      data: (likes) => likes.any((l) => l.destinationId == seed.id),
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(seed.name),
        actions: [
          IconButton(
            tooltip: liked ? 'Liked' : 'Like',
            onPressed: likesAsync.isLoading
                ? null
                : () => _toggleLike(context, ref, seed, liked),
            icon: Icon(liked ? Icons.favorite : Icons.favorite_border),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AsyncBody<DestinationModel>(
            asyncValue: detailAsync,
            onRetry: () =>
                ref.invalidate(destinationByNameProvider(seed.name)),
            data: (context, d) => _DetailHeader(destination: d),
          ),
          const SizedBox(height: 24),
          Text(
            'Reviews',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          AsyncBody<List<ReviewModel>>(
            asyncValue: reviewsAsync,
            emptyMessage: 'No reviews yet. Be the first to add one.',
            onRetry: () =>
                ref.invalidate(destinationReviewsProvider(seed.id)),
            data: (context, reviews) => Column(
              children: reviews
                  .map(
                    (r) => Card(
                      child: ListTile(
                        title: Text(
                          '${'★' * r.rating}'
                          '${'☆' * (5 - r.rating).clamp(0, 5).toInt()}  '
                          '${r.authorName ?? 'Traveler'}',
                        ),
                        subtitle: Text(r.comment),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.rate_review_outlined),
            label: const Text('Write a review'),
            onPressed: () => _openReviewSheet(context, ref, seed),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleLike(
    BuildContext context,
    WidgetRef ref,
    DestinationModel d,
    bool currentlyLiked,
  ) async {
    final session = ref.read(sessionProvider).valueOrNull;
    if (session == null) return;
    if (currentlyLiked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unlike is not available on this API version.'),
        ),
      );
      return;
    }
    try {
      await ref.read(terhalRepositoryProvider).addLike(
            userId: session.userId,
            destinationId: d.id,
          );
      ref.invalidate(myLikesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to your likes')),
        );
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Future<void> _openReviewSheet(
    BuildContext context,
    WidgetRef ref,
    DestinationModel d,
  ) async {
    final session = ref.read(sessionProvider).valueOrNull;
    if (session == null) return;

    final commentController = TextEditingController();
    var rating = 5;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Rate ${d.name}',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (i) {
                      final star = i + 1;
                      return IconButton(
                        onPressed: () =>
                            setModalState(() => rating = star),
                        icon: Icon(
                          star <= rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                      );
                    }),
                  ),
                  TextField(
                    controller: commentController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Comment',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () async {
                      try {
                        await ref.read(terhalRepositoryProvider).addReview(
                              userId: session.userId,
                              destinationId: d.id,
                              rating: rating,
                              comment: commentController.text.trim(),
                            );
                        ref.invalidate(
                          destinationReviewsProvider(d.id),
                        );
                        ref.invalidate(myReviewsProvider);
                        if (context.mounted) Navigator.pop(context);
                      } on ApiException catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.message)),
                        );
                      }
                    },
                    child: const Text('Submit review'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.destination});

  final DestinationModel destination;

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (destination.city != null) destination.city,
      if (destination.category != null) destination.category,
    ].whereType<String>().join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (meta.isNotEmpty)
          Text(meta, style: Theme.of(context).textTheme.labelLarge),
        if (destination.description != null &&
            destination.description!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(destination.description!),
          ),
      ],
    );
  }
}