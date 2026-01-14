/// Model class representing a meal plan for a specific date
class MealModel {
  final String id;
  final DateTime date;
  final String? breakfast;
  final String? lunch;
  final String? eveningSnack;
  final String? dinner;
  final DateTime createdAt;
  final DateTime updatedAt;

  MealModel({
    required this.id,
    required this.date,
    this.breakfast,
    this.lunch,
    this.eveningSnack,
    this.dinner,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory constructor to create MealModel from Supabase JSON
  factory MealModel.fromJson(Map<String, dynamic> json) {
    return MealModel(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      breakfast: json['breakfast'] as String?,
      lunch: json['lunch'] as String?,
      eveningSnack: json['evening_snack'] as String?,
      dinner: json['dinner'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert MealModel to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String().split('T')[0], // Date only
      'breakfast': breakfast,
      'lunch': lunch,
      'evening_snack': eveningSnack,
      'dinner': dinner,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Check if the meal has any data
  bool get hasData {
    return breakfast != null ||
        lunch != null ||
        eveningSnack != null ||
        dinner != null;
  }

  @override
  String toString() {
    return 'MealModel(id: $id, date: $date, breakfast: $breakfast, lunch: $lunch, eveningSnack: $eveningSnack, dinner: $dinner)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MealModel &&
        other.id == id &&
        other.date == date &&
        other.breakfast == breakfast &&
        other.lunch == lunch &&
        other.eveningSnack == eveningSnack &&
        other.dinner == dinner;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        date.hashCode ^
        breakfast.hashCode ^
        lunch.hashCode ^
        eveningSnack.hashCode ^
        dinner.hashCode;
  }
}
