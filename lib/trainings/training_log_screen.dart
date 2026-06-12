import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uni_project/trainings/database/training_database_service.dart';
import 'package:uni_project/trainings/model/training_report.dart';

enum _WorkoutDateFilter { all, week, month }

enum _WorkoutSortOrder { newest, oldest }

class TrainingLogScreen extends StatefulWidget {
  const TrainingLogScreen({super.key});

  @override
  State<TrainingLogScreen> createState() => _TrainingLogScreenState();
}

class _TrainingLogScreenState extends State<TrainingLogScreen> {
  List<TrainingReport> _reports = [];
  bool _isLoading = true;
  _WorkoutDateFilter _dateFilter = _WorkoutDateFilter.all;
  _WorkoutSortOrder _sortOrder = _WorkoutSortOrder.newest;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    final loadedReports = await TrainingDatabaseService.instance.getReports();
    if (!mounted) return;

    setState(() {
      _reports = loadedReports;
      _isLoading = false;
    });
  }

  List<TrainingReport> get _visibleReports {
    final visibleReports = _reports
        .where((report) => _matchesDateFilter(report.date))
        .toList();

    visibleReports.sort((a, b) {
      final comparison = a.date.compareTo(b.date);
      return _sortOrder == _WorkoutSortOrder.newest ? -comparison : comparison;
    });

    return visibleReports;
  }

  _WorkoutStats get _stats {
    final now = DateTime.now();
    final weekCount = _reports
        .where((report) => _isInCurrentWeek(report.date, now))
        .length;
    final durations = _reports
        .where((report) => report.durationMinutes > 0)
        .map((report) => report.durationMinutes)
        .toList();
    final averageDuration = durations.isEmpty
        ? 0
        : (durations.reduce((sum, duration) => sum + duration) /
                  durations.length)
              .round();
    final sortedByDate = [..._reports]
      ..sort((a, b) => b.date.compareTo(a.date));

    return _WorkoutStats(
      weekCount: weekCount,
      averageDuration: averageDuration,
      latestReport: sortedByDate.isEmpty ? null : sortedByDate.first,
    );
  }

  bool _matchesDateFilter(DateTime date) {
    final now = DateTime.now();
    return switch (_dateFilter) {
      _WorkoutDateFilter.all => true,
      _WorkoutDateFilter.week => _isInCurrentWeek(date, now),
      _WorkoutDateFilter.month =>
        date.year == now.year && date.month == now.month,
    };
  }

  bool _isInCurrentWeek(DateTime date, DateTime now) {
    final today = _dateOnly(now);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    final checkedDate = _dateOnly(date);

    return !checkedDate.isBefore(startOfWeek) &&
        checkedDate.isBefore(endOfWeek);
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  Future<void> _saveWorkout(_WorkoutFormData data) async {
    String? imagePath = data.existingImagePath;

    if (data.removeExistingImage) {
      await TrainingDatabaseService.instance.deleteReportImage(
        data.originalImagePath,
      );
      imagePath = null;
    }

    if (data.image != null) {
      final savedImagePath = await TrainingDatabaseService.instance
          .saveReportImage(data.image!);

      if (data.originalImagePath != null &&
          data.originalImagePath != savedImagePath) {
        await TrainingDatabaseService.instance.deleteReportImage(
          data.originalImagePath,
        );
      }

      imagePath = savedImagePath;
    }

    final report = TrainingReport(
      id: data.id,
      date: data.date,
      imagePath: imagePath,
      durationMinutes: data.durationMinutes,
      focus: data.focus,
      exercises: data.exercises,
    );

    if (report.id == null) {
      await TrainingDatabaseService.instance.insertReport(report);
    } else {
      await TrainingDatabaseService.instance.updateReport(report);
    }
  }

  Future<void> _openWorkoutSheet({TrainingReport? report}) async {
    final didSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _WorkoutFormSheet(report: report, onSave: _saveWorkout),
    );

    if (didSave == true) {
      await _loadReports();
    }
  }

  Future<void> _deleteReport(TrainingReport report) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete workout?'),
        content: const Text('This will remove the workout and its photo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || report.id == null) return;

    await TrainingDatabaseService.instance.deleteReport(report.id!);
    await _loadReports();
  }

  @override
  Widget build(BuildContext context) {
    final visibleReports = _visibleReports;

    return Scaffold(
      appBar: AppBar(title: const Text('Workout Log')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
          ? _EmptyWorkoutState(onAdd: () => _openWorkoutSheet())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              children: [
                _WorkoutStatsPanel(stats: _stats),
                const SizedBox(height: 14),
                _WorkoutToolbar(
                  filter: _dateFilter,
                  sortOrder: _sortOrder,
                  onFilterChanged: (filter) {
                    setState(() => _dateFilter = filter);
                  },
                  onSortChanged: (sortOrder) {
                    setState(() => _sortOrder = sortOrder);
                  },
                ),
                const SizedBox(height: 14),
                if (visibleReports.isEmpty)
                  _FilteredEmptyState(filter: _dateFilter)
                else
                  for (final report in visibleReports)
                    _WorkoutReportCard(
                      report: report,
                      onEdit: () => _openWorkoutSheet(report: report),
                      onDelete: () => _deleteReport(report),
                    ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openWorkoutSheet(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _WorkoutFormSheet extends StatefulWidget {
  const _WorkoutFormSheet({required this.report, required this.onSave});

  final TrainingReport? report;
  final Future<void> Function(_WorkoutFormData data) onSave;

  @override
  State<_WorkoutFormSheet> createState() => _WorkoutFormSheetState();
}

class _WorkoutFormSheetState extends State<_WorkoutFormSheet> {
  late final TextEditingController _focusController;
  late final TextEditingController _durationController;
  late final TextEditingController _exercisesController;
  late DateTime _selectedDate;
  late String? _existingImagePath;
  File? _pickedImage;
  bool _removeExistingImage = false;
  bool _isSaving = false;

  bool get _isEditing => widget.report != null;
  bool get _hasAnyImage => _pickedImage != null || _existingImagePath != null;

  @override
  void initState() {
    super.initState();
    final report = widget.report;

    _focusController = TextEditingController(text: report?.focus ?? '');
    _durationController = TextEditingController(
      text: report == null || report.durationMinutes <= 0
          ? ''
          : report.durationMinutes.toString(),
    );
    _exercisesController = TextEditingController(text: report?.exercises ?? '');
    _selectedDate = report?.date ?? DateTime.now();
    _existingImagePath = report?.imagePath;
  }

  @override
  void dispose() {
    _focusController.dispose();
    _durationController.dispose();
    _exercisesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, imageQuality: 72);
    if (image == null) return;

    setState(() {
      _pickedImage = File(image.path);
      _existingImagePath = null;
      _removeExistingImage = widget.report?.hasImage == true;
    });
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate == null) return;

    setState(() {
      _selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        _selectedDate.hour,
        _selectedDate.minute,
      );
    });
  }

  void _removePhoto() {
    setState(() {
      _pickedImage = null;
      _existingImagePath = null;
      _removeExistingImage = widget.report?.hasImage == true;
    });
  }

  Future<void> _submit() async {
    final focus = _focusController.text.trim();
    final durationMinutes = int.tryParse(_durationController.text.trim()) ?? 0;
    final exercises = _exercisesController.text.trim();

    if (focus.isEmpty || durationMinutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add focus and duration first.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await widget.onSave(
        _WorkoutFormData(
          id: widget.report?.id,
          date: _selectedDate,
          image: _pickedImage,
          existingImagePath: _existingImagePath,
          originalImagePath: widget.report?.imagePath,
          removeExistingImage: _removeExistingImage,
          durationMinutes: durationMinutes,
          focus: focus,
          exercises: exercises,
        ),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save this workout.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _isEditing ? 'Edit Workout' : 'New Workout',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Track the focus, duration, notes, and optional photo.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                _PhotoPickerBox(
                  image: _pickedImage,
                  existingImagePath: _existingImagePath,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('Camera'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Gallery'),
                      ),
                    ),
                  ],
                ),
                if (_hasAnyImage) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _isSaving ? null : _removePhoto,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Remove photo'),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _isSaving ? null : _selectDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    DateFormat('EEE, d MMM yyyy').format(_selectedDate),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _focusController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Focus',
                    hintText: 'Back and biceps',
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Duration',
                    hintText: '45',
                    suffixText: 'min',
                    prefixIcon: Icon(Icons.schedule),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _exercisesController,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Exercises and notes',
                    hintText: 'Pull-ups, rows, curls...',
                    prefixIcon: Icon(Icons.edit_note),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: _isSaving ? null : _submit,
                  child: Text(_isSaving ? 'Saving...' : 'Save Workout'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkoutFormData {
  const _WorkoutFormData({
    required this.id,
    required this.date,
    required this.image,
    required this.existingImagePath,
    required this.originalImagePath,
    required this.removeExistingImage,
    required this.durationMinutes,
    required this.focus,
    required this.exercises,
  });

  final int? id;
  final DateTime date;
  final File? image;
  final String? existingImagePath;
  final String? originalImagePath;
  final bool removeExistingImage;
  final int durationMinutes;
  final String focus;
  final String exercises;
}

class _WorkoutStats {
  const _WorkoutStats({
    required this.weekCount,
    required this.averageDuration,
    required this.latestReport,
  });

  final int weekCount;
  final int averageDuration;
  final TrainingReport? latestReport;
}

class _WorkoutStatsPanel extends StatelessWidget {
  const _WorkoutStatsPanel({required this.stats});

  final _WorkoutStats stats;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress overview',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'This week',
                    value: stats.weekCount.toString(),
                    helper: stats.weekCount == 1 ? 'workout' : 'workouts',
                    icon: Icons.calendar_view_week_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatTile(
                    label: 'Average',
                    value: stats.averageDuration == 0
                        ? '-'
                        : '${stats.averageDuration}',
                    helper: 'min',
                    icon: Icons.timer_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatTile(
                    label: 'Latest',
                    value: stats.latestReport == null
                        ? '-'
                        : DateFormat('d MMM').format(stats.latestReport!.date),
                    helper: stats.latestReport?.displayFocus ?? 'No workouts',
                    icon: Icons.trending_up,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.helper,
    required this.icon,
  });

  final String label;
  final String value;
  final String helper;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 116),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: 20,
          ),
          const SizedBox(height: 16),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            helper,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onPrimaryContainer.withValues(alpha: 0.72),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutToolbar extends StatelessWidget {
  const _WorkoutToolbar({
    required this.filter,
    required this.sortOrder,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  final _WorkoutDateFilter filter;
  final _WorkoutSortOrder sortOrder;
  final ValueChanged<_WorkoutDateFilter> onFilterChanged;
  final ValueChanged<_WorkoutSortOrder> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChipButton(
                  label: 'All',
                  selected: filter == _WorkoutDateFilter.all,
                  onTap: () => onFilterChanged(_WorkoutDateFilter.all),
                ),
                _FilterChipButton(
                  label: 'This week',
                  selected: filter == _WorkoutDateFilter.week,
                  onTap: () => onFilterChanged(_WorkoutDateFilter.week),
                ),
                _FilterChipButton(
                  label: 'This month',
                  selected: filter == _WorkoutDateFilter.month,
                  onTap: () => onFilterChanged(_WorkoutDateFilter.month),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  onSortChanged(
                    sortOrder == _WorkoutSortOrder.newest
                        ? _WorkoutSortOrder.oldest
                        : _WorkoutSortOrder.newest,
                  );
                },
                icon: Icon(
                  sortOrder == _WorkoutSortOrder.newest
                      ? Icons.south
                      : Icons.north,
                ),
                label: Text(
                  sortOrder == _WorkoutSortOrder.newest
                      ? 'Newest first'
                      : 'Oldest first',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      labelStyle: TextStyle(
        color: selected
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w800,
      ),
      selectedColor: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.surface,
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    );
  }
}

class _PhotoPickerBox extends StatelessWidget {
  const _PhotoPickerBox({required this.image, required this.existingImagePath});

  final File? image;
  final String? existingImagePath;

  @override
  Widget build(BuildContext context) {
    final existingFile = existingImagePath == null
        ? null
        : File(existingImagePath!);
    final hasExistingImage = existingFile != null && existingFile.existsSync();

    return Container(
      height: 166,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: image != null
          ? Image.file(image!, fit: BoxFit.cover)
          : hasExistingImage
          ? Image.file(existingFile, fit: BoxFit.cover)
          : const _PhotoPlaceholder(),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 34,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 8),
        Text(
          'Optional workout photo',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        Text(
          'Camera, gallery, or no photo',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _EmptyWorkoutState extends StatelessWidget {
  const _EmptyWorkoutState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.add_a_photo,
                size: 34,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No workouts yet',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Add your first report with focus, duration, notes, and an optional photo.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('New Workout'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilteredEmptyState extends StatelessWidget {
  const _FilteredEmptyState({required this.filter});

  final _WorkoutDateFilter filter;

  @override
  Widget build(BuildContext context) {
    final label = switch (filter) {
      _WorkoutDateFilter.all => 'No workouts yet',
      _WorkoutDateFilter.week => 'No workouts this week',
      _WorkoutDateFilter.month => 'No workouts this month',
    };

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              color: Theme.of(context).colorScheme.primary,
              size: 34,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Try another date filter.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutReportCard extends StatelessWidget {
  const _WorkoutReportCard({
    required this.report,
    required this.onEdit,
    required this.onDelete,
  });

  final TrainingReport report;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ReportImage(imagePath: report.imagePath),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.displayFocus,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _InfoChip(
                                  icon: Icons.calendar_today,
                                  label: DateFormat(
                                    'd MMM yyyy',
                                  ).format(report.date),
                                ),
                                _InfoChip(
                                  icon: Icons.schedule,
                                  label: report.durationLabel,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit workout',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: onEdit,
                      ),
                      IconButton(
                        tooltip: 'Delete workout',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    report.exercises.isEmpty
                        ? 'No detailed notes yet.'
                        : report.exercises,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportImage extends StatelessWidget {
  const _ReportImage({required this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final imageFile = imagePath == null ? null : File(imagePath!);
    final hasImage = imageFile != null && imageFile.existsSync();

    return SizedBox(
      height: 188,
      width: double.infinity,
      child: hasImage
          ? Image.file(imageFile, fit: BoxFit.cover)
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.fitness_center,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 38,
                ),
              ),
            ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 152),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
