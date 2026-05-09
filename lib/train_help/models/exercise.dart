class Exercise {
  const Exercise({
    required this.id,
    required this.title,
    required this.muscleGroupId,
    required this.gifUrl,
    required this.description,
    required this.techniqueSteps,
  });

  final String id;
  final String title;
  final String muscleGroupId;
  final String gifUrl;
  final String description;
  final List<String> techniqueSteps;
}