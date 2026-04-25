import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/destination_model.dart';
import '../../data/models/review_model.dart';
import 'dependencies.dart';
import 'session.dart';

/// All destinations (browse).
final destinationsListProvider =
    FutureProvider.autoDispose<List<DestinationModel>>((ref) {
  return ref.watch(terhalRepositoryProvider).getDestinations();
});

/// Search by optional city and category query params.
final destinationSearchProvider = FutureProvider.autoDispose
    .family<List<DestinationModel>, ({String? city, String? category})>(
        (ref, params) {
  return ref.watch(terhalRepositoryProvider).searchDestinations(
        city: params.city,
        category: params.category,
      );
});

/// Single destination by its API name/slug (used in [GET /destinations/{name}]).
final destinationByNameProvider =
    FutureProvider.autoDispose.family<DestinationModel, String>((ref, name) {
  return ref.watch(terhalRepositoryProvider).getDestinationByName(name);
});

/// Reviews for a destination id (API path uses id string).
final destinationReviewsProvider = FutureProvider.autoDispose
    .family<List<ReviewModel>, String>((ref, destinationId) {
  return ref
      .watch(terhalRepositoryProvider)
      .getReviewsForDestination(destinationId);
});
