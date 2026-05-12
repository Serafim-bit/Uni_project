import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/exercise.dart';

class ExerciseService {
  static Future<List<Exercise>> loadExercisesByMuscle(String muscleId) async {
    final String response = await rootBundle.loadString(
      'assets/data/exercises.json',
    );
    final List<dynamic> data = json.decode(response);

    return data
        .where((json) => json['muscleGroupId'] == muscleId)
        .map(
          (json) => Exercise(
            id: json['id'],
            muscleGroupId: json['muscleGroupId'],
            title: json['title'],
            gifUrl: json['gifUrl'],
            description: json['description'],
            techniqueSteps: List<String>.from(json['techniqueSteps']),
          ),
        )
        .toList();
  }
}
