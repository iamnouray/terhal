import '../../core/network/api_client.dart';
import '../models/destination_model.dart';
import '../models/like_model.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';

/// Raw API access — maps HTTP to typed models. Keeps repositories thin.
class TerhalRemoteDataSource {
  TerhalRemoteDataSource(this._api);

  final ApiClient _api;

  Future<void> register({
    required String email,
    required String password,
    required String name,
  }) async {
    await _api.post('/users/register', {
      'email': email,
      'password': password,
      'name': name,
    });
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final map = await _api.post('/users/login', {
      'email': email,
      'password': password,
    });
    return UserModel.fromJson(map);
  }

  Future<UserModel> getUser(String userId) async {
    final map = await _api.get('/users/$userId');
    return UserModel.fromJson(map);
  }

  Future<void> updatePreferences(
    String userId,
    UserPreferencesPayload payload,
  ) async {
    await _api.put('/users/$userId/preferences', payload.toJson());
  }

  Future<List<DestinationModel>> getDestinations() async {
    final raw = await _api.getDynamic('/destinations/');
    return DestinationModel.listFromDynamic(raw);
  }

  Future<List<DestinationModel>> searchDestinations({
    String? city,
    String? category,
  }) async {
    final q = <String, String>{};
    if (city != null && city.isNotEmpty) q['city'] = city;
    if (category != null && category.isNotEmpty) q['category'] = category;
    final raw = await _api.getDynamic('/destinations/search', query: q);
    return DestinationModel.listFromDynamic(raw);
  }

  Future<DestinationModel> getDestinationByName(String name) async {
    final encoded = Uri.encodeComponent(name);
    final map = await _api.get('/destinations/$encoded');
    // Single object or wrapped
    if (map.containsKey('destination') && map['destination'] is Map) {
      return DestinationModel.fromJson(
        map['destination'] as Map<String, dynamic>,
      );
    }
    return DestinationModel.fromJson(map);
  }

  Future<List<DestinationModel>> getRecommendations({
    required String userId,
    int? topN,
    String? city,
    String? budget,
  }) async {
    final q = <String, String>{};
    if (topN != null) q['top_n'] = '$topN';
    if (city != null && city.isNotEmpty) q['city'] = city;
    if (budget != null && budget.isNotEmpty) q['budget'] = budget;
    final raw = await _api.getDynamic('/recommend/$userId', query: q);
    return DestinationModel.listFromDynamic(raw);
  }

  Future<void> addLike({
    required String userId,
    required String destinationId,
  }) async {
    await _api.post('/likes', {
      'user_id': userId,
      'destination_id': destinationId,
    });
  }

  Future<List<LikeModel>> getLikes(String userId) async {
    final raw = await _api.getDynamic('/likes/$userId');
    return LikeModel.listFromDynamic(raw);
  }

  Future<void> addReview({
    required String userId,
    required String destinationId,
    required int rating,
    required String comment,
  }) async {
    await _api.post('/reviews', {
      'user_id': userId,
      'destination_id': destinationId,
      'rating': rating,
      'comment': comment,
    });
  }

  Future<List<ReviewModel>> getReviewsForDestination(String destinationId) async {
    final raw = await _api.getDynamic('/reviews/$destinationId');
    return ReviewModel.listFromDynamic(raw);
  }

  Future<List<ReviewModel>> getReviewsForUser(String userId) async {
    final raw = await _api.getDynamic('/reviews/user/$userId');
    return ReviewModel.listFromDynamic(raw);
  }
}
