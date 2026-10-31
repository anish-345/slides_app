import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/presentation_controller.dart';
import 'element_view.dart';

class SlideCanvas extends StatefulWidget {
  final PresentationController controller;
  final double zoomScale;

  const SlideCanvas({
    super.key,
    required this.controller,
    this.zoomScale = 1.0,
  });

  @override
  State<SlideCanvas> createState() => _SlideCanvasState();
}

class _SlideCanvasState extends State<SlideCanvas> {
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final controller = widget.controller;
    final selectedId = controller.selectedElementId;
    final isEditingText = controller.editingTextElementId != null;

    // Do not intercept hotkeys if the user is actively typing inside a text box
    if (isEditingText) return;

    // Undo / Redo
    if (HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed) {
      if (event.logicalKey == LogicalKeyboardKey.keyZ) {
        if (HardwareKeyboard.instance.isShiftPressed) {
          controller.redo();
        } else {
          controller.undo();
        }
        return;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyY) {
        controller.redo();
        return;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyD && selectedId != null) {
        controller.duplicateElement(selectedId);
        return;
      }
    }

    // Delete
    if ((event.logicalKey == LogicalKeyboardKey.delete ||
            event.logicalKey == LogicalKeyboardKey.backspace) &&
        selectedId != null) {
      controller.deleteElement(selectedId);
      return;
    }

    // Arrow Key Nudge
    if (selectedId != null) {
      final step = HardwareKeyboard.instance.isShiftPressed ? 10.0 : 2.0;
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        controller.updateElementPosition(selectedId, -step, 0);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        controller.updateElementPosition(selectedId, step, 0);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        controller.updateElementPosition(selectedId, 0, -step);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        controller.updateElementPosition(selectedId, 0, step);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final slide = controller.currentSlide;
        final pres = controller.presentation;

        return KeyboardListener(
          focusNode: _keyboardFocusNode,
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxW = constraints.maxWidth.isFinite ? constraints.maxWidth : 1920.0;
              final maxH = constraints.maxHeight.isFinite ? constraints.maxHeight : 1080.0;

              const padding = 24.0;
              final availW = math.max(100.0, maxW - padding * 2);
              final availH = math.max(100.0, maxH - padding * 2);

              final scaleX = availW / pres.canvasWidth;
              final scaleY = availH / pres.canvasHeight;
              final fitScale = (scaleX < scaleY ? scaleX : scaleY).clamp(0.05, 3.0);
              final scale = fitScale * widget.zoomScale;

              final renderW = pres.canvasWidth * scale;
              final renderH = pres.canvasHeight * scale;

              // Sort elements by zIndex for rendering order
              final sortedElements = List.of(slide.elements)
                ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

              final canvasWidget = GestureDetector(
                onTap: () {
                  // Tap on canvas background clears selection
                  controller.selectElement(null);
                  _keyboardFocusNode.requestFocus();
                },
                child: Container(
                  width: renderW,
                  height: renderH,
                  decoration: BoxDecoration(
                    color: Color(slide.backgroundColor),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x44000000),
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Slide Elements
                      for (final elem in sortedElements)
                        ElementView(
                          key: ValueKey(elem.id),
                          element: elem,
                          scale: scale,
                          isSelected: elem.id == controller.selectedElementId,
                          isEditing: elem.id == controller.editingTextElementId,
                          controller: controller,
                        ),
                    ],
                  ),
                ),
              );

              return InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(48),
                minScale: 0.2,
                maxScale: 3.5,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(padding),
                    child: canvasWidget,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
