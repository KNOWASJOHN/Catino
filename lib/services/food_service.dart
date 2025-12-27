import 'package:firebase_database/firebase_database.dart';
import '../models/food_item.dart';
import 'food_cache_service.dart';

/// Service for managing food items in Firebase
class FoodService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FoodCacheService _cacheService = FoodCacheService();
  bool _isListening = false;

  /// Start listening to food items changes in Firebase
  void startListeningToFoodItems() {
    if (_isListening) return;
    _isListening = true;
    
    _database.child('foodItems').onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        try {
          Map<dynamic, dynamic> foodsMap = event.snapshot.value as Map<dynamic, dynamic>;
          List<FoodItem> foodItems = [];
          
          foodsMap.forEach((key, value) {
            if (value is Map) {
              foodItems.add(FoodItem.fromMap(value));
            }
          });
          
          // Update cache with fresh data
          _cacheService.cacheAllFoodItems(foodItems);
          print('Food items cache updated from Firebase listener (${foodItems.length} items)');
        } catch (e) {
          print('Error processing food items update: $e');
        }
      }
    });
  }

  /// Get all food items from cache first, then Firebase if needed
  Future<List<FoodItem>> getAllFoodItems({bool forceRefresh = false}) async {
    try {
      // Start listening for real-time updates
      startListeningToFoodItems();
      
      // Try cache first if not forcing refresh
      if (!forceRefresh) {
        final cachedItems = await _cacheService.getCachedAllFoodItems();
        if (cachedItems != null && cachedItems.isNotEmpty) {
          print('Returning ${cachedItems.length} food items from cache');
          // Refresh in background if stale
          _refreshFoodDataIfStale();
          return cachedItems;
        }
      }
      
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
      
      // Cache the fresh data
      await _cacheService.cacheAllFoodItems(foodItems);
      
      return foodItems;
    } catch (e, stackTrace) {
      print('Error fetching food items: $e');
      print('Stack trace: $stackTrace');
      // Fallback to cache if Firebase fails
      final cachedItems = await _cacheService.getCachedAllFoodItems();
      return cachedItems ?? [];
    }
  }

  /// Refresh food data in background if cache is stale
  void _refreshFoodDataIfStale() async {
    try {
      final isStale = await _cacheService.isCacheStale(
        maxAge: const Duration(hours: 1),
      );
      
      if (isStale) {
        print('Food cache is stale, refreshing in background');
        getAllFoodItems(forceRefresh: true);
      }
    } catch (e) {
      print('Error checking food cache staleness: $e');
    }
  }

  /// Get food items by category from cache first, then Firebase if needed
  Future<List<FoodItem>> getFoodItemsByCategory(String category, {bool forceRefresh = false}) async {
    try {
      // Try cache first if not forcing refresh
      if (!forceRefresh) {
        final cachedItems = await _cacheService.getCachedFoodItemsByCategory(category);
        if (cachedItems != null && cachedItems.isNotEmpty) {
          print('Returning ${cachedItems.length} items from cache for category: $category');
          return cachedItems;
        }
      }
      
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
      
      // Cache the fresh data
      await _cacheService.cacheFoodItemsByCategory(category, foodItems);
      
      return foodItems;
    } catch (e, stackTrace) {
      print('Error fetching food items by category: $e');
      print('Stack trace: $stackTrace');
      // Fallback to cache
      final cachedItems = await _cacheService.getCachedFoodItemsByCategory(category);
      return cachedItems ?? [];
    }
  }

  /// Get vegetarian food items from cache first, then Firebase if needed
  Future<List<FoodItem>> getVegetarianItems({bool forceRefresh = false}) async {
    try {
      // Try cache first if not forcing refresh
      if (!forceRefresh) {
        final cachedItems = await _cacheService.getCachedVegetarianItems();
        if (cachedItems != null && cachedItems.isNotEmpty) {
          print('Returning ${cachedItems.length} vegetarian items from cache');
          return cachedItems;
        }
      }
      
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
      
      // Cache the fresh data
      await _cacheService.cacheVegetarianItems(foodItems);
      
      return foodItems;
    } catch (e, stackTrace) {
      print('Error fetching vegetarian items: $e');
      print('Stack trace: $stackTrace');
      // Fallback to cache
      final cachedItems = await _cacheService.getCachedVegetarianItems();
      return cachedItems ?? [];
    }
  }

  /// Add a new food item (Admin function)
  Future<bool> addFoodItem(FoodItem foodItem) async {
    try {
      print('Adding food item with id: ${foodItem.id}');
      
      await _database.child('foodItems').child(foodItem.id).set(foodItem.toMap());
      
      print('Successfully added food item: ${foodItem.id}');
      
      // Invalidate cache to force refresh
      await _cacheService.invalidateCache();
      
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
      
      // Invalidate cache to force refresh
      await _cacheService.invalidateCache();
      
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
      
      // Invalidate cache to force refresh
      await _cacheService.invalidateCache();
      
      return true;
    } catch (e, stackTrace) {
      print('Error deleting food item: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }
}
