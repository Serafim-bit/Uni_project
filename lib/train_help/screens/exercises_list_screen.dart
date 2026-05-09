import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../services/exercise_service.dart';
import 'exercise_details_screen.dart';

class ExercisesListScreen extends StatelessWidget {
  const ExercisesListScreen({super.key, required this.muscleId});

  final String muscleId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Упражнения'),
      ),
      // Используем FutureBuilder для асинхронной загрузки из JSON
      body: FutureBuilder<List<Exercise>>(
        future: ExerciseService.loadExercisesByMuscle(muscleId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return const Center(child: Text('Ошибка загрузки данных'));
          }

          final exercises = snapshot.data ?? [];

          if (exercises.isEmpty) {
            return const Center(child: Text('Упражнения для этой группы пока не добавлены'));
          }

          return ListView.builder(
            itemCount: exercises.length,
            itemBuilder: (ctx, index) {
              final exercise = exercises[index];
              return ListTile(
                leading: const Icon(Icons.fitness_center, color: Colors.orangeAccent),
                title: Text(exercise.title),
                subtitle: Text(exercise.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => ExerciseDetailsScreen(exercise: exercise),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}