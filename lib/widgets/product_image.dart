import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Network product photo on a white rounded tile.
///
/// The loading and error placeholders are static icons (no spinner), so the
/// tile never keeps an animation running while a photo is downloading.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.url,
    this.radius = 16,
    this.padding = 8,
    this.iconSize = 24,
  });

  final String url;
  final double radius;
  final double padding;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final placeholder = Icon(
      Icons.image_outlined,
      size: iconSize,
      color: AppColors.ink.withValues(alpha: 0.3),
    );

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: url.isEmpty
          ? Center(child: placeholder)
          : Image.network(
              url,
              fit: BoxFit.contain,
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : Center(child: placeholder),
              errorBuilder: (_, _, _) => Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  size: iconSize,
                  color: AppColors.ink.withValues(alpha: 0.3),
                ),
              ),
            ),
    );
  }
}
