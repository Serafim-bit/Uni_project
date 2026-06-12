import 'package:flutter_test/flutter_test.dart';
import 'package:uni_project/trainings/model/training_report.dart';

void main() {
  test('reads legacy workout rows safely', () {
    final report = TrainingReport.fromMap({
      'id': 1,
      'date': '2026-05-14T12:00:00.000',
      'imagePath': '',
      'duration': '45 min',
      'exercises': 'Back, biceps, 6 exercises',
    });

    expect(report.durationMinutes, 45);
    expect(report.durationLabel, '45 min');
    expect(report.focus, 'Back');
    expect(report.hasImage, isFalse);
  });

  test('serializes current workout rows with optional image data', () {
    final report = TrainingReport(
      id: 4,
      date: DateTime(2026, 5, 29, 18, 15),
      imagePath: 'C:/tmp/workout.jpg',
      durationMinutes: 60,
      focus: 'Legs',
      exercises: 'Squats\nRomanian deadlift',
    );

    final copy = TrainingReport.fromMap(report.toMap());

    expect(copy.id, 4);
    expect(copy.date, DateTime(2026, 5, 29, 18, 15));
    expect(copy.imagePath, 'C:/tmp/workout.jpg');
    expect(copy.durationLabel, '60 min');
    expect(copy.displayFocus, 'Legs');
    expect(copy.hasImage, isTrue);
  });

  test('copyWith can remove a workout image without losing other fields', () {
    final report = TrainingReport(
      id: 5,
      date: DateTime(2026, 5, 29),
      imagePath: 'old-photo.jpg',
      durationMinutes: 40,
      focus: 'Core',
      exercises: 'Leg raises',
    );

    final edited = report.copyWith(clearImage: true, durationMinutes: 42);

    expect(edited.id, 5);
    expect(edited.imagePath, isNull);
    expect(edited.durationMinutes, 42);
    expect(edited.focus, 'Core');
  });

  test('falls back to workout labels when focus and duration are missing', () {
    final report = TrainingReport(
      date: DateTime(2026, 5, 29),
      durationMinutes: 0,
      focus: '',
      exercises: 'A very long first exercise line that should be shortened',
    );

    expect(report.durationLabel, 'No duration');
    expect(report.displayFocus, 'A very long first exercise l...');
  });
}
