import 'package:flutter/material.dart';
import '../data/training_data.dart';
import '../widgets/training_category_card.dart';
import 'exercises_list_screen.dart';

class TrainingCategoriesScreen extends StatelessWidget {
  const TrainingCategoriesScreen({super.key, this.parentId});

  final String? parentId;

  @override
  Widget build(BuildContext context) {
    // Фильтруем категории: если parentId null — берем главные зоны, иначе — мышцы этой зоны
    final filteredCategories = dummyTrainingCategories
        .where((cat) => cat.parentId == parentId)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(parentId == null ? 'Зоны тела' : 'Выберите мышцу')),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: filteredCategories.length,
        itemBuilder: (ctx, index) {
          final category = filteredCategories[index];
          return TrainingCategoryCard(
            title: category.title,
            imagePath: category.imagePath,
            onSelect: () {
              if (parentId == null) {
                // Идем глубже к выбору мышц
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (ctx) => TrainingCategoriesScreen(parentId: category.id),
                ));
              } else {
                // Идем к списку упражнений
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (ctx) => ExercisesListScreen(muscleId: category.id),
                ));
              }
            },
          );
        },
      ),
    );
  }
}