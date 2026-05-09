class Task {
  final int? id;
  String title;
  String description;

  Task({
    this.id,
    required this.title,
    required this.description,
  });

  // Преобразование в Map (для БД)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
    };
  }

  // Создание объекта из Map (из БД)
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
    );
  }
}