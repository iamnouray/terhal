/// Reads Mongo-style `_id` or plain `id` as string.
String? readId(Map<String, dynamic> json) {
  final v = json['_id'] ?? json['id'];
  if (v == null) return null;
  return v.toString();
}
