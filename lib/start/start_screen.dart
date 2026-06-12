import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uni_project/meals/screens/nutrition_screen.dart';
import 'package:uni_project/notes/notes_screen.dart';
import 'package:uni_project/start/card_for_start.dart';
import 'package:uni_project/start/models/category.dart';
import 'package:uni_project/train_help/screens/training_categories_screen.dart';
import 'package:uni_project/trainings/database/training_database_service.dart';
import 'package:uni_project/trainings/model/training_report.dart';
import 'package:uni_project/trainings/training_log_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  TrainingReport? _latestReport;
  bool _isLoadingReport = true;

  @override
  void initState() {
    super.initState();
    _loadLatestReport();
  }

  Future<void> _loadLatestReport() async {
    try {
      final reports = await TrainingDatabaseService.instance.getReports();
      if (!mounted) return;

      setState(() {
        _latestReport = reports.isEmpty ? null : reports.first;
        _isLoadingReport = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _latestReport = null;
        _isLoadingReport = false;
      });
    }
  }

  Future<void> _openScreen(BuildContext context, Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
    if (mounted) {
      _loadLatestReport();
    }
  }

  void _selectCategory(BuildContext context, int id) {
    switch (id) {
      case 0:
        _openScreen(context, const TrainingCategoriesScreen());
        break;
      case 1:
        _openScreen(context, const TrainingLogScreen());
        break;
      case 2:
        _openScreen(context, const NutritionScreen());
        break;
      case 3:
        _openScreen(context, const NotesScreen());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayLabel = DateFormat('d MMM').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fit Diary'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  todayLabel,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          Text(
            'Your daily fitness space',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Log workouts, review technique, keep meals and notes close.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          _TodayWorkoutCard(
            latestReport: _latestReport,
            isLoading: _isLoadingReport,
            onOpenLog: () => _selectCategory(context, 1),
          ),
          const SizedBox(height: 24),
          const _SectionTitle(title: 'Quick actions'),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 560 ? 4 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categoriesList.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: crossAxisCount == 4 ? 1.2 : 1.28,
                ),
                itemBuilder: (context, index) {
                  final category = categoriesList[index];
                  return CardForStart(
                    title: category.title,
                    subtitle: category.subtitle,
                    imagePath: category.imagePath,
                    icon: category.icon,
                    onSelectCategory: () =>
                        _selectCategory(context, category.id),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TodayWorkoutCard extends StatelessWidget {
  const _TodayWorkoutCard({
    required this.latestReport,
    required this.isLoading,
    required this.onOpenLog,
  });

  final TrainingReport? latestReport;
  final bool isLoading;
  final VoidCallback onOpenLog;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final report = latestReport;

    return Material(
      color: colorScheme.primary,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpenLog,
        child: Container(
          constraints: const BoxConstraints(minHeight: 156),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, const Color(0xFF123D32)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: isLoading
              ? const Center(
                  child: SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  ),
                )
              : report == null
              ? _EmptyTodayContent(onOpenLog: onOpenLog)
              : _LatestTodayContent(report: report),
        ),
      ),
    );
  }
}

class _EmptyTodayContent extends StatelessWidget {
  const _EmptyTodayContent({required this.onOpenLog});

  final VoidCallback onOpenLog;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Icon(Icons.auto_graph, color: Colors.white, size: 28),
        const SizedBox(height: 18),
        const Text(
          'Start today strong',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Save your next workout and it will appear here.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.82)),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: onOpenLog,
            icon: const Icon(Icons.add_a_photo, size: 18),
            label: const Text('Log workout'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _LatestTodayContent extends StatelessWidget {
  const _LatestTodayContent({required this.report});

  final TrainingReport report;

  @override
  Widget build(BuildContext context) {
    final imagePath = report.imagePath;
    final imageFile = imagePath == null ? null : File(imagePath);
    final hasImage = imageFile != null && imageFile.existsSync();

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 104,
            height: 124,
            child: hasImage
                ? Image.file(imageFile, fit: BoxFit.cover)
                : Container(
                    color: Colors.white.withValues(alpha: 0.16),
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Latest workout',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                report.displayFocus,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetricPill(
                    icon: Icons.schedule,
                    label: report.durationLabel,
                  ),
                  _MetricPill(
                    icon: Icons.calendar_today,
                    label: DateFormat('d MMM').format(report.date),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}
