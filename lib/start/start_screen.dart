import 'package:flutter/material.dart';
import 'package:uni_project/meals/screens/categories_screen.dart';
import 'package:uni_project/notes/notes_screen.dart';
import 'package:uni_project/start/card_for_start.dart';
import 'package:uni_project/start/models/category.dart';
import 'package:uni_project/train_help/screens/training_categories_screen.dart';
import 'package:uni_project/trainings/training_log_screen.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  void _selectCategory(BuildContext context, int id) {
    switch (id) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TrainingCategoriesScreen(),
          ),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TrainingLogScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CategoriesScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NotesScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fit Diary')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Text(
            'Choose what you want to work on today.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          for (final category in categoriesList)
            SizedBox(
              height: 154,
              child: CardForStart(
                title: category.title,
                subtitle: category.subtitle,
                imagePath: category.imagePath,
                icon: category.icon,
                onSelectCategory: () => _selectCategory(context, category.id),
              ),
            ),
        ],
      ),
    );
  }
}
