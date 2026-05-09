import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

// Модель данных прямо в файле для удобства
class TrainingReport {
  final DateTime date;
  final String imagePath;
  final String duration;
  final String exercises;

  TrainingReport({
    required this.date,
    required this.imagePath,
    required this.duration,
    required this.exercises,
  });
}

class TrainingLogScreen extends StatefulWidget {
  @override
  _TrainingLogScreenState createState() => _TrainingLogScreenState();
}

class _TrainingLogScreenState extends State<TrainingLogScreen> {
  final List<TrainingReport> _reports = [];
  final _durationController = TextEditingController();
  final _exercisesController = TextEditingController();
  File? _pickedImage;

  // Метод для вызова камеры
  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (image != null) {
      setState(() => _pickedImage = File(image.path));
    }
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder( // Используем для обновления фото внутри шторки
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Новая тренировка', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                
                // Зона фото
                GestureDetector(
                  onTap: () async {
                    await _takePhoto();
                    setModalState(() {}); // Обновляем превью в модалке
                  },
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                    child: _pickedImage == null 
                      ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt), Text('Сделать фото')])
                      : ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(_pickedImage!, fit: BoxFit.cover)),
                  ),
                ),
                
                TextField(
                  controller: _durationController,
                  decoration: const InputDecoration(labelText: 'Длительность (мин/часы)'),
                ),
                TextField(
                  controller: _exercisesController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Что сделал?'),
                ),
                const SizedBox(height: 20),
                
                ElevatedButton(
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  onPressed: () {
                    if (_pickedImage == null) return;
                    setState(() {
                      _reports.insert(0, TrainingReport(
                        date: DateTime.now(),
                        imagePath: _pickedImage!.path,
                        duration: _durationController.text,
                        exercises: _exercisesController.text,
                      ));
                    });
                    _durationController.clear();
                    _exercisesController.clear();
                    _pickedImage = null;
                    Navigator.pop(context);
                  },
                  child: const Text('Сохранить отчет'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои тренировки')),
      body: _reports.isEmpty
          ? const Center(child: Text('Нет записей. Нажми + чтобы добавить!'))
          : ListView.builder(
              itemCount: _reports.length,
              itemBuilder: (ctx, i) => Card(
                margin: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.file(File(_reports[i].imagePath), height: 200, width: double.infinity, fit: BoxFit.cover),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(DateFormat('dd.MM.yyyy').format(_reports[i].date), style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('⏱ ${_reports[i].duration}', style: const TextStyle(color: Colors.blueGrey)),
                            ],
                          ),
                          const Divider(),
                          Text(_reports[i].exercises),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSheet,
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}