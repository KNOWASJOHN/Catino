import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import 'package:cantino/models/meal_model.dart';
import 'package:cantino/services/meal_service.dart';
import 'dart:ui';
import 'package:intl/intl.dart';

/// Dialog that displays meal information for a selected date
class MealDialog extends StatefulWidget {
  final DateTime selectedDate;

  const MealDialog({super.key, required this.selectedDate});

  @override
  State<MealDialog> createState() => _MealDialogState();
}

class _MealDialogState extends State<MealDialog> {
  final MealService _mealService = MealService();
  MealModel? _mealData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMealData();
  }

  Future<void> _loadMealData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final meal = await _mealService.getMealByDate(widget.selectedDate);
      setState(() {
        _mealData = meal;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load meal data';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat(
      'EEEE, MMMM d, y',
    ).format(widget.selectedDate);

    return Dialog(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.90,
          maxHeight: MediaQuery.of(context).size.height * 0.65,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface, // Solid dark gray
          borderRadius: BorderRadius.circular(20),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Meal Plan',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Unbounded',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontFamily: 'Unbounded',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white, size: 24),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 3,
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_mealData == null || !_mealData!.hasData) {
      return _buildEmptyState();
    }

    return _buildMealList();
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 72,
            color: Colors.white.withOpacity(0.8),
          ),
          const SizedBox(height: 20),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Unbounded',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadMealData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Retry',
              style: TextStyle(
                fontFamily: 'Unbounded',
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 72,
            color: Colors.white.withOpacity(0.6),
          ),
          const SizedBox(height: 20),
          Text(
            'No meal plan available',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Unbounded',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'There\'s no meal plan set for this date yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontFamily: 'Unbounded',
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_mealData!.breakfast != null)
          _buildMealItem(
            icon: Icons.wb_sunny,
            title: 'Breakfast',
            description: _mealData!.breakfast!,
            color: const Color(0xFFFFB347),
          ),
        if (_mealData!.lunch != null) ...[
          const SizedBox(height: 16),
          _buildMealItem(
            icon: Icons.lunch_dining,
            title: 'Lunch',
            description: _mealData!.lunch!,
            color: const Color(0xFF87CEEB),
          ),
        ],
        if (_mealData!.eveningSnack != null) ...[
          const SizedBox(height: 16),
          _buildMealItem(
            icon: Icons.coffee,
            title: 'Evening Snack',
            description: _mealData!.eveningSnack!,
            color: const Color(0xFFDDA0DD),
          ),
        ],
        if (_mealData!.dinner != null) ...[
          const SizedBox(height: 16),
          _buildMealItem(
            icon: Icons.dinner_dining,
            title: 'Dinner',
            description: _mealData!.dinner!,
            color: const Color(0xFF98D8C8),
          ),
        ],
      ],
    );
  }

  Widget _buildMealItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Unbounded',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.93),
                    fontFamily: 'Unbounded',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
