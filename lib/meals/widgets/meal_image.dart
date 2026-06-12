import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';

class MealImage extends StatelessWidget {
  const MealImage({
    super.key,
    required this.imagePath,
    required this.height,
    this.iconSize = 36,
    this.cacheWidth,
    this.cacheHeight,
  });

  final String imagePath;
  final double height;
  final double iconSize;
  final int? cacheWidth;
  final int? cacheHeight;

  bool get _isNetworkImage =>
      imagePath.startsWith('http://') || imagePath.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    final ImageProvider<Object> baseImageProvider = _isNetworkImage
        ? NetworkImage(imagePath)
        : AssetImage(imagePath);
    final imageProvider = ResizeImage.resizeIfNeeded(
      cacheWidth,
      cacheHeight,
      baseImageProvider,
    );

    return FadeInImage(
      fit: BoxFit.cover,
      filterQuality: FilterQuality.low,
      placeholder: MemoryImage(kTransparentImage),
      image: imageProvider,
      height: height,
      width: double.infinity,
      imageErrorBuilder: (context, error, stackTrace) {
        return Container(
          height: height,
          width: double.infinity,
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.restaurant,
            size: iconSize,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        );
      },
    );
  }
}
