import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cantino/models/meal_model.dart';
import 'package:cantino/services/log.dart';

/// Service class to handle meal-related operations with Supabase
class MealService {
  final _supabase = Supabase.instance.client;

  /// Fetch meal data for a specific date (shared across all users)
  /// Returns null if no meal data exists for the given date
  Future<MealModel?> getMealByDate(DateTime date) async {
    try {
      // Format date to YYYY-MM-DD
      final dateString = date.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('meals')
          .select()
          .eq('date', dateString)
          .maybeSingle();

      if (response == null) {
        logInfo('No meal data found for date: $dateString');
        return null;
      }

      return MealModel.fromJson(response);
    } catch (e, stackTrace) {
      logError('Error fetching meal data: $e', stackTrace);
      return null;
    }
  }

  /// Fetch meals for a date range (useful for future enhancements)
  Future<List<MealModel>> getMealsInRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final startDateString = startDate.toIso8601String().split('T')[0];
      final endDateString = endDate.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('meals')
          .select()
          .gte('date', startDateString)
          .lte('date', endDateString)
          .order('date');

      return (response as List)
          .map((item) => MealModel.fromJson(item))
          .toList();
    } catch (e, stackTrace) {
      logError('Error fetching meals in range: $e', stackTrace);
      return [];
    }
  }

  /// Create or update a meal entry
  Future<bool> upsertMeal(MealModel meal) async {
    try {
      await _supabase.from('meals').upsert(meal.toJson());
      logInfo('Meal upserted successfully for date: ${meal.date}');
      return true;
    } catch (e, stackTrace) {
      logError('Error upserting meal: $e', stackTrace);
      return false;
    }
  }

  /// Delete a meal entry
  Future<bool> deleteMeal(String mealId) async {
    try {
      await _supabase.from('meals').delete().eq('id', mealId);
      logInfo('Meal deleted successfully: $mealId');
      return true;
    } catch (e, stackTrace) {
      logError('Error deleting meal: $e', stackTrace);
      return false;
    }
  }
}
