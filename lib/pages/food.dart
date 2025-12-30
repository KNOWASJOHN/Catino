import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

// FoodItem model class
class FoodItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final bool isVeg;
  final String category;
  final bool isAvailable;
  final int preparationTime;
  final List<String> tags;

  FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.isVeg,
    required this.category,
    required this.isAvailable,
    this.preparationTime = 10,
    this.tags = const [],
  });

  factory FoodItem.fromRealtimeDB(Map<String, dynamic> data) {
    return FoodItem(
      id: data['id'] ?? '',
      name: data['name'] ?? 'Unknown',
      description: data['description'] ?? '',
      price: (data['price'] is double ? data['price'] : 
              data['price'] is int ? data['price'].toDouble() : 0.0),
      imageUrl: data['imageUrl'] ?? '',
      isVeg: data['isVeg'] ?? data['isVegetarian'] ?? true,
      category: data['category'] ?? 'Uncategorized',
      isAvailable: data['isAvailable'] ?? false,
      preparationTime: data['preparationTime'] ?? 10,
      tags: List<String>.from(data['tags'] ?? []),
    );
  }
}

// FoodService class
class FoodService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('foodPageItems');

  List<FoodItem> _cachedItems = [];
  Map<String, List<FoodItem>> _cachedCategorizedItems = {};

  Stream<List<FoodItem>> getFoodItems() {
    return _dbRef.onValue.map((event) {
      final items = <FoodItem>[];
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          final itemData = Map<String, dynamic>.from(value as Map);
          if (itemData['isAvailable'] == true) {
            items.add(FoodItem.fromRealtimeDB(itemData));
          }
        });
      }
      if (!_areFoodItemListsEqual(items, _cachedItems)) {
        _cachedItems = List<FoodItem>.from(items);
      }
      return _cachedItems;
    });
  }

  Stream<Map<String, List<FoodItem>>> getFoodItemsByCategory() {
    return _dbRef.onValue.map((event) {
      final Map<String, List<FoodItem>> categorizedItems = {};
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          final itemData = Map<String, dynamic>.from(value as Map);
          if (itemData['isAvailable'] == true) {
            final foodItem = FoodItem.fromRealtimeDB(itemData);
            final category = foodItem.category;
            if (!categorizedItems.containsKey(category)) {
              categorizedItems[category] = [];
            }
            categorizedItems[category]!.add(foodItem);
          }
        });
        // Sort items within each category
        categorizedItems.forEach((category, items) {
          items.sort((a, b) => a.name.compareTo(b.name));
        });
      }
      if (!_areCategorizedFoodItemsEqual(categorizedItems, _cachedCategorizedItems)) {
        _cachedCategorizedItems = categorizedItems.map((k, v) => MapEntry(k, List<FoodItem>.from(v)));
      }
      return _cachedCategorizedItems;
    });
  }

  bool _areFoodItemListsEqual(List<FoodItem> a, List<FoodItem> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!_foodItemEquals(a[i], b[i])) return false;
    }
    return true;
  }

  bool _areCategorizedFoodItemsEqual(Map<String, List<FoodItem>> a, Map<String, List<FoodItem>> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (!_areFoodItemListsEqual(a[key]!, b[key]!)) return false;
    }
    return true;
  }

  bool _foodItemEquals(FoodItem a, FoodItem b) {
    return a.id == b.id &&
        a.name == b.name &&
        a.description == b.description &&
        a.price == b.price &&
        a.imageUrl == b.imageUrl &&
        a.isVeg == b.isVeg &&
        a.category == b.category &&
        a.isAvailable == b.isAvailable &&
        a.preparationTime == b.preparationTime &&
        _listEquals(a.tags, b.tags);
  }

  bool _listEquals(List a, List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

// Category Section Widget
class CategorySection extends StatelessWidget {
  final String category;
  final List<FoodItem> foodItems;
  final Map<String, int> cart;
  final Function(String) onAddToCart;
  final Function(String, int) onUpdateQuantity;
  final IconData icon;

  const CategorySection({
    super.key,
    required this.category,
    required this.foodItems,
    required this.cart,
    required this.onAddToCart,
    required this.onUpdateQuantity,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 420;
    final horizontalPadding = isSmall ? 12.0 : 16.0;
    final cardHeight = isSmall ? 220.0 : 240.0;
    final cardWidth = isSmall ? screenWidth * 0.72 : 180.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Unbounded',
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.limeAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'View All',
                  style: const TextStyle(
                    fontFamily: 'Unbounded',
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Horizontal Scrollable Food Items (responsive)
        SizedBox(
          height: cardHeight+30,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
          padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
            itemCount: foodItems.length,
            itemBuilder: (context, index) {
              final foodItem = foodItems[index];
              final quantity = cart[foodItem.id] ?? 0;

              return Padding(
padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                child: SizedBox(
                  width: cardWidth,
                  child: FoodItemCard(
                    foodItem: foodItem,
                    quantity: quantity,
                    onAdd: () => onAddToCart(foodItem.id),
                    onUpdateQuantity: (qty) => onUpdateQuantity(foodItem.id, qty),
                    isHorizontalView: true,
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 30),
      ],
    );
  }
}

// FoodListPage widget
class FoodListPage extends StatefulWidget {
  const FoodListPage({super.key});

  @override
  State<FoodListPage> createState() => _FoodListPageState();
}

class _FoodListPageState extends State<FoodListPage> {
  final FoodService _foodService = FoodService();
  final Map<String, int> _cart = {};
  final Map<String, IconData> _categoryIcons = {
    'Fast Food': Icons.fastfood,
    'Italian': Icons.local_pizza,
    'Beverages': Icons.local_drink,
    'Healthy': Icons.eco,
    'Snacks': Icons.emoji_food_beverage,
    'Desserts': Icons.cake,
    'Main Course': Icons.dinner_dining,
    'Indian': Icons.restaurant,
  };

  void _addToCart(String foodId) {
    setState(() {
      _cart[foodId] = (_cart[foodId] ?? 0) + 1;
    });
  }

  void _updateQuantity(String foodId, int quantity) {
    setState(() {
      if (quantity > 0) {
        _cart[foodId] = quantity;
      } else {
        _cart.remove(foodId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Canteen Menu',
          style: TextStyle(
            fontFamily: 'Unbounded',
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 2,
      ),
      body: StreamBuilder<Map<String, List<FoodItem>>>(
        stream: _foodService.getFoodItemsByCategory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading food items',
                style: TextStyle(fontFamily: 'Unbounded'),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No food items available',
                style: TextStyle(fontFamily: 'Unbounded'),
              ),
            );
          }

          final categorizedItems = snapshot.data!;
          final categories = categorizedItems.keys.toList()
            ..sort((a, b) => a.compareTo(b));

          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final foodItems = categorizedItems[category]!;
              
              return CategorySection(
                category: category,
                foodItems: foodItems,
                cart: _cart,
                onAddToCart: _addToCart,
                onUpdateQuantity: _updateQuantity,
                icon: _categoryIcons[category] ?? Icons.restaurant_menu,
              );
            },
          );
        },
      ),
    );
  }
}

// FoodItemCard widget - Updated for horizontal layout
class FoodItemCard extends StatelessWidget {
  final FoodItem foodItem;
  final int quantity;
  final VoidCallback onAdd;
  final ValueChanged<int> onUpdateQuantity;
  final bool isHorizontalView;

  const FoodItemCard({
    super.key,
    required this.foodItem,
    required this.quantity,
    required this.onAdd,
    required this.onUpdateQuantity,
    this.isHorizontalView = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.black87,
      shadowColor: Colors.black.withOpacity(0.3),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxH = constraints.maxHeight.isFinite ? constraints.maxHeight : 320.0;
          final imageHeight = isHorizontalView ? (maxH * 0.42).clamp(70.0, 140.0) : (maxH * 0.30).clamp(90.0, 180.0);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Food Image (constrained by available height)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: SizedBox(
                  height: imageHeight,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.network(
                          foodItem.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Icon(Icons.restaurant_menu, size: 48, color: theme.disabledColor),
                          ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                                color: theme.colorScheme.primary,
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: foodItem.isVeg ? const Color(0xFF00C853) : Colors.red.shade700,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            foodItem.isVeg ? 'VEG' : 'NON-VEG',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Unbounded',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Details - use remaining space and avoid overflow
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and description
                      Text(
                        foodItem.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Unbounded',
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        foodItem.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'Unbounded',
                          color: Colors.white70,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const Spacer(),

                      // Price and tags
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '₹${foodItem.price.toStringAsFixed(2)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Unbounded',
                                color: Colors.limeAccent,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (foodItem.tags.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                foodItem.tags.first,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.white70,
                                  fontFamily: 'Unbounded',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Preparation time and quantity/button
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 13, color: Colors.white60),
                          const SizedBox(width: 4),
                          Text(
                            '${foodItem.preparationTime} min',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white60,
                              fontFamily: 'Unbounded',
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          const Spacer(),

                          // Add / quantity controls - constrained to avoid overflow
                          if (quantity == 0)
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C853),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00C853).withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: onAdd,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00C853),
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  minimumSize: const Size(80, 34),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                child: const Text(
                                  'ADD',
                                  style: TextStyle(
                                    fontFamily: 'Unbounded',
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                          else
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C853),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00C853).withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    icon: const Icon(Icons.remove, color: Colors.white, size: 16),
                                    onPressed: () => onUpdateQuantity(quantity - 1),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '$quantity',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        fontFamily: 'Unbounded',
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    icon: const Icon(Icons.add, color: Colors.white, size: 16),
                                    onPressed: () => onUpdateQuantity(quantity + 1),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}