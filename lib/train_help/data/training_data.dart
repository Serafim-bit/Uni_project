import '../models/training_category.dart';

const dummyTrainingCategories = [
  TrainingCategory(
    id: 'upper',
    title: 'Upper Body',
    imagePath: 'assets/images/upper_body.png',
  ),
  TrainingCategory(
    id: 'core',
    title: 'Core',
    imagePath: 'assets/images/core.png',
  ),
  TrainingCategory(
    id: 'lower',
    title: 'Lower Body',
    imagePath: 'assets/images/legs.png',
  ),

  TrainingCategory(
    id: 'arms',
    title: 'Arms',
    imagePath: 'assets/images/arms.jpg',
    parentId: 'upper',
  ),
  TrainingCategory(
    id: 'back',
    title: 'Back',
    imagePath: 'assets/images/back.jpg',
    parentId: 'upper',
  ),
  TrainingCategory(
    id: 'abs',
    title: 'Abs',
    imagePath: 'assets/images/abs.jpg',
    parentId: 'core',
  ),
  TrainingCategory(
    id: 'legs',
    title: 'Legs',
    imagePath: 'assets/images/legs.jpg',
    parentId: 'lower',
  ),
];
