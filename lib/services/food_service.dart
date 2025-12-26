import 'package:firebase_database/firebase_database.dart';
import '../models/food_item.dart';

/// Service for managing food items in Firebase
class FoodService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Get all food items
  Future<List<FoodItem>> getAllFoodItems() async {
    try {
      DatabaseEvent event = await _database.child('foodItems').once();
      
      if (!event.snapshot.exists) {
        return [];
      }

      Map<dynamic, dynamic> foodsMap = event.snapshot.value as Map<dynamic, dynamic>;
      List<FoodItem> foodItems = [];

      foodsMap.forEach((key, value) {
        foodItems.add(FoodItem.fromMap(value));
      });

      return foodItems;
    } catch (e) {
      print('Error fetching food items: $e');
      return [];
    }
  }

  /// Get food items by category
  Future<List<FoodItem>> getFoodItemsByCategory(String category) async {
    try {
      DatabaseEvent event = await _database
          .child('foodItems')
          .orderByChild('category')
          .equalTo(category)
          .once();

      if (!event.snapshot.exists) {
        return [];
      }

      Map<dynamic, dynamic> foodsMap = event.snapshot.value as Map<dynamic, dynamic>;
      List<FoodItem> foodItems = [];

      foodsMap.forEach((key, value) {
        foodItems.add(FoodItem.fromMap(value));
      });

      return foodItems;
    } catch (e) {
      print('Error fetching food items by category: $e');
      return [];
    }
  }

  /// Get vegetarian food items
  Future<List<FoodItem>> getVegetarianItems() async {
    try {
      DatabaseEvent event = await _database
          .child('foodItems')
          .orderByChild('isVegetarian')
          .equalTo(true)
          .once();

      if (!event.snapshot.exists) {
        return [];
      }

      Map<dynamic, dynamic> foodsMap = event.snapshot.value as Map<dynamic, dynamic>;
      List<FoodItem> foodItems = [];

      foodsMap.forEach((key, value) {
        foodItems.add(FoodItem.fromMap(value));
      });

      return foodItems;
    } catch (e) {
      print('Error fetching vegetarian items: $e');
      return [];
    }
  }

  /// Add a new food item (Admin function)
  Future<bool> addFoodItem(FoodItem foodItem) async {
    try {
      await _database.child('foodItems').child(foodItem.id).set(foodItem.toMap());
      return true;
    } catch (e) {
      print('Error adding food item: $e');
      return false;
    }
  }

  /// Update food item
  Future<bool> updateFoodItem(FoodItem foodItem) async {
    try {
      await _database.child('foodItems').child(foodItem.id).update(foodItem.toMap());
      return true;
    } catch (e) {
      print('Error updating food item: $e');
      return false;
    }
  }

  /// Delete food item
  Future<bool> deleteFoodItem(String foodId) async {
    try {
      await _database.child('foodItems').child(foodId).remove();
      return true;
    } catch (e) {
      print('Error deleting food item: $e');
      return false;
    }
  }
}
