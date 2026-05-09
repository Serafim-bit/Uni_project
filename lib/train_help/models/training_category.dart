class TrainingCategory {
  const TrainingCategory({
    required this.id,
    required this.title,
    required this.imagePath,
    this.parentId,
  });

  final String id;
  final String title;
  final String imagePath;
  final String? parentId; // Если null — это главная зона (Верх/Низ)
}