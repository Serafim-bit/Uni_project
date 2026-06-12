class MealEntry {
  const MealEntry({
    this.id,
    required this.date,
    required this.type,
    required this.title,
    this.calories,
    this.protein,
    required this.notes,
  });

  final int? id;
  final DateTime date;
  final String type;
  final String title;
  final int? calories;
  final int? protein;
  final String notes;

  String get caloriesLabel => calories == null ? 'No kcal' : '$calories kcal';

  String get proteinLabel =>
      protein == null ? 'No protein' : '${protein}g protein';

  MealEntry copyWith({
    int? id,
    DateTime? date,
    String? type,
    String? title,
    int? calories,
    bool clearCalories = false,
    int? protein,
    bool clearProtein = false,
    String? notes,
  }) {
    return MealEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      title: title ?? this.title,
      calories: clearCalories ? null : calories ?? this.calories,
      protein: clearProtein ? null : protein ?? this.protein,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'type': type,
      'title': title,
      'calories': calories,
      'protein': protein,
      'notes': notes,
    };
  }

  factory MealEntry.fromMap(Map<String, dynamic> map) {
    return MealEntry(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      type: map['type'] as String? ?? 'Meal',
      title: map['title'] as String? ?? '',
      calories: map['calories'] as int?,
      protein: map['protein'] as int?,
      notes: map['notes'] as String? ?? '',
    );
  }
}
