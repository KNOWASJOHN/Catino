import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/data/supabase_food_service.dart';
import '../models/food_item.dart';

// Category Section Widget
class CategorySection extends StatelessWidget {
  final String category;
  final List<FoodItem> foodItems;
  final Map<String, int> cart;
  final Function(String) onAddToCart;
  final Function(String, int) onUpdateQuantity;
  final IconData icon;

  final ScrollController? scrollController;

  const CategorySection({
    super.key,
    required this.category,
    required this.foodItems,
    required this.cart,
    required this.onAddToCart,
    required this.onUpdateQuantity,
    required this.icon,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 420;
    final cardHeight = isSmall ? 210.0 : 230.0;
    final cardWidth = isSmall ? screenWidth * 0.54 : screenWidth * 0.40;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header
        GestureDetector(
          onTap: () async {
            // Smooth scroll to end when header tapped
            if (scrollController != null && scrollController!.hasClients) {
              await scrollController!.animateTo(
                scrollController!.position.maxScrollExtent,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
              );
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
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
                    color: AppColors.primary,
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
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.priceText,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'View All',
                    style: const TextStyle(
                      fontFamily: 'Unbounded',
                      color: AppColors.surface,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Horizontal Scrollable Food Items (responsive)
        SizedBox(
          height: cardHeight,
          child: ListView.builder(
            controller: scrollController,
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
                    onUpdateQuantity: (qty) =>
                        onUpdateQuantity(foodItem.id, qty),
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
  final VoidCallback? onCartPressed;

  const FoodListPage({super.key, this.onCartPressed});

  @override
  State<FoodListPage> createState() => _FoodListPageState();
}

class _FoodListPageState extends State<FoodListPage> {
  final SupabaseFoodService _foodService = SupabaseFoodService();
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

  // Add a map of ScrollControllers for each category
  final Map<String, ScrollController> _categoryScrollControllers = {};

  Map<String, List<FoodItem>> _groupedFoodItems = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _foodService.startListeningToFoodItems();
    _loadFoodItems();
  }

  Future<void> _loadFoodItems() async {
    setState(() => _loading = true);
    try {
      final items = await _foodService.getAllFoodItems();
      setState(() {
        _groupedFoodItems = {};
        for (var item in items) {
          if (!_groupedFoodItems.containsKey(item.category)) {
            _groupedFoodItems[item.category] = [];
          }
          _groupedFoodItems[item.category]!.add(item);
        }
        // Sort items within each category
        _groupedFoodItems.forEach((category, items) {
          items.sort((a, b) => a.name.compareTo(b.name));
        });
        _loading = false;
      });
    } catch (e) {
      print('Error loading food items: $e');
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    // Dispose all scroll controllers
    for (final controller in _categoryScrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _groupedFoodItems.isEmpty
          ? Center(
              child: Text(
                'No food items available',
                style: TextStyle(fontFamily: 'Unbounded'),
              ),
            )
          : _buildFoodList(),
    );
  }

  Widget _buildFoodList() {
    final categories = _groupedFoodItems.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    // Initialize ScrollControllers once for all categories before building
    for (final category in categories) {
      _categoryScrollControllers.putIfAbsent(
        category,
        () => ScrollController(),
      );
    }

    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final cart = cartProvider.cart;
        return ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final foodItems = _groupedFoodItems[category]!;
            // Use the pre-created ScrollController
            final controller = _categoryScrollControllers[category]!;
            return CategorySection(
              category: category,
              foodItems: foodItems,
              cart: cart,
              onAddToCart: (id) => cartProvider.addItem(id),
              onUpdateQuantity: (id, qty) =>
                  cartProvider.updateQuantity(id, qty),
              icon: _categoryIcons[category] ?? Icons.restaurant_menu,
              scrollController: controller,
            );
          },
        );
      },
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
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      shadowColor: Colors.black.withOpacity(0.25),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxH = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : 320.0;
          final imageHeight = isHorizontalView
              ? (maxH * 0.42).clamp(70.0, 140.0)
              : (maxH * 0.30).clamp(90.0, 180.0);
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
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.restaurant_menu,
                                  size: 48,
                                  color: theme.disabledColor,
                                ),
                              ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: foodItem.isVegetarian
                                ? AppColors.primary
                                : Colors.red.shade700,
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
                            foodItem.isVegetarian ? 'VEG' : 'NON-VEG',
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
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and description
                      Text(
                        foodItem.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Unbounded',
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        foodItem.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 8,
                          fontFamily: 'Unbounded',
                          color: Colors.black54,
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
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Unbounded',
                                color: AppColors.priceText,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (foodItem.tags.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                foodItem.tags.first,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 7,
                                  color: Colors.orange.shade800,
                                  fontFamily: 'Unbounded',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Preparation time and quantity/button
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 10,
                            color: Colors.black38,
                          ),
                          const SizedBox(width: 1),
                          Text(
                            '${foodItem.preparationTime} min',
                            style: const TextStyle(
                              fontSize: 8,
                              color: Colors.black38,
                              fontFamily: 'Unbounded',
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          const Spacer(),

                          // Add / quantity controls - constrained to avoid overflow
                          if (quantity == 0)
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: onAdd,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  fixedSize: Size(8, 8),
                                  padding: const EdgeInsets.fromLTRB(
                                    8,
                                    8,
                                    8,
                                    8,
                                  ),
                                ),
                                child: const Text(
                                  'ADD',
                                  style: TextStyle(
                                    fontFamily: 'Unbounded',
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                          else
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    icon: const Icon(
                                      Icons.remove,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    onPressed: () =>
                                        onUpdateQuantity(quantity - 1),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '$quantity',
                                      style: const TextStyle(
                                        color: Color(0xFF1A1A1A),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                        fontFamily: 'Unbounded',
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    icon: const Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    onPressed: () =>
                                        onUpdateQuantity(quantity + 1),
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
