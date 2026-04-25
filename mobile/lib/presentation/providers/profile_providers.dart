import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/like_model.dart';
import '../../data/models/review_model.dart';
import '../../data/models/user_model.dart';
import 'dependencies.dart';
import 'session.dart';

/// Fresh profile from [GET /users/{user_id}] (includes preferences when present).
final currentUserProfileProvider =
    FutureProvider.autoDispose<UserModel>((ref) async {
  final session = ref.watch(sessionProvider).valueOrNull;
  if (session == null) {
    throw StateError('Not logged in');
  }
  return ref.watch(terhalRepositoryProvider).getUser(session.userId);
});

final myReviewsProvider =
    FutureProvider.autoDispose<List<ReviewModel>>((ref) async {
  final session = ref.watch(sessionProvider).valueOrNull;
  if (session == null) return [];
  return ref.watch(terhalRepositoryProvider).getReviewsForUser(session.userId);
});

final myLikesProvider =
    FutureProvider.autoDispose<List<LikeModel>>((ref) async {
  final session = ref.watch(sessionProvider).valueOrNull;
  if (session == null) return [];
  return ref.watch(terhalRepositoryProvider).getLikes(session.userId);
});
