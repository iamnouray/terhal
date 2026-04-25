import 'json_helpers.dart';

class DestinationModel {
  const DestinationModel({
    required this.id,
    required this.name,
    this.city,
    this.category,
    this.description,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String? city;
  final String? category;
  final String? description;
  final String? imageUrl;

  /// Best-effort parse: backends vary; extend when your API shape is fixed.
  factory DestinationModel.fromJson(Map<String, dynamic> json) {
    final id = readId(json) ?? (json['name'] ?? '').toString();
    final name = (json['name'] ?? json['title'] ?? id).toString();
    return DestinationModel(
      id: id.isEmpty ? name : id,
      name: name,
      city: json['city']?.toString(),
      category: json['category']?.toString(),
      description: json['description']?.toString() ?? json['about']?.toString(),
      imageUrl: json['image']?.toString() ?? json['image_url']?.toString(),
    );
  }

  static List<DestinationModel> listFromDynamic(dynamic data) {
    if (data == null) return [];
    if (data is List<dynamic>) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(DestinationModel.fromJson)
          .toList();
    }
    if (data is Map<String, dynamic>) {
      for (final key in ['destinations', 'data', 'items', 'results']) {
        final v = data[key];
        if (v is List<dynamic>) {
          return v
              .whereType<Map<String, dynamic>>()
              .map(DestinationModel.fromJson)
              .toList();
        }
      }
    }
    return [];
  }
}
