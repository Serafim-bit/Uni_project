import 'package:flutter/material.dart';

class CardForStart extends StatelessWidget {
  const CardForStart({
    super.key,
    required this.text,
    required this.imagePath,
    required this.onSelectCategory
  });

  final String text;
  final String imagePath;
  final void Function() onSelectCategory; 

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        splashColor: Colors.white24,

        onTap: () {
          onSelectCategory();
        },

        child: Stack(
          fit: StackFit.expand,
          children: [

            /// IMAGE
            Image.asset(
              imagePath,
              fit: BoxFit.cover,
            ),

            /// GRADIENT OVERLAY
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black54,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            /// TEXT
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 6,
                      color: Colors.black,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}