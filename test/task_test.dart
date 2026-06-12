import 'package:flutter_test/flutter_test.dart';
import 'package:uni_project/notes/model/task.dart';

void main() {
  test('serializes notes to and from database maps', () {
    final task = Task(id: 7, title: 'Stretch', description: '10 minutes');

    final copy = Task.fromMap(task.toMap());

    expect(copy.id, 7);
    expect(copy.title, 'Stretch');
    expect(copy.description, '10 minutes');
  });
}
