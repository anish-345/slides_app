import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../controllers/presentation_controller.dart';
import '../models/slide_element.dart';
import 'slide_layout_picker_dialog.dart';

enum RibbonTab { home, insert, design, tableTools, slideShow }

class OfficeRibbonBar extends StatefulWidget {
  final PresentationController controller;
  final VoidCallback onStartPresentation;
  final VoidCallback onExportPdf;
  final VoidCallback onExportPptx;
  final VoidCallback onSaveProject;
  final VoidCallback onLoadProject;
  final VoidCallback onNewProject;

  const OfficeRibbonBar({
    super.key,
    required this.controller,
    required this.onStartPresentation,
    required this.onExportPdf,
    required this.onExportPptx,
    required this.onSaveProject,
    required this.onLoadProject,
    required this.onNewProject,
  });

  @override
  State<OfficeRibbonBar> createState() => _OfficeRibbonBarState();
}

class _OfficeRibbonBarState extends State<OfficeRibbonBar> {
  RibbonTab _activeTab = RibbonTab.home;

  Future<void> _pickAndAddImage(BuildContext context) async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'gif'],
    );

    if (files.isNotEmpty) {
      final file = files.first;
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);

      widget.controller.addImageElement(
        path: file.path ?? '',
        base64: base64String,
        x: 400,
        y: 250,
        width: 600,
        height: 400,
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
      listenable: widget.controller,
      builder: (context, _) {
        final selected = widget.controller.selectedElement;
        final hasTable = selected?.type == ElementType.table;

        return Container(
          color: const Color(0xFF0F172A), // Office Dark Slate header
          child: Column(
            children: [
              // 1. Top Quick Access & Title Bar
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
                ),
                child: Row(
                  children: [
                    // Brand Icon
                    const Icon(Icons.slideshow_rounded, color: Color(0xFF38BDF8), size: 20),
                    const SizedBox(width: 8),
                    // Quick Action Icons
                    _buildQuickAction(
                      icon: Icons.save_outlined,
                      tooltip: 'Save (Ctrl+S)',
                      onTap: widget.onSaveProject,
                    ),
                    _buildQuickAction(
                      icon: Icons.undo_rounded,
                      tooltip: 'Undo (Ctrl+Z)',
                      enabled: widget.controller.canUndo,
                      onTap: widget.controller.canUndo ? widget.controller.undo : null,
                    ),
                    _buildQuickAction(
                      icon: Icons.redo_rounded,
                      tooltip: 'Redo (Ctrl+Y)',
                      enabled: widget.controller.canRedo,
                      onTap: widget.controller.canRedo ? widget.controller.redo : null,
                    ),
                    const SizedBox(width: 14),
                    Container(width: 1, height: 16, color: const Color(0xFF334155)),
                    const SizedBox(width: 14),

                    // Document Title
                    Expanded(
                      child: Text(
                        '${widget.controller.presentation.title} — Native Office Suite',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    // Present Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        minimumSize: const Size(0, 26),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 16),
                      label: const Text('Present (F5)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: widget.onStartPresentation,
                    ),
                  ],
                ),
              ),

              // 2. Ribbon Tabs Row
              Container(
                height: 32,
                color: const Color(0xFF1E293B),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    _buildRibbonTabHeader('Home', RibbonTab.home),
                    _buildRibbonTabHeader('Insert', RibbonTab.insert),
                    _buildRibbonTabHeader('Design', RibbonTab.design),
                    if (hasTable) _buildRibbonTabHeader('Table Tools', RibbonTab.tableTools, isHighlight: true),
                    _buildRibbonTabHeader('Slide Show', RibbonTab.slideShow),
                  ],
                ),
              ),

              // 3. Ribbon Content Band (Tools corresponding to active tab)
              Container(
                height: 82,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFF0B132B), // Modern dark band
                  border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (_activeTab == RibbonTab.home) _buildHomeTab(context, selected),
                      if (_activeTab == RibbonTab.insert) _buildInsertTab(context),
                      if (_activeTab == RibbonTab.design) _buildDesignTab(context),
                      if (_activeTab == RibbonTab.tableTools || (hasTable && _activeTab == RibbonTab.home))
                        _buildTableToolsTab(context, selected!),
                      if (_activeTab == RibbonTab.slideShow) _buildSlideShowTab(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Tab Contents ---

  Widget _buildHomeTab(BuildContext context, SlideElement? selected) {
    return Row(
      children: [
        // File Section
        _buildRibbonSection(
          title: 'FILE',
          children: [
            _buildRibbonButton(
              icon: Icons.note_add_outlined,
              label: 'New',
              onTap: widget.onNewProject,
            ),
            _buildRibbonButton(
              icon: Icons.folder_open_rounded,
              label: 'Open',
              onTap: widget.onLoadProject,
            ),
            _buildRibbonButton(
              icon: Icons.save_outlined,
              label: 'Save',
              onTap: widget.onSaveProject,
            ),
            _buildRibbonButton(
              icon: Icons.download_rounded,
              label: 'Export PPTX',
              color: const Color(0xFF38BDF8),
              onTap: widget.onExportPptx,
            ),
            _buildRibbonButton(
              icon: Icons.picture_as_pdf_outlined,
              label: 'PDF',
              onTap: widget.onExportPdf,
            ),
          ],
        ),

        _buildSectionDivider(),

        // Insert Quick Section
        _buildRibbonSection(
          title: 'INSERT',
          children: [
            _buildRibbonButton(
              icon: Icons.post_add_rounded,
              label: 'New Slide',
              onTap: () => showSlideLayoutPicker(context: context, controller: widget.controller),
            ),
            _buildRibbonButton(
              icon: Icons.text_fields_rounded,
              label: 'Text Box',
              onTap: () => widget.controller.addTextElement(),
            ),
            _buildRibbonButton(
              icon: Icons.image_outlined,
              label: 'Picture',
              onTap: () => _pickAndAddImage(context),
            ),
            _buildRibbonButton(
              icon: Icons.table_chart_outlined,
              label: 'Table',
              onTap: () => widget.controller.addTableElement(),
            ),
          ],
        ),

        _buildSectionDivider(),

        // Font Formatting Section
        _buildRibbonSection(
          title: 'FONT & PARAGRAPH',
          children: [
            if (selected?.type == ElementType.text) ...[
              _buildMiniIconButton(
                icon: Icons.remove,
                tooltip: 'Decrease Font Size',
                onTap: () => widget.controller.updateElementTextStyle(
                  selected!.id,
                  fontSize: (selected.fontSize - 4).clamp(10, 140),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '${selected!.fontSize.toInt()} pt',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              _buildMiniIconButton(
                icon: Icons.add,
                tooltip: 'Increase Font Size',
                onTap: () => widget.controller.updateElementTextStyle(
                  selected.id,
                  fontSize: (selected.fontSize + 4).clamp(10, 140),
                ),
              ),
              const SizedBox(width: 6),
              _buildToggleBox(
                icon: Icons.format_bold_rounded,
                active: selected.isBold,
                onTap: () => widget.controller.updateElementTextStyle(selected.id, isBold: !selected.isBold),
              ),
              _buildToggleBox(
                icon: Icons.format_italic_rounded,
                active: selected.isItalic,
                onTap: () => widget.controller.updateElementTextStyle(selected.id, isItalic: !selected.isItalic),
              ),
              _buildToggleBox(
                icon: Icons.format_underlined_rounded,
                active: selected.isUnderline,
                onTap: () => widget.controller.updateElementTextStyle(selected.id, isUnderline: !selected.isUnderline),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () {
                  _showColorPicker(
                    context: context,
                    title: 'Text Color',
                    currentColor: Color(selected.textColor),
                    onColorChanged: (c) => widget.controller.updateElementTextStyle(selected.id, textColor: c.toARGB32()),
                  );
                },
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Color(selected.textColor),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.white70, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildMiniIconButton(
                icon: Icons.format_align_left_rounded,
                tooltip: 'Align Left',
                onTap: () => widget.controller.updateElementTextStyle(selected.id, textAlign: 'left'),
              ),
              _buildMiniIconButton(
                icon: Icons.format_align_center_rounded,
                tooltip: 'Align Center',
                onTap: () => widget.controller.updateElementTextStyle(selected.id, textAlign: 'center'),
              ),
              _buildMiniIconButton(
                icon: Icons.format_align_right_rounded,
                tooltip: 'Align Right',
                onTap: () => widget.controller.updateElementTextStyle(selected.id, textAlign: 'right'),
              ),
            ] else ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text('Select text to format font, size & colors', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildInsertTab(BuildContext context) {
    return Row(
      children: [
        _buildRibbonSection(
          title: 'SLIDES',
          children: [
            _buildRibbonButton(
              icon: Icons.post_add_rounded,
              label: 'New Slide',
              onTap: () => showSlideLayoutPicker(context: context, controller: widget.controller),
            ),
          ],
        ),
        _buildSectionDivider(),
        _buildRibbonSection(
          title: 'MEDIA & TABLES',
          children: [
            _buildRibbonButton(
              icon: Icons.image_rounded,
              label: 'Picture',
              onTap: () => _pickAndAddImage(context),
            ),
            _buildRibbonButton(
              icon: Icons.table_chart_rounded,
              label: 'Table',
              onTap: () => widget.controller.addTableElement(),
            ),
            _buildRibbonButton(
              icon: Icons.text_fields_rounded,
              label: 'Text Box',
              onTap: () => widget.controller.addTextElement(),
            ),
          ],
        ),
        _buildSectionDivider(),
        _buildRibbonSection(
          title: 'SHAPES',
          children: [
            _buildRibbonButton(
              icon: Icons.crop_square_rounded,
              label: 'Rectangle',
              onTap: () => widget.controller.addShapeElement(shapeType: 'rectangle'),
            ),
            _buildRibbonButton(
              icon: Icons.crop_portrait_rounded,
              label: 'Rounded Rect',
              onTap: () => widget.controller.addShapeElement(shapeType: 'rounded_rect'),
            ),
            _buildRibbonButton(
              icon: Icons.circle_outlined,
              label: 'Circle',
              onTap: () => widget.controller.addShapeElement(shapeType: 'circle'),
            ),
            _buildRibbonButton(
              icon: Icons.change_history_rounded,
              label: 'Triangle',
              onTap: () => widget.controller.addShapeElement(shapeType: 'triangle'),
            ),
            _buildRibbonButton(
              icon: Icons.arrow_right_alt_rounded,
              label: 'Arrow',
              onTap: () => widget.controller.addShapeElement(shapeType: 'arrow'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesignTab(BuildContext context) {
    return Row(
      children: [
        _buildRibbonSection(
          title: 'THEME PRESETS',
          children: [
            _buildThemePill('Dark Slate', 0xFF0F172A),
            _buildThemePill('Corporate Navy', 0xFF0B1B3D),
            _buildThemePill('Clean White', 0xFFFFFFFF),
            _buildThemePill('Warm Cream', 0xFFFEF3C7),
          ],
        ),
        _buildSectionDivider(),
        _buildRibbonSection(
          title: 'CUSTOM BACKGROUND',
          children: [
            _buildRibbonButton(
              icon: Icons.palette_outlined,
              label: 'Pick Color',
              onTap: () {
                _showColorPicker(
                  context: context,
                  title: 'Slide Background Color',
                  currentColor: Color(widget.controller.currentSlide.backgroundColor),
                  onColorChanged: (c) => widget.controller.setSlideBackground(c.toARGB32()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTableToolsTab(BuildContext context, SlideElement elem) {
    return Row(
      children: [
        _buildRibbonSection(
          title: 'ROWS & COLUMNS',
          children: [
            _buildRibbonButton(
              icon: Icons.add_box_outlined,
              label: '+ Row',
              onTap: () => widget.controller.addTableRow(elem.id),
            ),
            _buildRibbonButton(
              icon: Icons.indeterminate_check_box_outlined,
              label: '- Row',
              onTap: () => widget.controller.deleteTableRow(elem.id),
            ),
            _buildRibbonButton(
              icon: Icons.view_column_outlined,
              label: '+ Column',
              onTap: () => widget.controller.addTableColumn(elem.id),
            ),
            _buildRibbonButton(
              icon: Icons.table_rows_outlined,
              label: '- Column',
              onTap: () => widget.controller.deleteTableColumn(elem.id),
            ),
          ],
        ),
        _buildSectionDivider(),
        _buildRibbonSection(
          title: 'TABLE STYLES',
          children: [
            _buildRibbonButton(
              icon: Icons.format_color_fill_rounded,
              label: 'Header Color',
              onTap: () {
                _showColorPicker(
                  context: context,
                  title: 'Table Header Color',
                  currentColor: Color(elem.tableHeaderColor),
                  onColorChanged: (c) => widget.controller.updateTableHeaderColor(elem.id, c.toARGB32()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSlideShowTab() {
    return Row(
      children: [
        _buildRibbonSection(
          title: 'START PRESENTATION',
          children: [
            _buildRibbonButton(
              icon: Icons.play_circle_fill_rounded,
              label: 'From Beginning (F5)',
              color: const Color(0xFF38BDF8),
              onTap: () {
                widget.controller.selectSlide(0);
                widget.onStartPresentation();
              },
            ),
            _buildRibbonButton(
              icon: Icons.play_arrow_rounded,
              label: 'From Current Slide',
              onTap: widget.onStartPresentation,
            ),
          ],
        ),
      ],
    );
  }

  // --- Sub-widgets & Builders ---

  Widget _buildRibbonTabHeader(String title, RibbonTab tab, {bool isHighlight = false}) {
    final isActive = _activeTab == tab;

    return InkWell(
      onTap: () => setState(() => _activeTab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0B132B) : Colors.transparent,
          border: Border(
            top: BorderSide(
              color: isActive ? (isHighlight ? const Color(0xFFF59E0B) : const Color(0xFF38BDF8)) : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF94A3B8),
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildRibbonSection({required String title, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(color: Color(0xFF475569), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
        ],
      ),
    );
  }

  Widget _buildRibbonButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: color, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildThemePill(String name, int colorVal) {
    return InkWell(
      onTap: () => widget.controller.setSlideBackground(colorVal),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Color(colorVal),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          name,
          style: TextStyle(
            color: colorVal == 0xFFFFFFFF || colorVal == 0xFFFEF3C7 ? Colors.black : Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
    bool enabled = true,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Icon(
            icon,
            size: 16,
            color: enabled ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(3),
        child: Padding(
          padding: const EdgeInsets.all(3.0),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildToggleBox({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(3),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0284C7) : Colors.transparent,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }

  Widget _buildSectionDivider() {
    return Container(
      width: 1,
      height: 38,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: const Color(0xFF1E293B),
    );
  }
}

