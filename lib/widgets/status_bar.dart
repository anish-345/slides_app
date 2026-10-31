import 'package:flutter/material.dart';
import '../controllers/presentation_controller.dart';
import '../services/rust_engine_service.dart';

class PresentationStatusBar extends StatelessWidget {
  final PresentationController controller;
  final double zoomScale;
  final ValueChanged<double> onZoomChanged;
  final VoidCallback onFitToScreen;
  final bool isInspectorOpen;
  final VoidCallback? onToggleInspector;

  const PresentationStatusBar({
    super.key,
    required this.controller,
    required this.zoomScale,
    required this.onZoomChanged,
    required this.onFitToScreen,
    this.isInspectorOpen = true,
    this.onToggleInspector,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final totalSlides = controller.presentation.slides.length;
        final currentSlideNum = controller.currentSlideIndex + 1;
        final selected = controller.selectedElement;

        return Container(
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            border: Border(top: BorderSide(color: Color(0xFF1E293B))),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Slide indicator
              Icon(Icons.layers_outlined, size: 14, color: const Color(0xFF38BDF8)),
              const SizedBox(width: 6),
              Text(
                'Slide $currentSlideNum of $totalSlides',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600),
              ),

              const SizedBox(width: 16),
              Container(width: 1, height: 14, color: const Color(0xFF334155)),
              const SizedBox(width: 16),

              // Selected Object Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    selected != null
                        ? '${selected.type.name.toUpperCase()}  •  ${selected.width.toInt()} × ${selected.height.toInt()} px  at  (${selected.x.toInt()}, ${selected.y.toInt()})'
                        : 'Canvas 1920 × 1080 (16:9 Widescreen)',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected != null ? const Color(0xFF38BDF8) : const Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                ),
              ),

              // Rust Engine Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded, size: 12, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Text(
                      RustEngineService.isNativeLoaded ? 'Rust Core 1.0 (Native FFI)' : 'Rust Engine (Active)',
                      style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 10, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),
              Container(width: 1, height: 14, color: const Color(0xFF334155)),
              const SizedBox(width: 16),

              // Zoom Controls
              InkWell(
                onTap: () => onZoomChanged((zoomScale - 0.1).clamp(0.4, 2.5)),
                child: const Padding(
                  padding: EdgeInsets.all(2.0),
                  child: Icon(Icons.remove_rounded, size: 16, color: Color(0xFF94A3B8)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '${(zoomScale * 100).toInt()}%',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              InkWell(
                onTap: () => onZoomChanged((zoomScale + 0.1).clamp(0.4, 2.5)),
                child: const Padding(
                  padding: EdgeInsets.all(2.0),
                  child: Icon(Icons.add_rounded, size: 16, color: Color(0xFF94A3B8)),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onFitToScreen,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Fit', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10)),
                ),
              ),
              if (onToggleInspector != null) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: onToggleInspector,
                  child: Tooltip(
                    message: isInspectorOpen ? 'Hide Properties Panel' : 'Show Properties Panel',
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isInspectorOpen ? const Color(0xFF0369A1) : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 12,
                            color: isInspectorOpen ? Colors.white : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Inspector',
                            style: TextStyle(
                              color: isInspectorOpen ? Colors.white : const Color(0xFF94A3B8),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

