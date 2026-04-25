import '../../data/models/destination_model.dart';
import '../../data/models/like_model.dart';
import '../../data/models/review_model.dart';
import '../../data/models/user_model.dart';

/// Application boundary for all Terhal backend operations.
abstract class TerhalRepository {
  Future<void> register({
    required String email,
    required String password,
    required String name,
  });

  Future<UserModel> login({
    required String email,
    required String password,
  });

  Future<UserModel> getUser(String userId);

  Future<void> updatePreferences(
    String userId,
    UserPreferencesPayload payload,
  );

  Future<List<DestinationModel>> getDestinations();

  Future<List<DestinationModel>> searchDestinations({
    String? city,
    String? category,
  });

  Future<DestinationModel> getDestinationByName(String name);

  Future<List<DestinationModel>> getRecommendations({
    required String userId,
    int? topN,
    String? city,
    String? budget,
  });

  Future<void> addLike({
    required String userId,
    required String destinationId,
  });

  Future<List<LikeModel>> getLikes(String userId);

  Future<void> addReview({
    required String userId,
    required String destinationId,
    required int rating,
    required String comment,
  });

  Future<List<ReviewModel>> getReviewsForDestination(String destinationId);

  Future<List<ReviewModel>> getReviewsForUser(String userId);
}
