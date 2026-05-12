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
      appBar: AppBar(title: const Text('Exercises')),
      body: FutureBuilder<List<Exercise>>(
        future: ExerciseService.loadExercisesByMuscle(muscleId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Could not load exercises'));
          }

          final exercises = snapshot.data ?? [];

          if (exercises.isEmpty) {
            return const Center(
              child: Text('No exercises have been added for this group yet'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            itemCount: exercises.length,
            itemBuilder: (ctx, index) {
              final exercise = exercises[index];
              return Card(
                elevation: 0,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Icon(
                    Icons.fitness_center,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(exercise.title),
                  subtitle: Text(
                    exercise.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) =>
                            ExerciseDetailsScreen(exercise: exercise),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
