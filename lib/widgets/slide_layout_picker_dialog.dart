import 'package:flutter/material.dart';
import '../controllers/presentation_controller.dart';

void showSlideLayoutPicker({
  required BuildContext context,
  required PresentationController controller,
  int? afterIndex,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1E293B),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Choose Slide Layout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Select a structured slide template to insert into your deck',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      _buildLayoutCard(
                        context: ctx,
                        title: 'Title Slide',
                        subtitle: 'Large title & subtitle cover',
                        preview: _buildTitlePreview(),
                        onTap: () {
                          Navigator.pop(ctx);
                          controller.addSlideWithLayout(SlideLayout.title, afterIndex: afterIndex);
                        },
                      ),
                      _buildLayoutCard(
                        context: ctx,
                        title: 'Title & Content',
                        subtitle: 'Header with bullet point body',
                        preview: _buildContentPreview(),
                        onTap: () {
                          Navigator.pop(ctx);
                          controller.addSlideWithLayout(SlideLayout.titleAndContent, afterIndex: afterIndex);
                        },
                      ),
                      _buildLayoutCard(
                        context: ctx,
                        title: 'Two Column',
                        subtitle: 'Side-by-side comparison layout',
                        preview: _buildTwoColumnPreview(),
                        onTap: () {
                          Navigator.pop(ctx);
                          controller.addSlideWithLayout(SlideLayout.twoColumn, afterIndex: afterIndex);
                        },
                      ),
                      _buildLayoutCard(
                        context: ctx,
                        title: 'Table & Matrix',
                        subtitle: 'Header with full editable data table',
                        preview: _buildTablePreview(),
                        onTap: () {
                          Navigator.pop(ctx);
                          controller.addSlideWithLayout(SlideLayout.table, afterIndex: afterIndex);
                        },
                      ),
                      _buildLayoutCard(
                        context: ctx,
                        title: 'Section Header',
                        subtitle: 'High-impact section breaker',
                        preview: _buildSectionPreview(),
                        onTap: () {
                          Navigator.pop(ctx);
                          controller.addSlideWithLayout(SlideLayout.sectionHeader, afterIndex: afterIndex);
                        },
                      ),
                      _buildLayoutCard(
                        context: ctx,
                        title: 'Blank Slide',
                        subtitle: 'Clean canvas for freeform design',
                        preview: _buildBlankPreview(),
                        onTap: () {
                          Navigator.pop(ctx);
                          controller.addSlideWithLayout(SlideLayout.blank, afterIndex: afterIndex);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildLayoutCard({
  required BuildContext context,
  required String title,
  required String subtitle,
  required Widget preview,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      width: 175,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 95,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: preview,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildTitlePreview() {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(width: 80, height: 8, decoration: BoxDecoration(color: const Color(0xFFC43E1C), borderRadius: BorderRadius.circular(2))),
      const SizedBox(height: 5),
      Container(width: 110, height: 5, decoration: BoxDecoration(color: const Color(0xFF64748B), borderRadius: BorderRadius.circular(2))),
      const SizedBox(height: 8),
      Container(width: 30, height: 2, decoration: BoxDecoration(color: const Color(0xFFC43E1C), borderRadius: BorderRadius.circular(1))),
    ],
  );
}

Widget _buildContentPreview() {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 65, height: 6, decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 8),
        Container(width: 120, height: 4, decoration: BoxDecoration(color: const Color(0xFF94A3B8), borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 4),
        Container(width: 100, height: 4, decoration: BoxDecoration(color: const Color(0xFF94A3B8), borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 4),
        Container(width: 110, height: 4, decoration: BoxDecoration(color: const Color(0xFF94A3B8), borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 4),
        Container(width: 80, height: 4, decoration: BoxDecoration(color: const Color(0xFF94A3B8), borderRadius: BorderRadius.circular(2))),
      ],
    ),
  );
}

Widget _buildTwoColumnPreview() {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 65, height: 6, decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: double.infinity, height: 4, decoration: BoxDecoration(color: const Color(0xFF38BDF8), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 3),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 3),
                  Container(width: 50, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2))),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: double.infinity, height: 4, decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 3),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 3),
                  Container(width: 50, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2))),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildTablePreview() {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 60, height: 5, decoration: BoxDecoration(color: const Color(0xFF0284C7), borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF94A3B8), width: 0.5),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Column(
            children: [
              Container(
                height: 12,
                color: const Color(0xFF1D4ED8),
                child: Row(
                  children: [
                    Expanded(child: Container(margin: const EdgeInsets.all(2), color: Colors.white38)),
                    Expanded(child: Container(margin: const EdgeInsets.all(2), color: Colors.white38)),
                    Expanded(child: Container(margin: const EdgeInsets.all(2), color: Colors.white38)),
                  ],
                ),
              ),
              Container(
                height: 10,
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(child: Container(margin: const EdgeInsets.all(1), color: const Color(0xFFE2E8F0))),
                    Expanded(child: Container(margin: const EdgeInsets.all(1), color: const Color(0xFFE2E8F0))),
                    Expanded(child: Container(margin: const EdgeInsets.all(1), color: const Color(0xFFE2E8F0))),
                  ],
                ),
              ),
              Container(
                height: 10,
                color: const Color(0xFFF0F9FF),
                child: Row(
                  children: [
                    Expanded(child: Container(margin: const EdgeInsets.all(1), color: const Color(0xFFE2E8F0))),
                    Expanded(child: Container(margin: const EdgeInsets.all(1), color: const Color(0xFFE2E8F0))),
                    Expanded(child: Container(margin: const EdgeInsets.all(1), color: const Color(0xFFE2E8F0))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildSectionPreview() {
  return Container(
    color: const Color(0xFF0F172A),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 70, height: 6, decoration: BoxDecoration(color: const Color(0xFF38BDF8), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 4),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFF94A3B8), borderRadius: BorderRadius.circular(2))),
        ],
      ),
    ),
  );
}

Widget _buildBlankPreview() {
  return Center(
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.add_rounded, color: Color(0xFF94A3B8), size: 20),
    ),
  );
}

