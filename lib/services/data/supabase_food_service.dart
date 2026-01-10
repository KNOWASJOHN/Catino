import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/food_item.dart';
import '../cache/food_cache_service.dart';

/// Service for managing food items in Supabase
class SupabaseFoodService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final FoodCacheService _cacheService = FoodCacheService();
  bool _isListening = false;

  /// Start listening to food items changes in Supabase
  void startListeningToFoodItems() {
    if (_isListening) return;
    _isListening = true;
    
    _supabase
        .from('food_items')
        .stream(primaryKey: ['id'])
        .listen((data) {
      try {
        List<FoodItem> foodItems = data.map((item) => FoodItem.fromSupabaseMap(item)).toList();
        
        // Update cache with fresh data
        _cacheService.cacheAllFoodItems(foodItems);
        print('Food items cache updated from Supabase listener (${foodItems.length} items)');
      } catch (e) {
        print('Error processing food items update: $e');
      }
    });
  }

  /// Get all food items from cache first, then Supabase if needed
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
      
      print('Fetching all food items from Supabase');
      
      final response = await _supabase
          .from('food_items')
          .select()
          .eq('is_available', true)
          .order('name', ascending: true);
      
      List<FoodItem> foodItems = response.map<FoodItem>((item) => FoodItem.fromSupabaseMap(item)).toList();
      
      print('Returning ${foodItems.length} parsed food items');
      
      // Cache the fresh data
      await _cacheService.cacheAllFoodItems(foodItems);
      
      return foodItems;
    } catch (e, stackTrace) {
      print('Error fetching food items: $e');
      print('Stack trace: $stackTrace');
      // Fallback to cache if Supabase fails
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

  /// Get food items by category from cache first, then Supabase if needed
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
      
      final response = await _supabase
          .from('food_items')
          .select()
          .eq('category', category)
          .eq('is_available', true)
          .order('name', ascending: true);
      
      List<FoodItem> foodItems = response.map<FoodItem>((item) => FoodItem.fromSupabaseMap(item)).toList();
      
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

  /// Get vegetarian food items from cache first, then Supabase if needed
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
      
      print('Fetching vegetarian food items from Supabase');
      
      final response = await _supabase
          .from('food_items')
          .select()
          .eq('is_vegetarian', true)
          .eq('is_available', true)
          .order('name', ascending: true);
      
      List<FoodItem> foodItems = response.map<FoodItem>((item) => FoodItem.fromSupabaseMap(item)).toList();
      
      print('Returning ${foodItems.length} vegetarian items');
      
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

  /// Get non-vegetarian food items from cache first, then Supabase if needed
  Future<List<FoodItem>> getNonVegetarianItems({bool forceRefresh = false}) async {
    try {
      // Try cache first if not forcing refresh
      if (!forceRefresh) {
        final cachedItems = await _cacheService.getCachedVegetarianItems();
        if (cachedItems != null && cachedItems.isNotEmpty) {
          // Filter to only non-vegetarian items
          final nonVegItems = cachedItems.where((item) => !item.isVegetarian).toList();
          if (nonVegItems.isNotEmpty) {
            print('Returning ${nonVegItems.length} non-vegetarian items from cache');
            return nonVegItems;
          }
        }
      }
      
      print('Fetching non-vegetarian food items from Supabase');
      
      final response = await _supabase
          .from('food_items')
          .select()
          .eq('is_vegetarian', false)
          .eq('is_available', true)
          .order('name', ascending: true);
      
      List<FoodItem> foodItems = response.map<FoodItem>((item) => FoodItem.fromSupabaseMap(item)).toList();
      
      print('Returning ${foodItems.length} non-vegetarian items');
      
      // Update the cache with all items (not just non-veg)
      final allItems = await getAllFoodItems();
      await _cacheService.cacheVegetarianItems(allItems);
      
      return foodItems;
    } catch (e, stackTrace) {
      print('Error fetching non-vegetarian items: $e');
      print('Stack trace: $stackTrace');
      // Fallback to cache
      final cachedItems = await _cacheService.getCachedVegetarianItems();
      return cachedItems?.where((item) => !item.isVegetarian).toList() ?? [];
    }
  }

  /// Search food items by name or description
  Future<List<FoodItem>> searchFoodItems(String query) async {
    try {
      print('Searching food items for: $query');
      
      final response = await _supabase
          .from('food_items')
          .select()
          .or('name.ilike.%$query%,description.ilike.%$query%')
          .eq('is_available', true)
          .order('name', ascending: true);
      
      List<FoodItem> foodItems = response.map<FoodItem>((item) => FoodItem.fromSupabaseMap(item)).toList();
      
      print('Found ${foodItems.length} items matching query');
      return foodItems;
    } catch (e, stackTrace) {
      print('Error searching food items: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }
}
