class TrainingReport {
  final int? id;
  final DateTime date;
  final String imagePath;
  final String duration;
  final String exercises;

  const TrainingReport({
    this.id,
    required this.date,
    required this.imagePath,
    required this.duration,
    required this.exercises,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'imagePath': imagePath,
      'duration': duration,
      'exercises': exercises,
    };
  }

  factory TrainingReport.fromMap(Map<String, dynamic> map) {
    return TrainingReport(
      id: map['id'],
      date: DateTime.parse(map['date']),
      imagePath: map['imagePath'],
      duration: map['duration'],
      exercises: map['exercises'],
    );
  }
}
