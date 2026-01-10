/// Food Item Model
class FoodItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final bool isVegetarian;
  final bool isAvailable;
  final int preparationTime; // in minutes
  final List<String> tags;

  FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.isVegetarian = false,
    this.isAvailable = true,
    this.preparationTime = 15,
    this.tags = const [],
  });

  // Convert FoodItem to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'isVegetarian': isVegetarian,
      'isAvailable': isAvailable,
      'preparationTime': preparationTime,
      'tags': tags,
    };
  }

  // Create FoodItem from Firebase Map
  factory FoodItem.fromMap(Map<dynamic, dynamic> map) {
    return FoodItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      category: map['category'] ?? 'Other',
      isVegetarian: map['isVegetarian'] ?? false,
      isAvailable: map['isAvailable'] ?? true,
      preparationTime: map['preparationTime'] ?? 15,
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  // Create FoodItem from Supabase Map
  factory FoodItem.fromSupabaseMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      imageUrl: map['image_url'] ?? '',
      category: map['category'] ?? 'Other',
      isVegetarian: map['is_vegetarian'] ?? false,
      isAvailable: map['is_available'] ?? true,
      preparationTime: map['preparation_time'] ?? 15,
      tags: List<String>.from(map['tags'] ?? []),
    );
  }
}