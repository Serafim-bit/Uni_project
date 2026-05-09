import 'package:flutter/material.dart';
import 'package:uni_project/meals/screens/categories_screen.dart';
import 'package:uni_project/notes/notes_screen.dart';
import 'package:uni_project/start/card_for_start.dart';
import 'package:uni_project/start/models/category.dart';
import 'package:uni_project/train_help/screens/training_categories_screen.dart';
import 'package:uni_project/trainings/training_log_screen.dart';


class StartScreen extends StatelessWidget {

  
    void _selectCategory(BuildContext context, int id) {
    switch (id) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TrainingCategoriesScreen()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TrainingLogScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CategoriesScreen()),
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
      appBar: AppBar(
        title: Text('Choose the category'),
      ),
      body: GridView(
        padding: const EdgeInsets.all(24),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1, 
          childAspectRatio: 1.9,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15),
        children: [
          for (final category in CategoriesList)
            CardForStart(
              text: category.cat_text, 
              imagePath: category.imagePath, 
              onSelectCategory: () => _selectCategory(context, category.id))
        ],
      ),
    );
  }
}