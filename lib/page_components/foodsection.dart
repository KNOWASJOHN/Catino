import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../services/food_service.dart';

class FoodSection extends StatefulWidget {
  const FoodSection({super.key});

  @override
  State<FoodSection> createState() => _FoodSectionState();
}

class _FoodSectionState extends State<FoodSection> {
  final FoodService _foodService = FoodService();
  List<FoodItem> _foodItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _foodService.startListeningToFoodItems();
    _loadFoodItems();
  }

  Future<void> _loadFoodItems() async {
    setState(() => _isLoading = true);
    
    try {
      List<FoodItem> items = await _foodService.getAllFoodItems();
      
      setState(() {
        _foodItems = items;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading food items: $e');
      setState(() => _isLoading = false);
    }
  }

  Widget foodBox(FoodItem item) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image with loading/error handling
            Image.network(
              item.imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[300],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported,
                          size: 40, color: Colors.grey[500]),
                      const SizedBox(height: 8),
                      Text('Image not available',
                          style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                    ],
                  ),
                );
              },
            ),
            // Dark overlay for better text visibility
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontFamily: 'Unbounded',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(2, 2),
                          blurRadius: 5,
                          color: Colors.black.withValues(alpha: 0.8),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'Unbounded',
                      fontWeight: FontWeight.w100,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(2, 2),
                          blurRadius: 5,
                          color: Colors.black.withValues(alpha: 0.8),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '₹ ${item.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontFamily: 'Unbounded',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.limeAccent,
                      shadows: [
                        Shadow(
                          offset: Offset(2, 2),
                          blurRadius: 5,
                          color: Colors.black.withValues(alpha: 0.8),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount;

    if (screenWidth < 600) {
      crossAxisCount = 2; // Small phones
    } else if (screenWidth < 900) {
      crossAxisCount = 3; // Tablets and large phones
    } else if (screenWidth < 1200) {
      crossAxisCount = 4; // Small desktops
    } else {
      crossAxisCount = 5; // Large screens
    }

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
        ),
      );
    }

    if (_foodItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No food items available',
              style: TextStyle(
                fontFamily: 'Unbounded',
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1,
      padding: const EdgeInsets.all(8.0),
      children: _foodItems.map((item) => foodBox(item)).toList(),
    );
  }
}
