 class Destination {
  final String name;
  final String category;
  final double rating;
  final String description;

  Destination({required this.name, required this.category, required this.rating, required this.description});

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      name: json['name'],
      category: json['category'],
      rating: json['rating'].toDouble(),
      description: json['description'],
    );
  }
}