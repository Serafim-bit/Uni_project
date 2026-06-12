import 'package:flutter/material.dart';
import '../data/training_data.dart';
import '../widgets/training_category_card.dart';
import 'exercises_list_screen.dart';

class TrainingCategoriesScreen extends StatelessWidget {
  const TrainingCategoriesScreen({super.key, this.parentId});

  final String? parentId;

  @override
  Widget build(BuildContext context) {
    final filteredCategories = dummyTrainingCategories
        .where((cat) => cat.parentId == parentId)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(parentId == null ? 'Exercise Guide' : 'Choose a Muscle'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            parentId == null
                ? 'Choose a training area.'
                : 'Pick a muscle group to see exercises.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          for (final category in filteredCategories)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TrainingCategoryCard(
                title: category.title,
                imagePath: category.imagePath,
                onSelect: () {
                  if (parentId == null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) =>
                            TrainingCategoriesScreen(parentId: category.id),
                      ),
                    );
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) =>
                            ExercisesListScreen(muscleId: category.id),
                      ),
                    );
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}
