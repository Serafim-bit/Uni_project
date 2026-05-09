import '../models/training_category.dart';
import '../models/exercise.dart';

const dummyTrainingCategories = [
  // ЗОНЫ (parentId: null)
  TrainingCategory(id: 'upper', title: 'ВЕРХ ТЕЛА', imagePath: 'assets/images/upper_body.png'),
  TrainingCategory(id: 'core', title: 'КОРПУС', imagePath: 'assets/images/core.png'),
  TrainingCategory(id: 'lower', title: 'НИЗ ТЕЛА', imagePath: 'assets/images/legs.png'),
  
  
  // МЫШЦЫ ВЕРХА (parentId: 'upper')
  TrainingCategory(id: 'arms', title: 'РУКИ', imagePath: 'assets/images/arms.jpg', parentId: 'upper'),
  TrainingCategory(id: 'back', title: 'СПИНА', imagePath: 'assets/images/back.jpg', parentId: 'upper'),

  // МЫШЦЫ КОРПУСА (parentId: 'core')
  TrainingCategory(id: 'abs', title: 'ПРЕСС', imagePath: 'assets/images/abs.jpg', parentId: 'core'),
  
  // МЫШЦЫ НИЗА (parentId: 'lower')
  TrainingCategory(id: 'legs', title: 'НОГИ', imagePath: 'assets/images/legs.jpg', parentId: 'lower'),
];
