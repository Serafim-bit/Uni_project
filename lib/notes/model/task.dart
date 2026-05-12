class Task {
  final int? id;
  String title;
  String description;

  Task({this.id, required this.title, required this.description});

  // Converts the task to a database map.
  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title, 'description': description};
  }

  // Creates a task from a database map.
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
    );
  }
}
