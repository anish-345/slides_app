import 'package:flutter/material.dart';
import '../controllers/presentation_controller.dart';
import 'slide_layout_picker_dialog.dart';
import 'slide_thumbnail_view.dart';

class SlideThumbnailSidebar extends StatelessWidget {
  final PresentationController controller;

  const SlideThumbnailSidebar({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final slides = controller.presentation.slides;
        final currentIndex = controller.currentSlideIndex;

        return Container(
          width: 220,
          color: const Color(0xFF0F172A), // Dark slate sidebar
          child: Column(
            children: [
              // Sidebar Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Slides (${slides.length})',
                        style: const TextStyle(
                          color: Color(0xFFF8FAFC),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_rounded, color: Color(0xFF38BDF8), size: 22),
                      tooltip: 'Choose Slide Layout',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => showSlideLayoutPicker(context: context, controller: controller),
                    ),
                  ],
                ),
              ),

              // Scrollable List of Slides
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  itemCount: slides.length,
                  itemBuilder: (context, index) {
                    final slide = slides[index];
                    final isSelected = index == currentIndex;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Slide Number
                          SizedBox(
                            width: 20,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${index + 1}',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: isSelected
                                      ? const Color(0xFF38BDF8)
                                      : const Color(0xFF64748B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Slide Thumbnail Card
                          Expanded(
                            child: InkWell(
                              onTap: () => controller.selectSlide(index),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF38BDF8)
                                        : const Color(0xFF334155),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          const BoxShadow(
                                            color: Color(0x3338BDF8),
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  children: [
                                    AspectRatio(
                                      aspectRatio: 16 / 9,
                                      child: SlideThumbnailView(
                                        slide: slide,
                                        width: 170,
                                        height: 170 * (9 / 16),
                                      ),
                                    ),
                                    Container(
                                      color: const Color(0xFF1E293B),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          InkWell(
                                            onTap: () => controller.duplicateSlide(index),
                                            child: const Padding(
                                              padding: EdgeInsets.all(3.0),
                                              child: Icon(Icons.copy_rounded,
                                                  size: 13, color: Color(0xFF94A3B8)),
                                            ),
                                          ),
                                          if (slides.length > 1) ...[
                                            const SizedBox(width: 6),
                                            InkWell(
                                              onTap: () => controller.deleteSlide(index),
                                              child: const Padding(
                                                padding: EdgeInsets.all(3.0),
                                                child: Icon(Icons.delete_outline_rounded,
                                                    size: 13, color: Color(0xFFEF4444)),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom Add Slide Action
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: const Color(0xFFF8FAFC),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: const BorderSide(color: Color(0xFF334155)),
                      ),
                    ),
                    onPressed: () => showSlideLayoutPicker(context: context, controller: controller),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('New Slide', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
