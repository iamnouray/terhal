import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/destination_model.dart';
import 'dependencies.dart';
import 'session.dart';

/// Tunable filters for [GET /recommend/{user_id}].
class RecommendationParams {
  const RecommendationParams({
    this.city,
    this.budget,
    this.topN = 10,
  });

  final String? city;
  final String? budget;
  final int topN;

  RecommendationParams copyWith({
    String? city,
    String? budget,
    int? topN,
    bool clearCity = false,
    bool clearBudget = false,
  }) {
    return RecommendationParams(
      city: clearCity ? null : (city ?? this.city),
      budget: clearBudget ? null : (budget ?? this.budget),
      topN: topN ?? this.topN,
    );
  }
}

final recommendationParamsProvider =
    StateProvider<RecommendationParams>((ref) => const RecommendationParams());

final recommendationsProvider =
    FutureProvider.autoDispose<List<DestinationModel>>((ref) async {
  final session = ref.watch(sessionProvider).valueOrNull;
  final params = ref.watch(recommendationParamsProvider);
  if (session == null) return [];
  return ref.watch(terhalRepositoryProvider).getRecommendations(
        userId: session.userId,
        topN: params.topN,
        city: params.city,
        budget: params.budget,
      );
});
