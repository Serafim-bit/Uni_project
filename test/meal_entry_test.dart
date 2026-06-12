import 'package:flutter_test/flutter_test.dart';
import 'package:uni_project/meals/models/meal_entry.dart';

void main() {
  test('serializes meal entries', () {
    final entry = MealEntry(
      id: 1,
      date: DateTime(2026, 5, 27),
      type: 'Lunch',
      title: 'Chicken bowl',
      calories: 620,
      protein: 42,
      notes: 'Good post-workout meal',
    );

    final copy = MealEntry.fromMap(entry.toMap());

    expect(copy.title, 'Chicken bowl');
    expect(copy.caloriesLabel, '620 kcal');
    expect(copy.proteinLabel, '42g protein');
  });

  test('uses safe labels and defaults for optional nutrition fields', () {
    final entry = MealEntry.fromMap({
      'id': 2,
      'date': '2026-05-28T08:30:00.000',
      'title': 'Coffee',
    });

    expect(entry.type, 'Meal');
    expect(entry.notes, '');
    expect(entry.caloriesLabel, 'No kcal');
    expect(entry.proteinLabel, 'No protein');
  });

  test('copyWith can update and clear optional nutrition values', () {
    final entry = MealEntry(
      id: 3,
      date: DateTime(2026, 5, 28),
      type: 'Dinner',
      title: 'Rice bowl',
      calories: 700,
      protein: 35,
      notes: 'Filling',
    );

    final edited = entry.copyWith(
      title: 'Light rice bowl',
      clearCalories: true,
      clearProtein: true,
      notes: '',
    );

    expect(edited.id, 3);
    expect(edited.title, 'Light rice bowl');
    expect(edited.calories, isNull);
    expect(edited.protein, isNull);
    expect(edited.notes, '');
  });
}
