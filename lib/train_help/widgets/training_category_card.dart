import 'package:flutter/material.dart';

class TrainingCategoryCard extends StatelessWidget {
  const TrainingCategoryCard({
    super.key,
    required this.title,
    required this.imagePath,
    required this.onSelect,
  });

  final String title;
  final String imagePath;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.hardEdge,
      elevation: 0,
      child: InkWell(
        onTap: onSelect,
        child: Stack(
          children: [
            Image.asset(
              imagePath,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 180,
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.fitness_center,
                    size: 42,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                );
              },
            ),
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xCC000000), Color(0x11000000)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
