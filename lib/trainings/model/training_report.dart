class TrainingReport {
  final int? id;
  final DateTime date;
  final String? imagePath;
  final int durationMinutes;
  final String focus;
  final String exercises;

  const TrainingReport({
    this.id,
    required this.date,
    this.imagePath,
    required this.durationMinutes,
    required this.focus,
    required this.exercises,
  });

  String get durationLabel {
    if (durationMinutes <= 0) return 'No duration';
    return '$durationMinutes min';
  }

  String get displayFocus {
    final trimmedFocus = focus.trim();
    if (trimmedFocus.isNotEmpty) return trimmedFocus;

    final trimmedExercises = exercises.trim();
    if (trimmedExercises.isEmpty) return 'Workout';

    final firstLine = trimmedExercises.split('\n').first.trim();
    if (firstLine.isEmpty) return 'Workout';
    return firstLine.length <= 28
        ? firstLine
        : '${firstLine.substring(0, 28)}...';
  }

  bool get hasImage => imagePath != null && imagePath!.trim().isNotEmpty;

  TrainingReport copyWith({
    int? id,
    DateTime? date,
    String? imagePath,
    bool clearImage = false,
    int? durationMinutes,
    String? focus,
    String? exercises,
  }) {
    return TrainingReport(
      id: id ?? this.id,
      date: date ?? this.date,
      imagePath: clearImage ? null : imagePath ?? this.imagePath,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      focus: focus ?? this.focus,
      exercises: exercises ?? this.exercises,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'imagePath': imagePath ?? '',
      'duration': durationLabel,
      'durationMinutes': durationMinutes,
      'focus': focus,
      'exercises': exercises,
    };
  }

  factory TrainingReport.fromMap(Map<String, dynamic> map) {
    final exercises = (map['exercises'] as String? ?? '').trim();
    final focus = (map['focus'] as String? ?? '').trim();
    final imagePath = (map['imagePath'] as String? ?? '').trim();

    return TrainingReport(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      imagePath: imagePath.isEmpty ? null : imagePath,
      durationMinutes: _readDurationMinutes(
        map['durationMinutes'],
        map['duration'],
      ),
      focus: focus.isEmpty ? _deriveFocus(exercises) : focus,
      exercises: exercises,
    );
  }

  static int _readDurationMinutes(Object? durationMinutes, Object? legacy) {
    if (durationMinutes is int) return durationMinutes;
    if (durationMinutes is num) return durationMinutes.round();

    final legacyText = legacy?.toString() ?? '';
    final match = RegExp(r'\d+').firstMatch(legacyText);
    if (match == null) return 0;
    return int.tryParse(match.group(0)!) ?? 0;
  }

  static String _deriveFocus(String exercises) {
    if (exercises.isEmpty) return '';
    final firstLine = exercises.split('\n').first.trim();
    final firstPart = firstLine.split(',').first.trim();
    return firstPart.length <= 32 ? firstPart : firstPart.substring(0, 32);
  }
}
