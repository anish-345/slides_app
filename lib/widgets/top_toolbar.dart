import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../controllers/presentation_controller.dart';
import '../models/slide_element.dart';

class TopToolbar extends StatelessWidget {
  final PresentationController controller;
  final VoidCallback onStartPresentation;
  final VoidCallback onExportPdf;
  final VoidCallback onExportPptx;
  final VoidCallback onSaveProject;
  final VoidCallback onLoadProject;

  const TopToolbar({
    super.key,
    required this.controller,
    required this.onStartPresentation,
    required this.onExportPdf,
    required this.onExportPptx,
    required this.onSaveProject,
    required this.onLoadProject,
  });

  Future<void> _pickAndAddImage(BuildContext context) async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'gif'],
    );

    if (files.isNotEmpty) {
      final file = files.first;
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);

      controller.addImageElement(
        path: file.path ?? '',
        base64: base64String,
        x: 400,
        y: 250,
        width: 500,
        height: 350,
      );
    }
  }

  void _showColorPicker({
    required BuildContext context,
    required String title,
    required Color currentColor,
    required ValueChanged<Color> onColorChanged,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        Color pickerColor = currentColor;
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: pickerColor,
              onColorChanged: (color) {
                pickerColor = color;
                onColorChanged(color);
                Navigator.of(ctx).pop();
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final selected = controller.selectedElement;

        return Container(
          height: 56,
          color: const Color(0xFF1E293B),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Left & Center scrollable tools
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // App Brand / Title
                      const Icon(Icons.slideshow_rounded, color: Color(0xFF38BDF8), size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Native Slides',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(width: 16),
                      _buildDivider(),
                      const SizedBox(width: 12),

                      // Element Inserters
                      _buildToolButton(
                        icon: Icons.text_fields_rounded,
                        label: 'Text',
                        onPressed: () => controller.addTextElement(),
                      ),
                      const SizedBox(width: 6),
                      _buildToolButton(
                        icon: Icons.image_outlined,
                        label: 'Image',
                        onPressed: () => _pickAndAddImage(context),
                      ),
                      const SizedBox(width: 6),
                      _buildToolButton(
                        icon: Icons.table_chart_outlined,
                        label: 'Table',
                        onPressed: () => controller.addTableElement(),
                      ),
                      const SizedBox(width: 6),
                      PopupMenuButton<String>(
                        tooltip: 'Insert Shape',
                        color: const Color(0xFF1E293B),
                        onSelected: (shape) => controller.addShapeElement(shapeType: shape),
                        itemBuilder: (context) => [
                          _buildPopupItem('rectangle', 'Rectangle', Icons.crop_square_rounded),
                          _buildPopupItem('rounded_rect', 'Rounded Rect', Icons.crop_portrait_rounded),
                          _buildPopupItem('circle', 'Circle', Icons.circle_outlined),
                          _buildPopupItem('triangle', 'Triangle', Icons.change_history_rounded),
                          _buildPopupItem('arrow', 'Arrow', Icons.arrow_right_alt_rounded),
                        ],
                        child: _buildToolButton(
                          icon: Icons.category_outlined,
                          label: 'Shape',
                          onPressed: null,
                        ),
                      ),

                      const SizedBox(width: 12),
                      _buildDivider(),
                      const SizedBox(width: 12),

                      // Slide Background Color
                      IconButton(
                        icon: const Icon(Icons.palette_outlined, color: Color(0xFFF8FAFC), size: 20),
                        tooltip: 'Slide Background Color',
                        onPressed: () {
                          _showColorPicker(
                            context: context,
                            title: 'Slide Background',
                            currentColor: Color(controller.currentSlide.backgroundColor),
                            onColorChanged: (c) => controller.setSlideBackground(c.toARGB32()),
                          );
                        },
                      ),

                      // Undo / Redo
                      IconButton(
                        icon: Icon(
                          Icons.undo_rounded,
                          color: controller.canUndo ? const Color(0xFFF8FAFC) : const Color(0xFF475569),
                          size: 20,
                        ),
                        tooltip: 'Undo (Ctrl+Z)',
                        onPressed: controller.canUndo ? controller.undo : null,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.redo_rounded,
                          color: controller.canRedo ? const Color(0xFFF8FAFC) : const Color(0xFF475569),
                          size: 20,
                        ),
                        tooltip: 'Redo (Ctrl+Y)',
                        onPressed: controller.canRedo ? controller.redo : null,
                      ),

                      const SizedBox(width: 12),
                      _buildDivider(),
                      const SizedBox(width: 12),

                      // Contextual Formatting Bar
                      if (selected != null) ...[
                        _buildContextualFormatting(context, selected),
                      ] else ...[
                        const Text(
                          'Select an element to edit styles',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Right Pinned Actions (Open, Save, Export PPTX, Export PDF, Present)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildIconButton(
                    icon: Icons.folder_open_rounded,
                    tooltip: 'Open Project / Import PPTX',
                    onPressed: onLoadProject,
                  ),
                  _buildIconButton(
                    icon: Icons.save_outlined,
                    tooltip: 'Save Project',
                    onPressed: onSaveProject,
                  ),
                  _buildIconButton(
                    icon: Icons.download_rounded,
                    tooltip: 'Export as PPTX (PowerPoint)',
                    onPressed: onExportPptx,
                  ),
                  _buildIconButton(
                    icon: Icons.picture_as_pdf_outlined,
                    tooltip: 'Export as PDF',
                    onPressed: onExportPdf,
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: const Text('Present', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: onStartPresentation,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContextualFormatting(BuildContext context, SlideElement elem) {
    if (elem.type == ElementType.text) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMiniIcon(
            Icons.remove_rounded,
            () => controller.updateElementTextStyle(
              elem.id,
              fontSize: (elem.fontSize - 4).clamp(10, 140),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '${elem.fontSize.toInt()}',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          _buildMiniIcon(
            Icons.add_rounded,
            () => controller.updateElementTextStyle(
              elem.id,
              fontSize: (elem.fontSize + 4).clamp(10, 140),
            ),
          ),
          const SizedBox(width: 8),
          _buildToggleIcon(
            Icons.format_bold_rounded,
            elem.isBold,
            () => controller.updateElementTextStyle(elem.id, isBold: !elem.isBold),
          ),
          _buildToggleIcon(
            Icons.format_italic_rounded,
            elem.isItalic,
            () => controller.updateElementTextStyle(elem.id, isItalic: !elem.isItalic),
          ),
          _buildToggleIcon(
            Icons.format_underlined_rounded,
            elem.isUnderline,
            () => controller.updateElementTextStyle(elem.id, isUnderline: !elem.isUnderline),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () {
              _showColorPicker(
                context: context,
                title: 'Text Color',
                currentColor: Color(elem.textColor),
                onColorChanged: (c) => controller.updateElementTextStyle(
                  elem.id,
                  textColor: c.toARGB32(),
                ),
              );
            },
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Color(elem.textColor),
                border: Border.all(color: Colors.white70, width: 1.5),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildMiniIcon(
            Icons.format_align_left_rounded,
            () => controller.updateElementTextStyle(elem.id, textAlign: 'left'),
          ),
          _buildMiniIcon(
            Icons.format_align_center_rounded,
            () => controller.updateElementTextStyle(elem.id, textAlign: 'center'),
          ),
          _buildMiniIcon(
            Icons.format_align_right_rounded,
            () => controller.updateElementTextStyle(elem.id, textAlign: 'right'),
          ),
        ],
      );
    } else if (elem.type == ElementType.shape) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Fill: ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          InkWell(
            onTap: () {
              _showColorPicker(
                context: context,
                title: 'Shape Fill Color',
                currentColor: Color(elem.fillColor),
                onColorChanged: (c) => controller.updateElementShapeStyle(
                  elem.id,
                  fillColor: c.toARGB32(),
                ),
              );
            },
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Color(elem.fillColor),
                border: Border.all(color: Colors.white70, width: 1.5),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text('Border: ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          InkWell(
            onTap: () {
              _showColorPicker(
                context: context,
                title: 'Shape Border Color',
                currentColor: Color(elem.strokeColor),
                onColorChanged: (c) => controller.updateElementShapeStyle(
                  elem.id,
                  strokeColor: c.toARGB32(),
                ),
              );
            },
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Color(elem.strokeColor),
                border: Border.all(color: Colors.white70, width: 1.5),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      );
    } else if (elem.type == ElementType.image) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Fit: ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          DropdownButton<String>(
            value: elem.fit,
            dropdownColor: const Color(0xFF1E293B),
            underline: const SizedBox(),
            style: const TextStyle(color: Colors.white, fontSize: 12),
            items: const [
              DropdownMenuItem(value: 'contain', child: Text('Contain')),
              DropdownMenuItem(value: 'cover', child: Text('Cover')),
              DropdownMenuItem(value: 'fill', child: Text('Fill')),
            ],
            onChanged: (val) {
              if (val != null) controller.updateElementImageFit(elem.id, val);
            },
          ),
        ],
      );
    } else if (elem.type == ElementType.table) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionPill(
            icon: Icons.add_rounded,
            label: 'Row',
            onTap: () => controller.addTableRow(elem.id),
          ),
          const SizedBox(width: 4),
          _buildActionPill(
            icon: Icons.remove_rounded,
            label: 'Row',
            onTap: () => controller.deleteTableRow(elem.id),
          ),
          const SizedBox(width: 8),
          _buildActionPill(
            icon: Icons.add_rounded,
            label: 'Col',
            onTap: () => controller.addTableColumn(elem.id),
          ),
          const SizedBox(width: 4),
          _buildActionPill(
            icon: Icons.remove_rounded,
            label: 'Col',
            onTap: () => controller.deleteTableColumn(elem.id),
          ),
          const SizedBox(width: 8),
          const Text('Header: ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          InkWell(
            onTap: () {
              _showColorPicker(
                context: context,
                title: 'Table Header Color',
                currentColor: Color(elem.tableHeaderColor),
                onColorChanged: (c) => controller.updateTableHeaderColor(elem.id, c.toARGB32()),
              );
            },
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Color(elem.tableHeaderColor),
                border: Border.all(color: Colors.white70, width: 1.5),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      );
    }
    return const SizedBox();
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF334155),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 2),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, String text, IconData icon) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF38BDF8)),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildMiniIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }

  Widget _buildToggleIcon(IconData icon, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0284C7) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFFF8FAFC),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: const Color(0xFF38BDF8)),
      label: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 24, color: const Color(0xFF334155));
  }
}
