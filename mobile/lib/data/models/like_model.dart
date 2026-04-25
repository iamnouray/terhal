import 'json_helpers.dart';

/// One liked destination for a user (shape depends on backend).
class LikeModel {
  const LikeModel({required this.destinationId});

  final String destinationId;

  factory LikeModel.fromJson(Map<String, dynamic> json) {
    final dest = json['destination'] is Map<String, dynamic>
        ? json['destination'] as Map<String, dynamic>
        : json;
    final id = readId(dest) ??
        json['destination_id']?.toString() ??
        dest['name']?.toString() ??
        '';
    return LikeModel(destinationId: id);
  }

  static List<LikeModel> listFromDynamic(dynamic data) {
    if (data == null) return [];
    if (data is List<dynamic>) {
      return data.map((e) {
        if (e is String) return LikeModel(destinationId: e);
        if (e is Map<String, dynamic>) return LikeModel.fromJson(e);
        return LikeModel(destinationId: e.toString());
      }).toList();
    }
    if (data is Map<String, dynamic>) {
      for (final key in ['likes', 'data', 'items']) {
        final v = data[key];
        if (v is List<dynamic>) return listFromDynamic(v);
      }
    }
    return [];
  }
}
