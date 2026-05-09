import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/exercise.dart';

class ExerciseService {
  static Future<List<Exercise>> loadExercisesByMuscle(String muscleId) async {
    // 1. Читаем файл
    final String response = await rootBundle.loadString('assets/data/exercises.json');
    final List<dynamic> data = json.decode(response);
    
    // 2. Превращаем JSON в объекты Exercise и фильтруем по muscleId
    return data
        .where((json) => json['muscleGroupId'] == muscleId)
        .map((json) => Exercise(
              id: json['id'],
              muscleGroupId: json['muscleGroupId'],
              title: json['title'],
              gifUrl: json['gifUrl'],
              description: json['description'],
              techniqueSteps: List<String>.from(json['techniqueSteps']),
            ))
        .toList();
  }
}