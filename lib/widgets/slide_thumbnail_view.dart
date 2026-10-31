import 'package:flutter/material.dart';
import '../models/slide.dart';
import '../models/slide_element.dart';
import 'image_element_view.dart';
import 'shape_element_view.dart';
import 'table_element_view.dart';

class SlideThumbnailView extends StatelessWidget {
  final Slide slide;
  final double width;
  final double height;

  const SlideThumbnailView({
    super.key,
    required this.slide,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    // Reference 1920x1080 canvas
    final scale = width / 1920.0;
    final sortedElements = List.of(slide.elements)
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Color(slide.backgroundColor),
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          for (final elem in sortedElements)
            Positioned(
              left: elem.x * scale,
              top: elem.y * scale,
              child: Opacity(
                opacity: elem.opacity,
                child: SizedBox(
                  width: elem.width * scale,
                  height: elem.height * scale,
                  child: ClipRect(
                    child: _buildMiniContent(elem, scale),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniContent(SlideElement elem, double scale) {
    switch (elem.type) {
      case ElementType.image:
        return ImageElementView(element: elem, scale: scale);
      case ElementType.shape:
        return ShapeElementView(element: elem, scale: scale);
      case ElementType.table:
        return TableElementView(
          element: elem,
          scale: scale,
          isSelected: false,
          onCellChanged: (row, col, value) {},
        );
      case ElementType.text:
        if (elem.paragraphs.isNotEmpty) {
          return ClipRect(
            child: Container(
              padding: EdgeInsets.all(2 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final p in elem.paragraphs.take(4))
                    Padding(
                      padding: EdgeInsets.only(bottom: 1 * scale),
                      child: p.runs.isNotEmpty
                          ? RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                children: [
                                  for (final run in p.runs)
                                    TextSpan(
                                      text: run.text,
                                      style: TextStyle(
                                        fontSize: (run.fontSize * scale).clamp(2.0, 14.0),
                                        fontWeight: run.isBold ? FontWeight.bold : FontWeight.normal,
                                        color: Color(run.textColor),
                                      ),
                                    ),
                                ],
                              ),
                            )
                          : Text(
                              p.text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: (p.fontSize * scale).clamp(2.0, 14.0),
                                fontWeight: p.isBold ? FontWeight.bold : FontWeight.normal,
                                color: Color(p.textColor),
                              ),
                            ),
                    ),
                ],
              ),
            ),
          );
        }
        return ClipRect(
          child: Container(
            padding: EdgeInsets.all(2 * scale),
            alignment: _getAlignment(elem.dartTextAlign),
            child: Text(
              elem.text,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              textAlign: elem.dartTextAlign,
              style: TextStyle(
                fontSize: (elem.fontSize * scale).clamp(2.0, 18.0),
                fontWeight: elem.isBold ? FontWeight.bold : FontWeight.normal,
                fontStyle: elem.isItalic ? FontStyle.italic : FontStyle.normal,
                color: Color(elem.textColor),
                height: 1.2,
              ),
            ),
          ),
        );
    }
  }

  Alignment _getAlignment(TextAlign align) {
    switch (align) {
      case TextAlign.center:
        return Alignment.center;
      case TextAlign.right:
        return Alignment.centerRight;
      default:
        return Alignment.centerLeft;
    }
  }
}
