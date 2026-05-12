import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uni_project/trainings/database/training_database_service.dart';
import 'package:uni_project/trainings/model/training_report.dart';

class TrainingLogScreen extends StatefulWidget {
  const TrainingLogScreen({super.key});

  @override
  State<TrainingLogScreen> createState() => _TrainingLogScreenState();
}

class _TrainingLogScreenState extends State<TrainingLogScreen> {
  List<TrainingReport> _reports = [];
  final _durationController = TextEditingController();
  final _exercisesController = TextEditingController();
  File? _pickedImage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  @override
  void dispose() {
    _durationController.dispose();
    _exercisesController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    final loadedReports = await TrainingDatabaseService.instance.getReports();
    if (!mounted) return;

    setState(() {
      _reports = loadedReports;
      _isLoading = false;
    });
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    );
    if (image != null) {
      setState(() => _pickedImage = File(image.path));
    }
  }

  Future<void> _saveReport() async {
    if (_pickedImage == null) return;

    final savedImagePath = await TrainingDatabaseService.instance
        .saveReportImage(_pickedImage!);

    final report = TrainingReport(
      date: DateTime.now(),
      imagePath: savedImagePath,
      duration: _durationController.text,
      exercises: _exercisesController.text,
    );

    await TrainingDatabaseService.instance.insertReport(report);
    _durationController.clear();
    _exercisesController.clear();
    _pickedImage = null;

    await _loadReports();
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _deleteReport(TrainingReport report) async {
    if (report.id != null) {
      await TrainingDatabaseService.instance.deleteReport(report.id!);
      await _loadReports();
    }
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'New Workout',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),

                GestureDetector(
                  onTap: () async {
                    await _takePhoto();
                    setModalState(() {});
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
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt),
                              Text('Take a photo'),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.file(_pickedImage!, fit: BoxFit.cover),
                          ),
                  ),
                ),

                TextField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration',
                    hintText: 'Example: 45 min',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _exercisesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Workout notes',
                    hintText: 'What did you train?',
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: _saveReport,
                  child: const Text('Save Workout'),
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
      appBar: AppBar(title: const Text('Workout Log')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_a_photo,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No workouts yet',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap the camera button to save your first workout.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
              itemCount: _reports.length,
              itemBuilder: (ctx, i) => Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.file(
                      File(_reports[i].imagePath),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat(
                                  'dd.MM.yyyy',
                                ).format(_reports[i].date),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 17,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _reports[i].duration,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _deleteReport(_reports[i]),
                                  ),
                                ],
                              ),
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
