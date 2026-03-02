import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import 'package:table_calendar/table_calendar.dart';
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xxxl),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: AppShadows.dialog,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xxxl),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.borderHighlight, width: 1),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Calendar',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Unbounded',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${_focusedDay.year}',
                      style: const TextStyle(
                        fontFamily: 'Unbounded',
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Calendar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _showMealDialog(context, selectedDay);
                },
                onPageChanged: (focusedDay) {
                  setState(() => _focusedDay = focusedDay);
                  _loadMealsForMonth(focusedDay);
                },
                calendarFormat: CalendarFormat.month,
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Month',
                },
                eventLoader: _getEventsForDay,

                // Header
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Unbounded',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                  leftChevronIcon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderHighlight, width: 1),
                    ),
                    child: const Icon(Icons.chevron_left, color: Colors.white, size: 16),
                  ),
                  rightChevronIcon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderHighlight, width: 1),
                    ),
                    child: const Icon(Icons.chevron_right, color: Colors.white, size: 16),
                  ),
                  headerPadding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: const BoxDecoration(color: Colors.transparent),
                ),

                // Days of week
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontFamily: 'Unbounded',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  weekendStyle: TextStyle(
                    color: AppColors.primary.withOpacity(0.6),
                    fontFamily: 'Unbounded',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                // Calendar cell styling
                calendarStyle: CalendarStyle(
                  cellMargin: const EdgeInsets.all(3),

                  // Today
                  todayDecoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withOpacity(0.9),
                        AppColors.primaryLight.withOpacity(0.7),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  todayTextStyle: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Unbounded',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),

                  // Selected
                  selectedDecoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.25),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  selectedTextStyle: const TextStyle(
                    color: AppColors.primary,
                    fontFamily: 'Unbounded',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),

                  // Default
                  defaultDecoration: const BoxDecoration(shape: BoxShape.circle),
                  defaultTextStyle: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Unbounded',
                    fontSize: 12,
                  ),

                  // Weekend
                  weekendDecoration: const BoxDecoration(shape: BoxShape.circle),
                  weekendTextStyle: TextStyle(
                    color: AppColors.primary.withOpacity(0.8),
                    fontFamily: 'Unbounded',
                    fontSize: 12,
                  ),

                  // Outside month
                  outsideDecoration: const BoxDecoration(shape: BoxShape.circle),
                  outsideTextStyle: TextStyle(
                    color: Colors.white.withOpacity(0.2),
                    fontFamily: 'Unbounded',
                    fontSize: 12,
                  ),

                  // Disabled
                  disabledTextStyle: TextStyle(
                    color: Colors.white.withOpacity(0.15),
                    fontFamily: 'Unbounded',
                    fontSize: 12,
                  ),

                  // Meal markers — orange dot
                  markersMaxCount: 1,
                  markerDecoration: BoxDecoration(
                    color: AppColors.primaryBright,
                    shape: BoxShape.circle,
                  ),
                  markerSize: 5.0,
                  markerMargin: const EdgeInsets.only(top: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show meal dialog for the selected date
  void _showMealDialog(BuildContext context, DateTime selectedDate) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: AppColors.barrierMedium,
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (ctx, animation, _, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, _, __) => MealDialog(selectedDate: selectedDate),
    );
  }
}
