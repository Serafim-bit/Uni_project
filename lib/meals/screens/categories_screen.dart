import 'package:flutter/material.dart';
import 'package:uni_project/meals/models/category.dart';
import 'package:uni_project/meals/screens/meals_screen.dart';
import 'package:uni_project/meals/widgets/category_grid_item.dart';
import 'package:uni_project/meals/services/meals_data_service.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Category> _availableCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await DataService.loadCategories();
    setState(() {
      _availableCategories = categories;
      _isLoading = false;
    });
  }

  void _selectCategory(BuildContext context, Category category) async {
    final allMeals = await DataService.loadMeals();
    final filteredMeals = allMeals
        .where((meal) => meal.categories.contains(category.id))
        .toList();
    
    if (!mounted) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => MealsScreen(
          title: category.title,
          meals: filteredMeals,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick your category'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView(
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3 / 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              children: [
                for (final category in _availableCategories)
                  CategoryGridItem(
                    category: category,
                    onSelectCategory: () {
                      _selectCategory(context, category);
                    },
                  )
              ],
            ),
    );
  }
}