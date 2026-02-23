import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:ui';
import 'package:cantino/components/common/meal_dialog.dart';
import 'package:cantino/services/meal_service.dart';
import 'package:cantino/models/meal_model.dart';

/// A styled table calendar component that matches the app's design system.
///
/// Features:
/// - Glassmorphism design matching OrderHistoryList
/// - Date selection functionality
/// - Consistent styling with Unbounded font
/// - Responsive layout
class TableCalendarComponent extends StatefulWidget {
  const TableCalendarComponent({super.key});

  @override
  State<TableCalendarComponent> createState() => _TableCalendarComponentState();
}

class _TableCalendarComponentState extends State<TableCalendarComponent> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final MealService _mealService = MealService();
  List<MealModel> _mealsInMonth = [];

  @override
  void initState() {
    super.initState();
    _loadMealsForMonth(_focusedDay);
  }

  /// Load meals for the visible month
  Future<void> _loadMealsForMonth(DateTime focusedDay) async {
    final firstDay = DateTime(focusedDay.year, focusedDay.month, 1);
    final lastDay = DateTime(focusedDay.year, focusedDay.month + 1, 0);

    final meals = await _mealService.getMealsInRange(firstDay, lastDay);
    setState(() {
      _mealsInMonth = meals;
    });
  }

  /// Check if a date has a meal
  bool _hasMeal(DateTime day) {
    return _mealsInMonth.any((meal) => isSameDay(meal.date, day));
  }

  /// Event loader for calendar markers
  List<String> _getEventsForDay(DateTime day) {
    if (_hasMeal(day)) {
      return ['meal']; // Return a marker for this day
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.95,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Column(
            children: [
              // Heading
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Text(
                  'Calendar',
                  style: TextStyle(
                    color: Colors.black87,
                    backgroundColor: Colors.transparent,
                    fontFamily: 'Unbounded',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),

              // Calendar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    // Show meal dialog when a date is selected
                    _showMealDialog(context, selectedDay);
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                    _loadMealsForMonth(focusedDay);
                  },
                  calendarFormat: CalendarFormat.month,
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Month',
                  },
                  // Event loader for markers
                  eventLoader: _getEventsForDay,

                  // Header styling
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: const TextStyle(
                      color: Colors.black87,
                      fontFamily: 'Unbounded',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                    leftChevronIcon: const Icon(
                      Icons.chevron_left,
                      color: Colors.black87,
                    ),
                    rightChevronIcon: const Icon(
                      Icons.chevron_right,
                      color: Colors.black87,
                    ),
                    decoration: BoxDecoration(color: Colors.transparent),
                  ),

                  // Days of week styling
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                      color: Colors.black87.withOpacity(0.7),
                      fontFamily: 'Unbounded',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    weekendStyle: TextStyle(
                      color: Colors.black87.withOpacity(0.7),
                      fontFamily: 'Unbounded',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  // Calendar styling
                  calendarStyle: CalendarStyle(
                    // Today styling
                    todayDecoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryBright.withOpacity(0.6),
                          AppColors.primaryBright.withOpacity(0.4),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryBright,
                        width: 2,
                      ),
                    ),
                    todayTextStyle: const TextStyle(
                      color: Colors.black87,
                      fontFamily: 'Unbounded',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),

                    // Selected day styling
                    selectedDecoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black87.withOpacity(0.8),
                          Colors.black87.withOpacity(0.6),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    selectedTextStyle: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Unbounded',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),

                    // Default day styling
                    defaultDecoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    defaultTextStyle: const TextStyle(
                      color: Colors.black87,
                      fontFamily: 'Unbounded',
                      fontSize: 14,
                    ),

                    // Weekend styling
                    weekendDecoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    weekendTextStyle: TextStyle(
                      color: Colors.black87.withOpacity(0.7),
                      fontFamily: 'Unbounded',
                      fontSize: 14,
                    ),

                    // Outside month styling
                    outsideDecoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    outsideTextStyle: TextStyle(
                      color: Colors.black87.withOpacity(0.3),
                      fontFamily: 'Unbounded',
                      fontSize: 14,
                    ),

                    // Disabled styling
                    disabledTextStyle: TextStyle(
                      color: Colors.black87.withOpacity(0.2),
                      fontFamily: 'Unbounded',
                      fontSize: 14,
                    ),

                    // Markers - Red for dates with meals
                    markersMaxCount: 1,
                    markerDecoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    markerSize: 6.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show meal dialog for the selected date
  void _showMealDialog(BuildContext context, DateTime selectedDate) {
    showDialog(
      context: context,
      builder: (context) => MealDialog(selectedDate: selectedDate),
    );
  }
}
