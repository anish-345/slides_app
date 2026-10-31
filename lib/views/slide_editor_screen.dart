import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/presentation_controller.dart';
import '../models/slide_element.dart';
import '../services/pdf_export_service.dart';
import '../services/rust_engine_service.dart';
import '../services/storage_service.dart';
import '../widgets/format_inspector_panel.dart';
import '../widgets/office_ribbon_bar.dart';
import '../widgets/presentation_mode_view.dart';
import '../widgets/slide_canvas.dart';
import '../widgets/slide_layout_picker_dialog.dart';
import '../widgets/slide_thumbnail_sidebar.dart';
import '../widgets/slide_thumbnail_view.dart';
import '../widgets/status_bar.dart';

class SlideEditorScreen extends StatefulWidget {
  final PresentationController controller;

  const SlideEditorScreen({super.key, required this.controller});

  @override
  State<SlideEditorScreen> createState() => _SlideEditorScreenState();
}

class _SlideEditorScreenState extends State<SlideEditorScreen> {
  late final PresentationController _controller;
  double _zoomScale = 1.0;
  bool _showInspector = true;
  bool? _forceMode; // null = auto detect by screen width; true = force mobile; false = force desktop
  int _mobileRibbonTab = 0; // 0: Home, 1: Insert, 2: Design, 3: Table

