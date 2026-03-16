import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../models/food_item.dart';
import '../../services/data/supabase_food_service.dart';
import '../common/skeleton_loader.dart';
import 'dart:async';

class FoodSection extends StatefulWidget {
  const FoodSection({super.key});

  @override
  State<FoodSection> createState() => _FoodSectionState();
}

class _FoodSectionState extends State<FoodSection> {
  final SupabaseFoodService _foodService = SupabaseFoodService();
  List<FoodItem> _allFoodItems = [];
  List<FoodItem> _displayedItems = [];
  bool _isLoading = true;
  Timer? _rotationTimer;
  static const int _maxDisplayItems = 6; // Show only 6 items at a time

  @override
  void initState() {
    super.initState();
    _foodService.startListeningToFoodItems();
    _loadFoodItems();
    _startRotation();
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    super.dispose();
  }

  void _startRotation() {
    // Rotate items every 5 seconds
    _rotationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_allFoodItems.isNotEmpty) {
        _updateDisplayedItems();
      }
    });
  }

  void _updateDisplayedItems() {
    if (_allFoodItems.isEmpty) return;

    setState(() {
      // Shuffle and take first items for variety
      final shuffled = List<FoodItem>.from(_allFoodItems)..shuffle();
      _displayedItems = shuffled.take(_maxDisplayItems).toList();
    });
  }

  Future<void> _loadFoodItems() async {
    setState(() => _isLoading = true);

    try {
      List<FoodItem> items = await _foodService.getAllFoodItems();

      setState(() {
        _allFoodItems = items;
        _updateDisplayedItems();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Widget foodBox(FoodItem item) {
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
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
                    color: Colors.grey[200],
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 32,
                      color: Colors.grey[400],
                    ),
                  );
                },
              ),
              // Dark overlay for better text visibility - Simplified gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
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
                      style: const TextStyle(
                        fontFamily: 'Unbounded',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'Unbounded',
                        fontWeight: FontWeight.w100,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹ ${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontFamily: 'Unbounded',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.priceText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
      return const FoodSectionSkeleton();
    }

    if (_displayedItems.isEmpty) {
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

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8.0),
      itemCount: _displayedItems.length,
      itemBuilder: (context, index) => foodBox(_displayedItems[index]),
    );
  }
}
