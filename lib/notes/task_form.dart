import 'package:flutter/material.dart';
import 'package:uni_project/notes/model/task.dart';
import 'package:uni_project/notes/database/database_service.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task;
  const TaskFormScreen({this.task, super.key});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty && description.isEmpty) {
      if (widget.task?.id != null) {
        await DatabaseService.instance.deleteTask(widget.task!.id!);
      }
    } else {
      if (widget.task == null) {
        await DatabaseService.instance.insertTask(
          Task(title: title, description: description),
        );
      } else {
        widget.task!
          ..title = title
          ..description = description;
        await DatabaseService.instance.updateTask(widget.task!);
      }
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Add Note' : 'Edit Note'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Note'),
              maxLines: null,
            ),
            const SizedBox(height: 32),
            ElevatedButton(onPressed: _saveTask, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