  static const Color aviontiOrange = Color(0xFFC43E1C);

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
  }

  void _saveToStorage() {
    StorageService.saveRecentPresentation(_controller.presentation);
  }

  void _startPresentation() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, anim1, anim2) => PresentationModeView(controller: _controller),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  Future<void> _exportPdf() async {
    try {
      await PdfExportService.exportToPdf(_controller.presentation);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportPptx() async {
    try {
      final success = await StorageService.exportPptx(_controller);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PowerPoint (.pptx) exported successfully!'),
            backgroundColor: Color(0xFF059669),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export PPTX: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveProject() async {
    await StorageService.saveRecentPresentation(_controller.presentation);
    final success = await StorageService.saveProject(_controller);
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Project saved successfully!'),
            ],
          ),
          backgroundColor: Color(0xFF059669),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _loadProject() async {
    final success = await StorageService.loadProject(_controller);
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Presentation loaded successfully!'),
          backgroundColor: Color(0xFF059669),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _newProject() {
    _controller.newPresentation();
    _saveToStorage();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Started a new presentation.'),
        backgroundColor: Color(0xFF0284C7),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _handleGlobalShortcuts(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.f5) {
      _startPresentation();
      return;
    }

    if (HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed) {
      if (event.logicalKey == LogicalKeyboardKey.keyS) {
        _saveProject();
      } else if (event.logicalKey == LogicalKeyboardKey.keyO) {
        _loadProject();
      } else if (event.logicalKey == LogicalKeyboardKey.keyN) {
        _newProject();
      }
    }
  }

  void _showAddSlideMenu(BuildContext context) {
    showSlideLayoutPicker(
      context: context,
      controller: _controller,
    );
  }

  Future<void> _pickAndInsertImage() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'gif'],
    );

    if (files.isNotEmpty) {
      final file = files.first;
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);

      _controller.addImageElement(
        path: file.path ?? '',
        base64: base64String,
        x: 400,
        y: 250,
        width: 600,
        height: 400,
      );
      _saveToStorage();
    }
  }

  void _showEngineInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.bolt_rounded, color: Colors.amber, size: 24),
            SizedBox(width: 8),
            Text('Rust Core Engine Details', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Avionti Core: ${RustEngineService.getAviontiVersion()}',
              style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Slide Studio: ${RustEngineService.engineVersion}',
              style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12),
            ),
            const SizedBox(height: 12),
            const Text(
              '• FFI C-ABI: Zero overhead native DLL/SO bindings\n'
              '• Magnetic Snapping: Sub-millisecond boundary alignment\n'
              '• Text Analytics: High-speed lexical analysis\n'
              '• OpenXML (.pptx): Bidirectional fidelity preservation\n'
              '• Offline Mode: 100% private, cloud-free',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Color(0xFF38BDF8))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = _forceMode ?? (screenWidth < 800);

    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: _handleGlobalShortcuts,
      child: Scaffold(
        backgroundColor: const Color(0xFF090D16),
        body: SafeArea(
          child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
        ),
      ),
    );
  }

  // ==========================================
  // DESKTOP STUDIO LAYOUT
  // ==========================================
  Widget _buildDesktopLayout() {
    return Column(
      children: [
        // Top Multi-Tab Office Ribbon Bar
        OfficeRibbonBar(
          controller: _controller,
          onStartPresentation: _startPresentation,
          onExportPdf: _exportPdf,
          onExportPptx: _exportPptx,
          onSaveProject: _saveProject,
          onLoadProject: _loadProject,
          onNewProject: _newProject,
        ),

        // Workspace
        Expanded(
          child: Row(
            children: [
              // Left Vertical Slide Thumbnails
              SlideThumbnailSidebar(controller: _controller),

              // Center Scalable Slide Canvas
              Expanded(
                child: Container(
                  color: const Color(0xFF0B0F19),
                  child: SlideCanvas(
                    controller: _controller,
                    zoomScale: _zoomScale,
                  ),
                ),
              ),

              // Right Format Inspector Panel
              if (_showInspector)
                FormatInspectorPanel(controller: _controller),
            ],
          ),
        ),

        // Bottom Status Bar
        PresentationStatusBar(
          controller: _controller,
          zoomScale: _zoomScale,
          onZoomChanged: (zoom) => setState(() => _zoomScale = zoom),
          onFitToScreen: () => setState(() => _zoomScale = 1.0),
          isInspectorOpen: _showInspector,
          onToggleInspector: () => setState(() => _showInspector = !_showInspector),
        ),
      ],
    );
  }

  // ==========================================
  // MOBILE POWERPOINT LAYOUT (From Avionti)
  // ==========================================
  Widget _buildMobileLayout() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final selected = _controller.selectedElement;
        final hasTable = selected?.type == ElementType.table;

        return Column(
          children: [
            // 1. Mobile Top AppBar
            Container(
              height: 48,
              color: aviontiOrange,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                    tooltip: 'Back to Presentations Hub',
                    onPressed: () {
                      _saveToStorage();
                      Navigator.pop(context);
                    },
                  ),
                  Expanded(
                    child: Text(
                      _controller.presentation.title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.undo_rounded, color: Colors.white, size: 20),
                    tooltip: 'Undo',
                    onPressed: _controller.canUndo ? _controller.undo : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
                    tooltip: 'Present',
                    onPressed: _startPresentation,
                  ),
                  // Toggle to Desktop Studio Mode button
                  IconButton(
                    icon: const Icon(Icons.desktop_windows_rounded, color: Colors.white, size: 20),
                    tooltip: 'Switch to Desktop Studio Mode',
                    onPressed: () => setState(() => _forceMode = false),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                    color: const Color(0xFF1E293B),
                    onSelected: (val) {
                      if (val == 'engine_info') _showEngineInfoDialog();
                      if (val == 'export_pptx') _exportPptx();
                      if (val == 'export_pdf') _exportPdf();
                      if (val == 'save_proj') _saveProject();
                      if (val == 'delete_slide') _controller.deleteSlide(_controller.currentSlideIndex);
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'engine_info',
                        child: Row(
                          children: [
                            Icon(Icons.bolt_rounded, size: 16, color: Colors.amber),
                            SizedBox(width: 8),
                            Text('Rust Engine Info', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'export_pptx',
                        child: Row(
                          children: [
                            Icon(Icons.download_rounded, size: 16, color: Color(0xFF38BDF8)),
                            SizedBox(width: 8),
                            Text('Export PPTX', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'export_pdf',
                        child: Row(
                          children: [
                            Icon(Icons.picture_as_pdf_outlined, size: 16, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Export PDF', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'save_proj',
                        child: Row(
                          children: [
                            Icon(Icons.save_outlined, size: 16, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Save Project', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete_slide',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                            SizedBox(width: 8),
                            Text('Delete Slide', style: TextStyle(color: Colors.redAccent)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Interactive Slide Canvas Area
            Expanded(
              child: Container(
                color: const Color(0xFF0B0F19),
                child: SlideCanvas(
                  controller: _controller,
                  zoomScale: 1.0,
                ),
              ),
            ),

            // 3. Mobile Slide Filmstrip (Bottom horizontal thumbnails)
            _buildMobileFilmstrip(),

            // 4. Mobile Office Ribbon Bar (Home, Insert, Design, Table)
            _buildMobileRibbon(selected, hasTable),
          ],
        );
      },
    );
  }

  Widget _buildMobileFilmstrip() {
    final slides = _controller.presentation.slides;
    final currentIndex = _controller.currentSlideIndex;

    return Container(
      height: 76,
      color: const Color(0xFF0F172A),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF1E293B))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: slides.length,
              itemBuilder: (context, idx) {
                final isCurrent = idx == currentIndex;
                final slide = slides[idx];

                return GestureDetector(
                  onTap: () => _controller.selectSlide(idx),
                  child: Container(
                    width: 96,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Color(slide.backgroundColor),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isCurrent ? aviontiOrange : const Color(0xFF334155),
                        width: isCurrent ? 2 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        SlideThumbnailView(
                          slide: slide,
                          width: 96,
                          height: 54,
                        ),
                        Positioned(
                          left: 4,
                          top: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: isCurrent ? aviontiOrange : Colors.black54,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              '${idx + 1}',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_box_rounded, color: aviontiOrange, size: 30),
            tooltip: 'Add Slide',
            onPressed: () => _showAddSlideMenu(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileRibbon(SlideElement? selected, bool hasTable) {
    return Container(
      color: const Color(0xFF1E293B),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ribbon Tab Switcher
          Container(
            height: 36,
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF334155))),
            ),
            child: Row(
              children: [
                _buildMobileRibbonTab('Home', 0),
                _buildMobileRibbonTab('Insert', 1),
                _buildMobileRibbonTab('Design', 2),
                if (hasTable) _buildMobileRibbonTab('Table', 3, isHighlight: true),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF334155)),
          // Tab Tools Bar
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _buildMobileRibbonTools(selected, hasTable),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileRibbonTab(String title, int tabIndex, {bool isHighlight = false}) {
    final isSelected = _mobileRibbonTab == tabIndex;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _mobileRibbonTab = tabIndex),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? aviontiOrange : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isSelected
                  ? aviontiOrange
                  : (isHighlight ? const Color(0xFF38BDF8) : const Color(0xFF94A3B8)),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileRibbonTools(SlideElement? selected, bool hasTable) {
    if (_mobileRibbonTab == 0) {
      // Home Tools
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.format_bold_rounded,
                color: (selected?.isBold ?? false) ? aviontiOrange : Colors.white,
              ),
              onPressed: selected == null
                  ? null
                  : () {
                      _controller.updateElementFormat(selected.id, isBold: !selected.isBold);
                      _saveToStorage();
                    },
            ),
            IconButton(
              icon: Icon(
                Icons.format_italic_rounded,
                color: (selected?.isItalic ?? false) ? aviontiOrange : Colors.white,
              ),
              onPressed: selected == null
                  ? null
                  : () {
                      _controller.updateElementFormat(selected.id, isItalic: !selected.isItalic);
                      _saveToStorage();
                    },
            ),
            IconButton(
              icon: const Icon(Icons.text_increase_rounded, color: Colors.white),
              onPressed: selected == null
                  ? null
                  : () {
                      _controller.updateElementFormat(selected.id, fontSize: selected.fontSize + 4);
                      _saveToStorage();
                    },
            ),
            IconButton(
              icon: const Icon(Icons.text_decrease_rounded, color: Colors.white),
              onPressed: selected == null
                  ? null
                  : () {
                      if (selected.fontSize > 12) {
                        _controller.updateElementFormat(selected.id, fontSize: selected.fontSize - 4);
                        _saveToStorage();
                      }
                    },
            ),
            const VerticalDivider(color: Color(0xFF334155), indent: 10, endIndent: 10),
            IconButton(
              icon: const Icon(Icons.copy_rounded, color: Colors.white70),
              tooltip: 'Duplicate',
              onPressed: selected == null ? null : () => _controller.duplicateElement(selected.id),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              tooltip: 'Delete',
              onPressed: selected == null ? null : () => _controller.deleteElement(selected.id),
            ),
          ],
        ),
      );
    } else if (_mobileRibbonTab == 1) {
      // Insert Tools
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            TextButton.icon(
              onPressed: () {
                _controller.addTextElement(x: 400, y: 300, text: 'Tap to edit text');
                _saveToStorage();
              },
              icon: const Icon(Icons.text_fields_rounded, color: aviontiOrange, size: 18),
              label: const Text('Text Box', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
            const VerticalDivider(color: Color(0xFF334155), indent: 10, endIndent: 10),
            IconButton(
              icon: const Icon(Icons.crop_square_rounded, color: Colors.white),
              tooltip: 'Rectangle',
              onPressed: () => _controller.addShapeElement(shapeType: 'rectangle', fillColor: 0xFFC43E1C),
            ),
            IconButton(
              icon: const Icon(Icons.circle_outlined, color: Colors.white),
              tooltip: 'Circle',
              onPressed: () => _controller.addShapeElement(shapeType: 'circle', fillColor: 0xFF0284C7),
            ),
            IconButton(
              icon: const Icon(Icons.star_border_rounded, color: Colors.amber),
              tooltip: 'Star',
              onPressed: () => _controller.addShapeElement(shapeType: 'star', fillColor: 0xFFF59E0B),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_rounded, color: Colors.lightGreen),
              tooltip: 'Arrow',
              onPressed: () => _controller.addShapeElement(shapeType: 'arrow', fillColor: 0xFF10B981),
            ),
            const VerticalDivider(color: Color(0xFF334155), indent: 10, endIndent: 10),
            TextButton.icon(
              onPressed: () => _controller.addTableElement(rows: 4, cols: 4),
              icon: const Icon(Icons.table_chart_rounded, color: Color(0xFF38BDF8), size: 18),
              label: const Text('Table', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
            TextButton.icon(
              onPressed: _pickAndInsertImage,
              icon: const Icon(Icons.image_outlined, color: Colors.purpleAccent, size: 18),
              label: const Text('Image', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ),
      );
    } else if (_mobileRibbonTab == 2) {
      // Design Tools
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Text('Background: ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            _buildColorCircle('White', 0xFFFFFFFF),
            _buildColorCircle('Slate Dark', 0xFF0F172A),
            _buildColorCircle('Avionti Orange', 0xFFC43E1C),
            _buildColorCircle('Navy', 0xFF002B49),
            _buildColorCircle('Blue', 0xFF1D4ED8),
            _buildColorCircle('Charcoal', 0xFF1E1E1E),
          ],
        ),
      );
    } else {
      // Table Tools
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            TextButton.icon(
              onPressed: selected == null ? null : () => _controller.addTableRow(selected.id),
              icon: const Icon(Icons.add_rounded, color: Color(0xFF38BDF8), size: 16),
              label: const Text('+ Row', style: TextStyle(color: Colors.white, fontSize: 11)),
            ),
            TextButton.icon(
              onPressed: selected == null ? null : () => _controller.deleteTableRow(selected.id),
              icon: const Icon(Icons.remove_rounded, color: Colors.redAccent, size: 16),
              label: const Text('- Row', style: TextStyle(color: Colors.white, fontSize: 11)),
            ),
            const VerticalDivider(color: Color(0xFF334155), indent: 10, endIndent: 10),
            TextButton.icon(
              onPressed: selected == null ? null : () => _controller.addTableColumn(selected.id),
              icon: const Icon(Icons.add_rounded, color: Color(0xFF38BDF8), size: 16),
              label: const Text('+ Col', style: TextStyle(color: Colors.white, fontSize: 11)),
            ),
            TextButton.icon(
              onPressed: selected == null ? null : () => _controller.deleteTableColumn(selected.id),
              icon: const Icon(Icons.remove_rounded, color: Colors.redAccent, size: 16),
              label: const Text('- Col', style: TextStyle(color: Colors.white, fontSize: 11)),
            ),
            const VerticalDivider(color: Color(0xFF334155), indent: 10, endIndent: 10),
            TextButton(
              onPressed: selected == null ? null : () => _controller.setTableHeaderColor(selected.id, 0xFFC43E1C),
              child: const Text('Orange Header', style: TextStyle(color: aviontiOrange, fontSize: 11)),
            ),
            TextButton(
              onPressed: selected == null ? null : () => _controller.setTableHeaderColor(selected.id, 0xFF0284C7),
              child: const Text('Blue Header', style: TextStyle(color: Color(0xFF0284C7), fontSize: 11)),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildColorCircle(String tooltip, int colorVal) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          _controller.setSlideBackground(colorVal);
          _saveToStorage();
        },
        child: Container(
          width: 26,
          height: 26,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: Color(colorVal),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white30, width: 1.5),
          ),
        ),
      ),
    );
  }
}
