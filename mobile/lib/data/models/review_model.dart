import 'json_helpers.dart';

class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.userId,
    required this.destinationId,
    required this.rating,
    required this.comment,
    this.authorName,
  });

  final String id;
  final String userId;
  final String destinationId;
  final int rating;
  final String comment;
  final String? authorName;

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final id = readId(json) ?? 'review_${json.hashCode}';

    String userId = '';
    if (json['user_id'] != null) {
      userId = json['user_id'].toString();
    } else if (json['user'] is Map<String, dynamic>) {
      userId = readId(json['user'] as Map<String, dynamic>) ?? '';
    }

    String destinationId = '';
    if (json['destination_id'] != null) {
      destinationId = json['destination_id'].toString();
    } else if (json['destination'] is Map<String, dynamic>) {
      destinationId =
          readId(json['destination'] as Map<String, dynamic>) ?? '';
    }

    final rating = (json['rating'] is int)
        ? json['rating'] as int
        : int.tryParse(json['rating']?.toString() ?? '') ?? 0;
    final comment = (json['comment'] ?? json['text'] ?? '').toString();

    String? authorName;
    if (json['user'] is Map<String, dynamic>) {
      final u = json['user'] as Map<String, dynamic>;
      authorName = (u['name'] ?? u['username'])?.toString();
    }

    return ReviewModel(
      id: id,
      userId: userId,
      destinationId: destinationId,
      rating: rating,
      comment: comment,
      authorName: authorName,
    );
  }

  static List<ReviewModel> listFromDynamic(dynamic data) {
    if (data == null) return [];
    if (data is List<dynamic>) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(ReviewModel.fromJson)
          .toList();
    }
    if (data is Map<String, dynamic>) {
      for (final key in ['reviews', 'data', 'items']) {
        final v = data[key];
        if (v is List<dynamic>) {
          return v
              .whereType<Map<String, dynamic>>()
              .map(ReviewModel.fromJson)
              .toList();
        }
      }
    }
    return [];
  }
}
