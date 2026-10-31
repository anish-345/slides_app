import 'package:flutter/material.dart';
import '../controllers/presentation_controller.dart';
import '../models/slide_element.dart';
import '../services/rust_engine_service.dart';
import 'image_element_view.dart';
import 'text_element_view.dart';
import 'shape_element_view.dart';
import 'table_element_view.dart';

class ElementView extends StatefulWidget {
  final SlideElement element;
  final double scale;
  final bool isSelected;
  final bool isEditing;
  final PresentationController controller;

  const ElementView({
    super.key,
    required this.element,
    required this.scale,
    required this.isSelected,
    required this.isEditing,
    required this.controller,
  });

  @override
  State<ElementView> createState() => _ElementViewState();
}

class _ElementViewState extends State<ElementView> {
  // Dragging state
  double _dragStartX = 0;
  double _dragStartY = 0;
  double _initialElemX = 0;
  double _initialElemY = 0;
  double _initialElemW = 0;
  double _initialElemH = 0;

  @override
  Widget build(BuildContext context) {
    final elem = widget.element;
    final scale = widget.scale;
    final width = elem.width * scale;
    final height = elem.height * scale;
    final left = elem.x * scale;
    final top = elem.y * scale;

    Widget contentWidget;
    switch (elem.type) {
      case ElementType.image:
        contentWidget = ImageElementView(element: elem, scale: scale);
        break;
      case ElementType.text:
        contentWidget = TextElementView(
          element: elem,
          scale: scale,
          isEditing: widget.isEditing,
          onTextChanged: (text) => widget.controller.updateElementText(elem.id, text),
          onEditingComplete: () => widget.controller.stopEditingText(),
        );
        break;
      case ElementType.shape:
        contentWidget = ShapeElementView(element: elem, scale: scale);
        break;
      case ElementType.table:
        contentWidget = TableElementView(
          element: elem,
          scale: scale,
          isSelected: widget.isSelected,
          onCellChanged: (r, c, val) => widget.controller.updateTableCell(elem.id, r, c, val),
        );
        break;
    }

    return Positioned(
      left: left,
      top: top,
      child: Transform.rotate(
        angle: elem.rotation,
        child: Opacity(
          opacity: elem.opacity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Core Draggable Element Body
              MouseRegion(
                cursor: widget.isSelected
                    ? (widget.isEditing ? SystemMouseCursors.text : SystemMouseCursors.move)
                    : SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    if (widget.isSelected && elem.type == ElementType.text && !widget.isEditing) {
                      widget.controller.startEditingText(elem.id);
                    } else {
                      widget.controller.selectElement(elem.id);
                    }
                  },
                  onDoubleTap: () {
                    if (elem.type == ElementType.text) {
                      widget.controller.startEditingText(elem.id);
                    }
                  },
                  onPanStart: widget.isEditing
                      ? null
                      : (details) {
                          widget.controller.selectElement(elem.id);
                          _dragStartX = details.globalPosition.dx;
                          _dragStartY = details.globalPosition.dy;
                          _initialElemX = elem.x;
                          _initialElemY = elem.y;
                        },
                  onPanUpdate: widget.isEditing
                      ? null
                      : (details) {
                          final dx = (details.globalPosition.dx - _dragStartX) / scale;
                          final dy = (details.globalPosition.dy - _dragStartY) / scale;

                          var rawX = _initialElemX + dx;
                          var rawY = _initialElemY + dy;

                          // High-performance snapping to canvas center
                          rawX = RustEngineService.snapCoordinate(
                            pos: rawX,
                            size: elem.width,
                            target: 960.0,
                            threshold: 14.0,
                          );
                          rawY = RustEngineService.snapCoordinate(
                            pos: rawY,
                            size: elem.height,
                            target: 540.0,
                            threshold: 14.0,
                          );

                          widget.controller.setElementPosition(
                            elem.id,
                            rawX,
                            rawY,
                          );
                        },
                  child: Container(
                    width: width,
                    height: height,
                    decoration: BoxDecoration(
                      border: widget.isSelected
                          ? Border.all(color: const Color(0xFF0284C7), width: 2)
                          : null,
                    ),
                    child: contentWidget,
                  ),
                ),
              ),

              // Selection Chrome & Resize Handles
              if (widget.isSelected && !widget.isEditing) ...[
                // Top-Left Handle
                _buildHandle(
                  left: -6,
                  top: -6,
                  cursor: SystemMouseCursors.resizeUpLeftDownRight,
                  onPanUpdate: (dx, dy) {
                    final newW = _initialElemW - dx;
                    final newH = _initialElemH - dy;
                    if (newW > 30 && newH > 30) {
                      widget.controller.updateElementSize(
                        elem.id,
                        newW,
                        newH,
                        newX: _initialElemX + dx,
                        newY: _initialElemY + dy,
                      );
                    }
                  },
                ),
                // Top-Right Handle
                _buildHandle(
                  left: width - 6,
                  top: -6,
                  cursor: SystemMouseCursors.resizeUpRightDownLeft,
                  onPanUpdate: (dx, dy) {
                    final newW = _initialElemW + dx;
                    final newH = _initialElemH - dy;
                    if (newW > 30 && newH > 30) {
                      widget.controller.updateElementSize(
                        elem.id,
                        newW,
                        newH,
                        newY: _initialElemY + dy,
                      );
                    }
                  },
                ),
                // Bottom-Left Handle
                _buildHandle(
                  left: -6,
                  top: height - 6,
                  cursor: SystemMouseCursors.resizeUpRightDownLeft,
                  onPanUpdate: (dx, dy) {
                    final newW = _initialElemW - dx;
                    final newH = _initialElemH + dy;
                    if (newW > 30 && newH > 30) {
                      widget.controller.updateElementSize(
                        elem.id,
                        newW,
                        newH,
                        newX: _initialElemX + dx,
                      );
                    }
                  },
                ),
                // Bottom-Right Handle
                _buildHandle(
                  left: width - 6,
                  top: height - 6,
                  cursor: SystemMouseCursors.resizeUpLeftDownRight,
                  onPanUpdate: (dx, dy) {
                    final newW = _initialElemW + dx;
                    final newH = _initialElemH + dy;
                    if (newW > 30 && newH > 30) {
                      widget.controller.updateElementSize(elem.id, newW, newH);
                    }
                  },
                ),

                // Floating Action Toolbar Above the Element
                Positioned(
                  left: 0,
                  top: (top < 50) ? height + 8 : -42,
                  child: Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFF1E293B),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (elem.type == ElementType.text) ...[
                            _buildQuickIcon(
                              icon: Icons.edit_note_rounded,
                              color: const Color(0xFF38BDF8),
                              tooltip: 'Edit Text',
                              onTap: () => widget.controller.startEditingText(elem.id),
                            ),
                            const SizedBox(width: 4),
                            Container(width: 1, height: 16, color: const Color(0xFF475569)),
                            const SizedBox(width: 4),
                          ],
                          _buildQuickIcon(
                            icon: Icons.copy_rounded,
                            tooltip: 'Duplicate',
                            onTap: () => widget.controller.duplicateElement(elem.id),
                          ),
                          _buildQuickIcon(
                            icon: Icons.flip_to_front_rounded,
                            tooltip: 'Bring to Front',
                            onTap: () => widget.controller.bringToFront(elem.id),
                          ),
                          _buildQuickIcon(
                            icon: Icons.flip_to_back_rounded,
                            tooltip: 'Send to Back',
                            onTap: () => widget.controller.sendToBack(elem.id),
                          ),
                          const SizedBox(width: 4),
                          Container(width: 1, height: 16, color: const Color(0xFF475569)),
                          const SizedBox(width: 4),
                          _buildQuickIcon(
                            icon: Icons.check_rounded,
                            color: const Color(0xFF10B981),
                            tooltip: 'Done / Deselect',
                            onTap: () => widget.controller.selectElement(null),
                          ),
                          _buildQuickIcon(
                            icon: Icons.delete_outline_rounded,
                            color: const Color(0xFFEF4444),
                            tooltip: 'Delete',
                            onTap: () => widget.controller.deleteElement(elem.id),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickIcon({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color color = const Color(0xFFF8FAFC),
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  Widget _buildHandle({
    required double left,
    required double top,
    required MouseCursor cursor,
    required void Function(double dx, double dy) onPanUpdate,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          onPanStart: (details) {
            _dragStartX = details.globalPosition.dx;
            _dragStartY = details.globalPosition.dy;
            _initialElemX = widget.element.x;
            _initialElemY = widget.element.y;
            _initialElemW = widget.element.width;
            _initialElemH = widget.element.height;
          },
          onPanUpdate: (details) {
            final dx = (details.globalPosition.dx - _dragStartX) / widget.scale;
            final dy = (details.globalPosition.dy - _dragStartY) / widget.scale;
            onPanUpdate(dx, dy);
          },
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFF0284C7), width: 2),
              borderRadius: BorderRadius.circular(3),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
