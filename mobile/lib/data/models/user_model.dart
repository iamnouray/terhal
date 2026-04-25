import 'json_helpers.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.preferences,
  });

  final String id;
  final String name;
  final String email;
  final Map<String, dynamic>? preferences;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Wrapped as { user: { ... } } or flat user object.
    final root = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : json;

    final id = readId(root) ?? root['user_id']?.toString();
    if (id == null || id.isEmpty) {
      throw FormatException('User JSON missing id: $json');
    }

    final name = (root['name'] ?? root['username'] ?? '').toString();
    final email = (root['email'] ?? '').toString();
    final prefs = root['preferences'];
    return UserModel(
      id: id,
      name: name,
      email: email,
      preferences: prefs is Map<String, dynamic> ? prefs : null,
    );
  }
}

/// Payload for [PUT /users/{id}/preferences].
class UserPreferencesPayload {
  const UserPreferencesPayload({
    required this.city,
    required this.visitorType,
    required this.preferredTime,
    required this.environment,
    required this.budget,
  });

  final String city;
  final String visitorType;
  final String preferredTime;
  final String environment;
  final String budget;

  Map<String, dynamic> toJson() => {
        'city': city,
        'visitor_type': visitorType,
        'preferred_time': preferredTime,
        'environment': environment,
        'budget': budget,
      };
}
