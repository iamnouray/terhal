import '../../domain/repositories/terhal_repository.dart';
import '../datasources/terhal_remote_datasource.dart';
import '../models/destination_model.dart';
import '../models/like_model.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';

class TerhalRepositoryImpl implements TerhalRepository {
  TerhalRepositoryImpl(this._remote);

  final TerhalRemoteDataSource _remote;

  @override
  Future<void> register({
    required String email,
    required String password,
    required String name,
  }) =>
      _remote.register(email: email, password: password, name: name);

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) =>
      _remote.login(email: email, password: password);

  @override
  Future<UserModel> getUser(String userId) => _remote.getUser(userId);

  @override
  Future<void> updatePreferences(
    String userId,
    UserPreferencesPayload payload,
  ) =>
      _remote.updatePreferences(userId, payload);

  @override
  Future<List<DestinationModel>> getDestinations() =>
      _remote.getDestinations();

  @override
  Future<List<DestinationModel>> searchDestinations({
    String? city,
    String? category,
  }) =>
      _remote.searchDestinations(city: city, category: category);

  @override
  Future<DestinationModel> getDestinationByName(String name) =>
      _remote.getDestinationByName(name);

  @override
  Future<List<DestinationModel>> getRecommendations({
    required String userId,
    int? topN,
    String? city,
    String? budget,
  }) =>
      _remote.getRecommendations(
        userId: userId,
        topN: topN,
        city: city,
        budget: budget,
      );

  @override
  Future<void> addLike({
    required String userId,
    required String destinationId,
  }) =>
      _remote.addLike(userId: userId, destinationId: destinationId);

  @override
  Future<List<LikeModel>> getLikes(String userId) => _remote.getLikes(userId);

  @override
  Future<void> addReview({
    required String userId,
    required String destinationId,
    required int rating,
    required String comment,
  }) =>
      _remote.addReview(
        userId: userId,
        destinationId: destinationId,
        rating: rating,
        comment: comment,
      );

  @override
  Future<List<ReviewModel>> getReviewsForDestination(String destinationId) =>
      _remote.getReviewsForDestination(destinationId);

  @override
  Future<List<ReviewModel>> getReviewsForUser(String userId) =>
      _remote.getReviewsForUser(userId);
}
