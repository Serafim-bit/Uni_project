import 'package:flutter/material.dart';

class Category {
  const Category({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.id,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String imagePath;
  final int id;
  final IconData icon;
}

const categoriesList = [
  Category(
    title: 'Exercise Guide',
    subtitle: 'Learn technique and muscle groups',
    imagePath: 'assets/images/trening_help.jpg',
    id: 0,
    icon: Icons.fitness_center,
  ),
  Category(
    title: 'Workout Log',
    subtitle: 'Save training reports with photos',
    imagePath: 'assets/images/photo.jpg',
    id: 1,
    icon: Icons.add_a_photo,
  ),
  Category(
    title: 'Meals',
    subtitle: 'Browse recipes by category',
    imagePath: 'assets/images/food.jpg',
    id: 2,
    icon: Icons.restaurant,
  ),
  Category(
    title: 'Notes',
    subtitle: 'Keep simple tasks and reminders',
    imagePath: 'assets/images/notepad.jpg',
    id: 3,
    icon: Icons.notes,
  ),
];
