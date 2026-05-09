import 'package:flutter/material.dart';
import '../models/exercise.dart';

class ExerciseDetailsScreen extends StatelessWidget {
  const ExerciseDetailsScreen({super.key, required this.exercise});
  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(exercise.title)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.asset(
              exercise.gifUrl, // Теперь подставится путь 'assets/exercises/...'
              height: 300,
              width: double.infinity,
              fit: BoxFit.contain,
              // Добавим обработку ошибки, если вдруг опечатался в названии файла
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 300,
                  color: Colors.grey[900],
                  child: const Center(
                    child: Text(
                      'Файл гифки не найден',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Техника выполнения:', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  for (int i = 0; i < exercise.techniqueSteps.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(radius: 12, child: Text('${i + 1}', style: const TextStyle(fontSize: 12))),
                          const SizedBox(width: 10),
                          Expanded(child: Text(exercise.techniqueSteps[i], style: const TextStyle(fontSize: 16))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}