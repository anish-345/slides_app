import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/slide_element.dart';

class ImageElementView extends StatelessWidget {
  final SlideElement element;
  final double scale;

  const ImageElementView({
    super.key,
    required this.element,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (element.imageBase64 != null && element.imageBase64!.isNotEmpty) {
      try {
        final cleanBase64 = element.imageBase64!.replaceAll(RegExp(r'\s+'), '');
        final bytes = base64Decode(cleanBase64);
        final targetW = ((element.width > 0 ? element.width : 500) * 2).clamp(100, 2560).toInt();

        imageWidget = Image.memory(
          bytes,
          fit: element.dartBoxFit,
          width: element.width * scale,
          height: element.height * scale,
          cacheWidth: targetW,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder('Corrupt image data'),
        );
      } catch (_) {
        imageWidget = _buildPlaceholder('Invalid base64 image');
      }
    } else if (element.imagePath != null && element.imagePath!.isNotEmpty) {
      final file = File(element.imagePath!);
      if (file.existsSync()) {
        final targetW = ((element.width > 0 ? element.width : 500) * 2).clamp(100, 2560).toInt();
        imageWidget = Image.file(
          file,
          fit: element.dartBoxFit,
          width: element.width * scale,
          height: element.height * scale,
          cacheWidth: targetW,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder('Failed to load image'),
        );
      } else {
        imageWidget = _buildPlaceholder('Image file not found:\n${element.imagePath}');
      }
    } else {
      imageWidget = _buildPlaceholder('No image source');
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(element.borderRadius * scale),
      child: imageWidget,
    );
  }

  Widget _buildPlaceholder(String message) {
    return Container(
      width: element.width * scale,
      height: element.height * scale,
      color: const Color(0xFFF1F5F9),
      padding: const EdgeInsets.all(12),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image_rounded,
              color: const Color(0xFF94A3B8),
              size: 36 * scale.clamp(0.5, 2.0),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF64748B),
                fontSize: 11 * scale.clamp(0.6, 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
