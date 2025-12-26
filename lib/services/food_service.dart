import 'package:firebase_database/firebase_database.dart';
import '../models/food_item.dart';

/// Service for managing food items in Firebase
class FoodService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Get all food items
  Future<List<FoodItem>> getAllFoodItems() async {
    try {
      print('Fetching all food items from database');
      
      DatabaseEvent event = await _database.child('foodItems').once();
      
      print('Database snapshot exists: ${event.snapshot.exists}');
      
      if (!event.snapshot.exists) {
        print('No food items found in database');
        return [];
      }

      final snapshotValue = event.snapshot.value;
      print('Snapshot value type: ${snapshotValue.runtimeType}');
      print('Snapshot value: $snapshotValue');
      
      if (snapshotValue == null) {
        print('Snapshot value is null');
        return [];
      }

      Map<dynamic, dynamic> foodsMap = snapshotValue as Map<dynamic, dynamic>;
      print('Found ${foodsMap.length} food items in database');
      
      List<FoodItem> foodItems = [];

      foodsMap.forEach((key, value) {
        try {
          print('Processing food item $key with value: $value');
          if (value is Map) {
            foodItems.add(FoodItem.fromMap(value));
          } else {
            print('Value is not a Map: ${value.runtimeType}');
          }
        } catch (e, stackTrace) {
          print('Error parsing food item $key: $e');
          print('Stack trace: $stackTrace');
        }
      });

      print('Returning ${foodItems.length} parsed food items');
      return foodItems;
    } catch (e, stackTrace) {
      print('Error fetching food items: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get food items by category
  Future<List<FoodItem>> getFoodItemsByCategory(String category) async {
    try {
      print('Fetching food items for category: $category');
      
      DatabaseEvent event = await _database
          .child('foodItems')
          .orderByChild('category')
          .equalTo(category)
          .once();

      print('Database snapshot exists: ${event.snapshot.exists}');
      
      if (!event.snapshot.exists) {
        print('No food items found for category: $category');
        return [];
      }

      final snapshotValue = event.snapshot.value;
      print('Snapshot value type: ${snapshotValue.runtimeType}');
      
      if (snapshotValue == null) {
        print('Snapshot value is null for category: $category');
        return [];
      }

      Map<dynamic, dynamic> foodsMap = snapshotValue as Map<dynamic, dynamic>;
      print('Found ${foodsMap.length} food items in category: $category');
      
      List<FoodItem> foodItems = [];

      foodsMap.forEach((key, value) {
        try {
          print('Processing food item $key');
          if (value is Map) {
            foodItems.add(FoodItem.fromMap(value));
          } else {
            print('Value is not a Map: ${value.runtimeType}');
          }
        } catch (e, stackTrace) {
          print('Error parsing food item $key: $e');
          print('Stack trace: $stackTrace');
        }
      });

      print('Returning ${foodItems.length} parsed food items for category: $category');
      return foodItems;
    } catch (e, stackTrace) {
      print('Error fetching food items by category: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get vegetarian food items
  Future<List<FoodItem>> getVegetarianItems() async {
    try {
      print('Fetching vegetarian food items');
      
      DatabaseEvent event = await _database
          .child('foodItems')
          .orderByChild('isVegetarian')
          .equalTo(true)
          .once();

      print('Database snapshot exists: ${event.snapshot.exists}');
      
      if (!event.snapshot.exists) {
        print('No vegetarian food items found');
        return [];
      }

      final snapshotValue = event.snapshot.value;
      print('Snapshot value type: ${snapshotValue.runtimeType}');
      
      if (snapshotValue == null) {
        print('Snapshot value is null for vegetarian items');
        return [];
      }

      Map<dynamic, dynamic> foodsMap = snapshotValue as Map<dynamic, dynamic>;
      print('Found ${foodsMap.length} vegetarian food items');
      
      List<FoodItem> foodItems = [];

      foodsMap.forEach((key, value) {
        try {
          print('Processing vegetarian item $key');
          if (value is Map) {
            foodItems.add(FoodItem.fromMap(value));
          } else {
            print('Value is not a Map: ${value.runtimeType}');
          }
        } catch (e, stackTrace) {
          print('Error parsing vegetarian item $key: $e');
          print('Stack trace: $stackTrace');
        }
      });

      print('Returning ${foodItems.length} parsed vegetarian items');
      return foodItems;
    } catch (e, stackTrace) {
      print('Error fetching vegetarian items: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Add a new food item (Admin function)
  Future<bool> addFoodItem(FoodItem foodItem) async {
    try {
      print('Adding food item with id: ${foodItem.id}');
      
      await _database.child('foodItems').child(foodItem.id).set(foodItem.toMap());
      
      print('Successfully added food item: ${foodItem.id}');
      return true;
    } catch (e, stackTrace) {
      print('Error adding food item: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Update food item
  Future<bool> updateFoodItem(FoodItem foodItem) async {
    try {
      print('Updating food item with id: ${foodItem.id}');
      
      await _database.child('foodItems').child(foodItem.id).update(foodItem.toMap());
      
      print('Successfully updated food item: ${foodItem.id}');
      return true;
    } catch (e, stackTrace) {
      print('Error updating food item: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Delete food item
  Future<bool> deleteFoodItem(String foodId) async {
    try {
      print('Deleting food item with id: $foodId');
      
      await _database.child('foodItems').child(foodId).remove();
      
      print('Successfully deleted food item: $foodId');
      return true;
    } catch (e, stackTrace) {
      print('Error deleting food item: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }
}
