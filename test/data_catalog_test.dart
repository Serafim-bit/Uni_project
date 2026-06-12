import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_project/meals/services/meals_data_service.dart';
import 'package:uni_project/train_help/data/training_data.dart';
import 'package:uni_project/train_help/services/exercise_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('recipe data', () {
    test(
      'loads a rich recipe catalog with valid category references',
      () async {
        final categories = await DataService.loadCategories();
        final meals = await DataService.loadMeals();
        final categoryIds = categories.map((category) => category.id).toSet();
        final mealIds = meals.map((meal) => meal.id).toSet();

        expect(categories, hasLength(10));
        expect(meals, hasLength(greaterThanOrEqualTo(30)));
        expect(
          mealIds,
          hasLength(meals.length),
          reason: 'Meal ids must be unique.',
        );

        for (final meal in meals) {
          expect(meal.title.trim(), isNotEmpty, reason: meal.id);
          expect(meal.duration, greaterThan(0), reason: meal.title);
          expect(meal.ingredients, isNotEmpty, reason: meal.title);
          expect(meal.steps, isNotEmpty, reason: meal.title);
          expect(meal.imageUrl.trim(), isNotEmpty, reason: meal.title);
          expect(meal.categories, isNotEmpty, reason: meal.title);

          for (final categoryId in meal.categories) {
            expect(
              categoryIds,
              contains(categoryId),
              reason: '${meal.title} points to missing category $categoryId',
            );
          }
        }
      },
    );

    test('all local recipe images exist on disk', () async {
      final meals = await DataService.loadMeals();

      for (final meal in meals) {
        if (meal.imageUrl.startsWith('assets/')) {
          expect(
            File(meal.imageUrl).existsSync(),
            isTrue,
            reason: '${meal.title} uses missing asset ${meal.imageUrl}',
          );
        } else {
          expect(Uri.tryParse(meal.imageUrl)?.isAbsolute, isTrue);
        }
      }
    });
  });

  group('exercise data', () {
    test('loads exercises for every leaf training group', () async {
      final leafGroups = dummyTrainingCategories
          .where((category) => category.parentId != null)
          .toList();

      expect(
        leafGroups.map((group) => group.id),
        containsAll(['arms', 'back', 'abs', 'legs']),
      );

      for (final group in leafGroups) {
        final exercises = await ExerciseService.loadExercisesByMuscle(group.id);

        expect(
          exercises,
          isNotEmpty,
          reason: '${group.title} should have at least one exercise.',
        );

        for (final exercise in exercises) {
          expect(exercise.title.trim(), isNotEmpty, reason: exercise.id);
          expect(
            exercise.description.trim(),
            isNotEmpty,
            reason: exercise.title,
          );
          expect(exercise.techniqueSteps, isNotEmpty, reason: exercise.title);
        }
      }
    });

    test('local training images and gifs referenced by data exist', () async {
      for (final category in dummyTrainingCategories) {
        expect(
          File(category.imagePath).existsSync(),
          isTrue,
          reason: '${category.title} uses missing image ${category.imagePath}',
        );
      }

      final rawExercises =
          jsonDecode(await rootBundle.loadString('assets/data/exercises.json'))
              as List<dynamic>;

      for (final rawExercise in rawExercises.cast<Map<String, dynamic>>()) {
        final mediaPath = rawExercise['gifUrl'] as String;

        expect(
          mediaPath.startsWith('assets/'),
          isTrue,
          reason: '${rawExercise['title']} should use a local gif asset.',
        );
        expect(
          File(mediaPath).existsSync(),
          isTrue,
          reason: '${rawExercise['title']} uses missing gif $mediaPath',
        );
      }
    });
  });
}
