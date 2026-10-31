import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/presentation.dart';
import '../models/slide.dart';
import '../models/slide_element.dart';

enum SlideLayout { title, titleAndContent, twoColumn, table, blank, sectionHeader }

class PresentationController extends ChangeNotifier {
  final Uuid _uuid = const Uuid();
  late Presentation _presentation;
  int _currentSlideIndex = 0;
  String? _selectedElementId;
  String? _editingTextElementId;

  // Undo / Redo History
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];
  static const int _maxHistory = 30;

  PresentationController() {
    _initDefaultPresentation();
  }

  void _initDefaultPresentation() {
    final titleSlideId = _uuid.v4();
    final firstSlide = Slide(
      id: titleSlideId,
      title: 'Title Slide',
      backgroundColor: 0xFF0F172A, // Deep slate dark mode
      elements: [
        SlideElement(
          id: _uuid.v4(),
          type: ElementType.text,
          x: 240,
          y: 320,
          width: 1440,
          height: 180,
          text: 'Next-Gen Native Presentations',
          fontSize: 64,
          isBold: true,
          textColor: 0xFFF8FAFC,
          textAlign: 'center',
          zIndex: 1,
        ),
        SlideElement(
          id: _uuid.v4(),
          type: ElementType.text,
          x: 360,
          y: 520,
          width: 1200,
          height: 100,
          text: 'Built with Flutter & High-Performance Native Architecture',
          fontSize: 32,
          isItalic: true,
          textColor: 0xFF94A3B8,
          textAlign: 'center',
          zIndex: 2,
        ),
        SlideElement(
          id: _uuid.v4(),
          type: ElementType.shape,
          x: 720,
          y: 660,
          width: 480,
          height: 8,
          shapeType: 'rounded_rect',
          fillColor: 0xFF38BDF8, // Sky-400 accent bar
          strokeColor: 0x00000000,
          strokeWidth: 0,
          zIndex: 3,
        ),
      ],
    );

    _presentation = Presentation(
      id: _uuid.v4(),
      title: 'Native Slides Studio',
      slides: [firstSlide],
    );
    _currentSlideIndex = 0;
  }

  // Getters
  Presentation get presentation => _presentation;
  int get currentSlideIndex => _currentSlideIndex;
  Slide get currentSlide => _presentation.slides.isNotEmpty
      ? _presentation.slides[_currentSlideIndex]
      : Slide(id: 'empty');
  String? get selectedElementId => _selectedElementId;
  String? get editingTextElementId => _editingTextElementId;

  SlideElement? get selectedElement {
    if (_selectedElementId == null) return null;
    try {
      return currentSlide.elements.firstWhere((e) => e.id == _selectedElementId);
    } catch (_) {
      return null;
    }
  }

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  // History Management
  void _recordHistory() {
    final snapshot = jsonEncode(_presentation.toJson());
    _undoStack.add(snapshot);
    if (_undoStack.length > _maxHistory) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  void undo() {
    if (!canUndo) return;
    final current = jsonEncode(_presentation.toJson());
    _redoStack.add(current);
    final previous = _undoStack.removeLast();
    _presentation = Presentation.fromJson(jsonDecode(previous) as Map<String, dynamic>);
    if (_currentSlideIndex >= _presentation.slides.length) {
      _currentSlideIndex = _presentation.slides.length - 1;
    }
    _selectedElementId = null;
    _editingTextElementId = null;
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    final current = jsonEncode(_presentation.toJson());
    _undoStack.add(current);
    final next = _redoStack.removeLast();
    _presentation = Presentation.fromJson(jsonDecode(next) as Map<String, dynamic>);
    if (_currentSlideIndex >= _presentation.slides.length) {
      _currentSlideIndex = _presentation.slides.length - 1;
    }
    _selectedElementId = null;
    _editingTextElementId = null;
    notifyListeners();
  }

  // Slide Actions
  void addSlide({int? afterIndex}) {
    addSlideWithLayout(SlideLayout.titleAndContent, afterIndex: afterIndex);
  }

  void addSlideWithLayout(SlideLayout layout, {int? afterIndex}) {
    _recordHistory();
    final slideId = _uuid.v4();
    final elements = <SlideElement>[];
    int bgColor = 0xFFFFFFFF;

    switch (layout) {
      case SlideLayout.title:
        elements.addAll([
          SlideElement(
            id: _uuid.v4(),
            type: ElementType.text,
            x: 120,
            y: 320,
            width: 1680,
            height: 160,
            text: 'Double-Tap to Add Title',
            fontSize: 64,
            isBold: true,
            textColor: 0xFFC43E1C, // Avionti Orange
            textAlign: 'center',
            zIndex: 1,
          ),
          SlideElement(
            id: _uuid.v4(),
            type: ElementType.text,
            x: 120,
            y: 500,
            width: 1680,
            height: 80,
            text: 'Subtitle — Powered by Avionti Rust Engine',
            fontSize: 28,
            isItalic: true,
            textColor: 0xFF64748B,
            textAlign: 'center',
            zIndex: 2,
          ),
          SlideElement(
            id: _uuid.v4(),
            type: ElementType.shape,
            x: 860,
            y: 600,
            width: 200,
            height: 6,
            shapeType: 'rounded_rect',
            fillColor: 0xFFC43E1C,
            strokeColor: 0x00000000,
            zIndex: 3,
          ),
        ]);
        break;

      case SlideLayout.titleAndContent:
        elements.addAll([
          SlideElement(
            id: _uuid.v4(),
            type: ElementType.text,
            x: 120,
            y: 80,
            width: 1680,
            height: 90,
            text: 'Slide Title Heading',
            fontSize: 44,
            isBold: true,
            textColor: 0xFF0F172A,
            zIndex: 1,
          ),
          SlideElement(
            id: _uuid.v4(),
            type: ElementType.text,
            x: 120,
            y: 200,
            width: 1680,
            height: 750,
            text: '• Double-tap to enter bullet points or body text\n• Drag and reposition elements freely anywhere on the canvas\n• Insert shapes, images and multi-column tables from the ribbon\n• 100% offline-first native performance',
            fontSize: 28,
            textColor: 0xFF334155,
            zIndex: 2,
          ),
        ]);
        break;

      case SlideLayout.twoColumn:
        elements.addAll([
          SlideElement(
            id: _uuid.v4(),
            type: ElementType.text,
            x: 120,
            y: 80,
            width: 1680,
            height: 90,
            text: 'Comparative Architecture',
            fontSize: 44,
            isBold: true,
            textColor: 0xFF0F172A,
            zIndex: 1,
          ),
          SlideElement(
            id: _uuid.v4(),
            type: ElementType.text,
            x: 120,
            y: 200,
            width: 800,
            height: 750,
            text: 'Column A: Native Capabilities\n\n• Sub-millisecond Rust FFI processing\n• Real-time vector rendering\n• Bidirectional .pptx import and export\n• Cross-platform desktop & mobile UI',
            fontSize: 26,
            textColor: 0xFF1E293B,
            zIndex: 2,
          ),
          SlideElement(
            id: _uuid.v4(),
            type: ElementType.text,
            x: 1000,
            y: 200,
            width: 800,
            height: 750,
            text: 'Column B: Productivity Tools\n\n• Multi-tab Office & WPS ribbon bar\n• In-place text formatting and styles\n• In-cell interactive table editing\n• Responsive slide show presenter',
            fontSize: 26,
            textColor: 0xFF1E293B,
            zIndex: 3,
          ),
        ]);
        break;

      case SlideLayout.table:
        elements.addAll([
          SlideElement(
            id: _uuid.v4(),
            type: ElementType.text,
            x: 120,
            y: 80,
            width: 1680,
            height: 80,
            text: 'Specifications & Data Schedule',
            fontSize: 40,
            isBold: true,
            textColor: 0xFF0F172A,
            zIndex: 1,
          ),
          SlideElement(
            id: _uuid.v4(),
            type: ElementType.table,
            x: 120,
            y: 190,
            width: 1680,
            height: 780,
            tableRows: 5,
            tableCols: 5,
            tableColWidths: [0.22, 0.22, 0.22, 0.20, 0.14],
            tableData: [
              ['Category', 'Parameter', 'Specification', 'Requirement', 'Status'],
              ['Structure', 'Waterproofing Membrane', '2-coat elastomeric PU', 'Zero ponding', 'Approved'],
              ['Thermal', 'Fire-Stop Sealant', 'Class A intumescent', '2-hr rating', 'Compliant'],
              ['Foundation', 'Plinth Band Damp Proof', '40 mm PCC (1:1.5:3)', 'IS 3067:1988', 'Verified'],
              ['Roofing', 'Terrace Liquid Membrane', 'Polyurethane + mesh', '1:60 gradient', 'Passed'],
            ],
            tableHeaderColor: 0xFFC43E1C, // Avionti Orange
            tableRowColor: 0xFFFFFFFF,
            tableAltRowColor: 0xFFFFF7ED,
            tableBorderColor: 0xFFCBD5E1,
            tableFontSize: 20,
            zIndex: 2,
          ),
        ]);
        break;

      case SlideLayout.sectionHeader:
        elements.addAll([
          SlideElement(
            id: _uuid.v4(),
            type: ElementType.text,
            x: 120,
            y: 420,
            width: 1680,
            height: 140,
            text: 'Section 01 — Executive Roadmap',
            fontSize: 56,
            isBold: true,
            textColor: 0xFF0F172A,
            textAlign: 'center',
            zIndex: 1,
          ),
          SlideElement(
            id: _uuid.v4(),
            type: ElementType.shape,
            x: 810,
            y: 580,
            width: 300,
            height: 6,
            shapeType: 'rounded_rect',
            fillColor: 0xFFC43E1C,
            strokeColor: 0x00000000,
            zIndex: 2,
          ),
        ]);
        break;

      case SlideLayout.blank:
        break;
    }

    final newSlide = Slide(
      id: slideId,
      title: 'Slide ${_presentation.slides.length + 1}',
      backgroundColor: bgColor,
      elements: elements,
    );

    final insertIdx = afterIndex != null ? afterIndex + 1 : _currentSlideIndex + 1;
    if (insertIdx >= _presentation.slides.length) {
      _presentation.slides.add(newSlide);
      _currentSlideIndex = _presentation.slides.length - 1;
    } else {
      _presentation.slides.insert(insertIdx, newSlide);
      _currentSlideIndex = insertIdx;
    }
    _selectedElementId = null;
    _editingTextElementId = null;
    notifyListeners();
  }

  void duplicateSlide(int index) {
    if (index < 0 || index >= _presentation.slides.length) return;
    _recordHistory();
    final original = _presentation.slides[index];
    final duplicated = Slide(
      id: _uuid.v4(),
      title: '${original.title} (Copy)',
      backgroundColor: original.backgroundColor,
      backgroundGradient: original.backgroundGradient,
      backgroundImagePath: original.backgroundImagePath,
      elements: original.elements
          .map((e) => e.copyWith(id: _uuid.v4()))
          .toList(),
      notes: original.notes,
    );

    _presentation.slides.insert(index + 1, duplicated);
    _currentSlideIndex = index + 1;
    _selectedElementId = null;
    notifyListeners();
  }

  void deleteSlide(int index) {
    if (_presentation.slides.length <= 1) return; // Keep at least one
    _recordHistory();
    _presentation.slides.removeAt(index);
    if (_currentSlideIndex >= _presentation.slides.length) {
      _currentSlideIndex = _presentation.slides.length - 1;
    }
    _selectedElementId = null;
    _editingTextElementId = null;
    notifyListeners();
  }

  void selectSlide(int index) {
    if (index < 0 || index >= _presentation.slides.length) return;
    _currentSlideIndex = index;
    _selectedElementId = null;
    _editingTextElementId = null;
    notifyListeners();
  }

  void reorderSlide(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _presentation.slides.length) return;
    if (newIndex < 0 || newIndex >= _presentation.slides.length) return;
    _recordHistory();
    final item = _presentation.slides.removeAt(oldIndex);
    _presentation.slides.insert(newIndex, item);
    _currentSlideIndex = newIndex;
    notifyListeners();
  }

  void setSlideBackground(int color) {
    _recordHistory();
    currentSlide.backgroundColor = color;
    notifyListeners();
  }

  // Element Selection & Editing
  void selectElement(String? id) {
    if (_selectedElementId == id && _editingTextElementId == null) return;
    _selectedElementId = id;
    if (_editingTextElementId != id) {
      _editingTextElementId = null;
    }
    notifyListeners();
  }

  void startEditingText(String? id) {
    _selectedElementId = id;
    _editingTextElementId = id;
    notifyListeners();
  }

  void stopEditingText() {
    if (_editingTextElementId != null) {
      _editingTextElementId = null;
      notifyListeners();
    }
  }



  // Adding Elements
  void addTextElement({double? x, double? y, String text = 'Tap to edit text'}) {
    _recordHistory();
    final id = _uuid.v4();

    double targetX = x ?? 280.0;
    double targetY = y ?? 220.0;
    if (x == null && y == null) {
      final textElemCount = currentSlide.elements.where((e) => e.type == ElementType.text).length;
      targetY = (200.0 + (textElemCount * 50.0)).clamp(150.0, 720.0);
    }

    final isDarkBg = currentSlide.backgroundColor < 0xFF888888;
    final element = SlideElement(
      id: id,
      type: ElementType.text,
      x: targetX,
      y: targetY,
      width: 500,
      height: 100,
      text: text,
      fontSize: 32,
      textColor: isDarkBg ? 0xFFF8FAFC : 0xFF0F172A,
      zIndex: _getNextZIndex(),
    );
    currentSlide.elements.add(element);
    _selectedElementId = id;
    _editingTextElementId = id; // Instantly start typing
    notifyListeners();
  }

  void addImageElement({
    required String path,
    String? base64,
    double x = 300,
    double y = 200,
    double width = 500,
    double height = 350,
  }) {
    _recordHistory();
    final id = _uuid.v4();
    final element = SlideElement(
      id: id,
      type: ElementType.image,
      x: x,
      y: y,
      width: width,
      height: height,
      imagePath: path,
      imageBase64: base64,
      fit: 'contain',
      zIndex: _getNextZIndex(),
    );
    currentSlide.elements.add(element);
    _selectedElementId = id;
    notifyListeners();
  }

  void addShapeElement({
    required String shapeType,
    double x = 400,
    double y = 300,
    double width = 250,
    double height = 200,
    int fillColor = 0xFF3B82F6,
    int strokeColor = 0xFF1D4ED8,
  }) {
    _recordHistory();
    final id = _uuid.v4();
    final element = SlideElement(
      id: id,
      type: ElementType.shape,
      x: x,
      y: y,
      width: width,
      height: height,
      shapeType: shapeType,
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: 2,
      zIndex: _getNextZIndex(),
    );
    currentSlide.elements.add(element);
    _selectedElementId = id;
    notifyListeners();
  }

  void addTableElement({
    double x = 460,
    double y = 300,
    double width = 1000,
    double height = 360,
    int rows = 3,
    int cols = 3,
  }) {
    _recordHistory();
    final id = _uuid.v4();
    final List<List<String>> initialData = List.generate(
      rows,
      (r) => List.generate(
        cols,
        (c) => r == 0 ? 'Header ${c + 1}' : 'Data $r-${c + 1}',
      ),
    );

    final element = SlideElement(
      id: id,
      type: ElementType.table,
      x: x,
      y: y,
      width: width,
      height: height,
      tableRows: rows,
      tableCols: cols,
      tableData: initialData,
      zIndex: _getNextZIndex(),
    );
    currentSlide.elements.add(element);
    _selectedElementId = id;
    notifyListeners();
  }

  void updateTableCell(String id, int row, int col, String value) {
    final elem = _findElement(id);
    if (elem != null && elem.type == ElementType.table) {
      if (row >= 0 && row < elem.tableData.length) {
        if (col >= 0 && col < elem.tableData[row].length) {
          elem.tableData[row][col] = value;
          notifyListeners();
        }
      }
    }
  }

  void addTableRow(String id) {
    final elem = _findElement(id);
    if (elem != null && elem.type == ElementType.table) {
      _recordHistory();
      final cols = elem.tableData.isNotEmpty ? elem.tableData.first.length : 3;
      final newRow = List.generate(cols, (c) => 'New ${elem.tableData.length}-$c');
      elem.tableData.add(newRow);
      elem.tableRows = elem.tableData.length;
      elem.height += 60; // Auto-expand height
      notifyListeners();
    }
  }



  void deleteTableRow(String id) {
    final elem = _findElement(id);
    if (elem != null && elem.type == ElementType.table && elem.tableData.length > 1) {
      _recordHistory();
      elem.tableData.removeLast();
      elem.tableRows = elem.tableData.length;
      elem.height = (elem.height - 60).clamp(100.0, 1000.0);
      notifyListeners();
    }
  }



  void addTableColumn(String id) {
    final elem = _findElement(id);
    if (elem != null && elem.type == ElementType.table) {
      _recordHistory();
      for (int r = 0; r < elem.tableData.length; r++) {
        elem.tableData[r].add(r == 0 ? 'Col ${elem.tableData[r].length + 1}' : 'Cell');
      }
      elem.tableCols = elem.tableData.first.length;
      elem.width += 120;
      notifyListeners();
    }
  }



  void deleteTableColumn(String id) {
    final elem = _findElement(id);
    if (elem != null && elem.type == ElementType.table) {
      if (elem.tableData.isNotEmpty && elem.tableData.first.length > 1) {
        _recordHistory();
        for (int r = 0; r < elem.tableData.length; r++) {
          elem.tableData[r].removeLast();
        }
        elem.tableCols = elem.tableData.first.length;
        elem.width = (elem.width - 120).clamp(200.0, 1800.0);
        notifyListeners();
      }
    }
  }

  void updateTableHeaderColor(String id, int color) {
    final elem = _findElement(id);
    if (elem != null && elem.type == ElementType.table) {
      _recordHistory();
      elem.tableHeaderColor = color;
      notifyListeners();
    }
  }

  void updateTableFontSize(String id, double size) {
    final elem = _findElement(id);
    if (elem != null && elem.type == ElementType.table) {
      _recordHistory();
      elem.tableFontSize = size.clamp(9.0, 36.0);
      notifyListeners();
    }
  }

  void setTableHeaderColor(String id, int color) => updateTableHeaderColor(id, color);

  int _getNextZIndex() {
    if (currentSlide.elements.isEmpty) return 1;
    final maxZ = currentSlide.elements.map((e) => e.zIndex).fold(0, (max, z) => z > max ? z : max);
    return maxZ + 1;
  }

  // Modifying Elements
  void updateElementPosition(String id, double dx, double dy) {
    final elem = _findElement(id);
    if (elem != null) {
      elem.x = (elem.x + dx).clamp(-500.0, _presentation.canvasWidth + 200.0);
      elem.y = (elem.y + dy).clamp(-500.0, _presentation.canvasHeight + 200.0);
      notifyListeners();
    }
  }



  void setElementPosition(String id, double x, double y) {
    final elem = _findElement(id);
    if (elem != null) {
      elem.x = x;
      elem.y = y;
      notifyListeners();
    }
  }



  void updateElementSize(
    String id,
    double newWidth,
    double newHeight, {
    double? newX,
    double? newY,
  }) {
    final elem = _findElement(id);
    if (elem != null) {
      elem.width = newWidth.clamp(30.0, _presentation.canvasWidth * 2);
      elem.height = newHeight.clamp(30.0, _presentation.canvasHeight * 2);
      if (newX != null) elem.x = newX;
      if (newY != null) elem.y = newY;
      notifyListeners();
    }
  }



  void updateElementRotation(String id, double rotation) {
    final elem = _findElement(id);
    if (elem != null) {
      elem.rotation = rotation;
      notifyListeners();
    }
  }



  void updateElementOpacity(String id, double opacity) {
    _recordHistory();
    final elem = _findElement(id);
    if (elem != null) {
      elem.opacity = opacity.clamp(0.0, 1.0);
      notifyListeners();
    }
  }



  void updateElementText(String id, String text) {
    final elem = _findElement(id);
    if (elem != null && elem.type == ElementType.text) {
      elem.text = text;

      // Keep rich paragraphs and runs in full sync for real-time live preview
      final lines = text.split('\n');
      final updatedParagraphs = <TextParagraphSpan>[];

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (i < elem.paragraphs.length) {
          final existing = elem.paragraphs[i];
          existing.text = line;
          if (existing.runs.isNotEmpty) {
            existing.runs = [
              existing.runs.first.copyWith(text: line),
            ];
          } else {
            existing.runs = [
              TextRunSpan(
                text: line,
                fontSize: existing.fontSize,
                isBold: existing.isBold,
                isItalic: existing.isItalic,
                isUnderline: existing.isUnderline,
                textColor: existing.textColor,
              ),
            ];
          }
          updatedParagraphs.add(existing);
        } else {
          updatedParagraphs.add(
            TextParagraphSpan(
              text: line,
              fontSize: elem.fontSize,
              isBold: elem.isBold,
              isItalic: elem.isItalic,
              isUnderline: elem.isUnderline,
              textColor: elem.textColor,
              textAlign: elem.textAlign,
              runs: [
                TextRunSpan(
                  text: line,
                  fontSize: elem.fontSize,
                  isBold: elem.isBold,
                  isItalic: elem.isItalic,
                  isUnderline: elem.isUnderline,
                  textColor: elem.textColor,
                ),
              ],
            ),
          );
        }
      }
      elem.paragraphs = updatedParagraphs;
      notifyListeners();
    }
  }

  void updateElementTextStyle(
    String id, {
    double? fontSize,
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
    int? textColor,
    String? textAlign,
    int? backgroundColor,
  }) {
    _recordHistory();
    final elem = _findElement(id);
    if (elem != null && elem.type == ElementType.text) {
      if (fontSize != null) {
        elem.fontSize = fontSize;
        for (final p in elem.paragraphs) {
          p.fontSize = fontSize;
          for (final r in p.runs) {
            r.fontSize = fontSize;
          }
        }
      }
      if (isBold != null) {
        elem.isBold = isBold;
        for (final p in elem.paragraphs) {
          p.isBold = isBold;
          for (final r in p.runs) {
            r.isBold = isBold;
          }
        }
      }
      if (isItalic != null) {
        elem.isItalic = isItalic;
        for (final p in elem.paragraphs) {
          p.isItalic = isItalic;
          for (final r in p.runs) {
            r.isItalic = isItalic;
          }
        }
      }
      if (isUnderline != null) {
        elem.isUnderline = isUnderline;
        for (final p in elem.paragraphs) {
          p.isUnderline = isUnderline;
          for (final r in p.runs) {
            r.isUnderline = isUnderline;
          }
        }
      }
      if (textColor != null) {
        elem.textColor = textColor;
        for (final p in elem.paragraphs) {
          p.textColor = textColor;
          for (final r in p.runs) {
            r.textColor = textColor;
          }
        }
      }
      if (textAlign != null) {
        elem.textAlign = textAlign;
        for (final p in elem.paragraphs) {
          p.textAlign = textAlign;
        }
      }
      if (backgroundColor != null) elem.backgroundColor = backgroundColor;
      notifyListeners();
    }
  }

  void updateElementFontSize(String id, double size) => updateElementTextStyle(id, fontSize: size);

  void toggleElementBold(String id) {
    final elem = _findElement(id);
    if (elem != null) updateElementTextStyle(id, isBold: !elem.isBold);
  }

  void toggleElementItalic(String id) {
    final elem = _findElement(id);
    if (elem != null) updateElementTextStyle(id, isItalic: !elem.isItalic);
  }

  void toggleElementUnderline(String id) {
    final elem = _findElement(id);
    if (elem != null) updateElementTextStyle(id, isUnderline: !elem.isUnderline);
  }

  void updateElementTextAlign(String id, String align) => updateElementTextStyle(id, textAlign: align);

  void updateElementTextColor(String id, int color) => updateElementTextStyle(id, textColor: color);



  void updateElementShapeStyle(
    String id, {
    int? fillColor,
    int? strokeColor,
    double? strokeWidth,
    double? borderRadius,
  }) {
    _recordHistory();
    final elem = _findElement(id);
    if (elem != null && elem.type == ElementType.shape) {
      if (fillColor != null) elem.fillColor = fillColor;
      if (strokeColor != null) elem.strokeColor = strokeColor;
      if (strokeWidth != null) elem.strokeWidth = strokeWidth;
      if (borderRadius != null) elem.borderRadius = borderRadius;
      notifyListeners();
    }
  }



  void updateElementImageFit(String id, String fit) {
    _recordHistory();
    final elem = _findElement(id);
    if (elem != null && elem.type == ElementType.image) {
      elem.fit = fit;
      notifyListeners();
    }
  }



  void bringToFront(String id) {
    _recordHistory();
    final elem = _findElement(id);
    if (elem != null) {
      elem.zIndex = _getNextZIndex();
      _sortElementsByZIndex();
      notifyListeners();
    }
  }



  void sendToBack(String id) {
    _recordHistory();
    final elem = _findElement(id);
    if (elem != null) {
      final minZ = currentSlide.elements.map((e) => e.zIndex).fold(1, (min, z) => z < min ? z : min);
      elem.zIndex = minZ - 1;
      _sortElementsByZIndex();
      notifyListeners();
    }
  }



  void deleteElement(String id) {
    _recordHistory();
    currentSlide.elements.removeWhere((e) => e.id == id);
    if (_selectedElementId == id) {
      _selectedElementId = null;
      _editingTextElementId = null;
    }
    notifyListeners();
  }

  void duplicateElement(String id) {
    final elem = _findElement(id);
    if (elem != null) {
      _recordHistory();
      final duplicated = elem.copyWith(
        id: _uuid.v4(),
        x: elem.x + 40,
        y: elem.y + 40,
        zIndex: _getNextZIndex(),
      );
      currentSlide.elements.add(duplicated);
      _selectedElementId = duplicated.id;
      notifyListeners();
    }
  }



  void _sortElementsByZIndex() {
    currentSlide.elements.sort((a, b) => a.zIndex.compareTo(b.zIndex));
  }

  SlideElement? _findElement(String id) {
    try {
      return currentSlide.elements.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  // Whole Project Import/Export
  String exportToJson() {
    return const JsonEncoder.withIndent('  ').convert(_presentation.toJson());
  }

  void importFromJson(String jsonStr) {
    _recordHistory();
    _presentation = Presentation.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    _currentSlideIndex = 0;
    _selectedElementId = null;
    _editingTextElementId = null;
    notifyListeners();
  }

  void loadPresentation(Presentation pres) {
    _recordHistory();
    _presentation = pres;
    _currentSlideIndex = 0;
    _selectedElementId = null;
    _editingTextElementId = null;
    notifyListeners();
  }

  void newPresentation({String title = 'Untitled Presentation'}) {
    createFromTemplate('blank', customTitle: title);
  }

  void createFromTemplate(String templateKey, {String? customTitle}) {
    _recordHistory();
    final deckId = _uuid.v4();
    final effectiveTitle = customTitle ??
        (templateKey == 'avionti_pitch' || templateKey == 'avionti_orange'
            ? 'Avionti Pitch Deck'
            : templateKey == 'dark_modern'
                ? 'Modern Dark Deck'
                : templateKey == 'technical_matrix'
                    ? 'Technical Schedule & Matrix'
                    : 'Blank Presentation');

    final slides = <Slide>[];

    if (templateKey == 'avionti_pitch' || templateKey == 'avionti_orange') {
      // 1. Signature Executive Title Slide
      slides.add(Slide(
        id: _uuid.v4(),
        title: 'Title Slide',
        backgroundColor: 0xFFFFFFFF,
        elements: [
          SlideElement(
            id: _uuid.v4(),
            type: ElementType.text,
            x: 120,
            y: 300,
            width: 1680,
            height: 140,
            text: effectiveTitle,
            fontSize: 60,
            isBold: true,
            textColor: 0xFFC43E1C, // Avionti Orange
            textAlign: 'center',
            zIndex: 1,
          ),
          SlideElement(
            id: _uuid.v4(),
            type: ElementType.text,
            x: 120,
            y: 460,
            width: 1680,
            height: 80,
            text: 'High-Performance Presentation Studio Powered by Rust & Flutter',
            fontSize: 28,
            isItalic: true,
            textColor: 0xFF64748B,
            textAlign: 'center',
            zIndex: 2,
          ),
          SlideElement(
            id: _uuid.v4(),
            type: ElementType.shape,
            x: 860,
            y: 560,
            width: 200,
            height: 6,
            shapeType: 'rounded_rect',
            fillColor: 0xFFC43E1C,
            strokeColor: 0x00000000,
            zIndex: 3,
          ),
        ],
      ));

      // 2. Executive Overview & Architecture
      slides.add(Slide(
        id: _uuid.v4(),
        title: 'Executive Overview',
        backgroundColor: 0xFFFFFFFF,
        elements: [
          SlideElement(
            id: _uuid.v4(),
            type: ElementType.text,
            x: 120,
            y: 80,
            width: 1680,
            height: 80,
            text: 'Executive Overview & Architecture',
            fontSize: 44,
            isBold: true,
            textColor: 0xFFC43E1C,
            zIndex: 1,
          ),
          SlideElement(
            id: _uuid.v4(),
            type: ElementType.text,
            x: 120,
            y: 200,
            width: 1040,
            height: 750,
            text: '• Native Rust Presentation Engine (C-ABI FFI)\n  Sub-millisecond snap coordinates, search & deck serialization.\n\n• True Offline Studio Independence\n  No account logins, no cloud subscriptions, zero paywalls.\n\n• Complete OpenXML (.pptx) Fidelity\n  Preserves rich multi-line typography, table grids, images, shapes.\n\n• Unified Mobile & Desktop Responsive Workspace\n  Desktop multi-tab Office ribbon & touch-optimized mobile filmstrip.',
            fontSize: 28,
            textColor: 0xFF1E293B,
            zIndex: 2,
          ),
          SlideElement(
            id: _uuid.v4(),
            type: ElementType.shape,
            x: 1240,
            y: 220,
            width: 540,
            height: 480,
            shapeType: 'rounded_rect',
            fillColor: 0xFFC43E1C,
            strokeColor: 0xFF9C27B0,
            strokeWidth: 3,
            zIndex: 3,
          ),
        ],
      ));

      // 3. Technical Capabilities Matrix
      slides.add(Slide(
        id: _uuid.v4(),
        title: 'Capabilities Matrix',
        backgroundColor: 0xFFFFFFFF,
        elements: [
          SlideElement(
            id: _uuid.v4(),
            type: ElementType.text,
            x: 120,
            y: 80,
            width: 1680,
            height: 80,
            text: 'Technical Capabilities & Benchmark Matrix',
            fontSize: 40,
            isBold: true,
            textColor: 0xFF0F172A,
            zIndex: 1,
          ),
          SlideElement(
            id: _uuid.v4(),
            type: ElementType.table,
            x: 120,
            y: 190,
            width: 1680,
            height: 780,
            tableRows: 5,
            tableCols: 5,
            tableColWidths: [0.22, 0.26, 0.22, 0.18, 0.12],
            tableData: [
              ['Core Capability', 'Avionti / WPS Studio', 'Cloud Suites', 'Standard Viewers', 'Status'],
              ['Engine Architecture', 'Rust FFI Native Core', 'Cloud Server Sync', 'Dart VM Only', 'Optimal'],
              ['Offline Autonomy', '100% Offline & Private', 'Subscription Gated', 'Limited Offline', 'Verified'],
              ['PowerPoint (.pptx)', 'Bidirectional OpenXML', 'Proprietary Formats', 'Read Only', 'Complete'],
              ['Responsive Form Factors', 'Mobile & Desktop Studio', 'Fragmented Apps', 'Mobile Only', 'Active'],
            ],
            tableHeaderColor: 0xFFC43E1C, // Avionti Orange
            tableRowColor: 0xFFFFFFFF,
            tableAltRowColor: 0xFFFFF7ED,
            tableBorderColor: 0xFFCBD5E1,
            tableFontSize: 20,
            zIndex: 2,
          ),
        ],
      ));
    } else if (templateKey == 'dark_modern') {
      slides.add(Slide(
        id: _uuid.v4(),
        title: 'Title Slide',
        backgroundColor: 0xFF0F172A,
        elements: [
          SlideElement(
            id: _uuid.v4(),
            type: ElementType.text,
            x: 120,
            y: 320,
            width: 1680,
            height: 160,
            text: effectiveTitle,
            fontSize: 64,
            isBold: true,
            textColor: 0xFFF8FAFC,
            textAlign: 'center',
            zIndex: 1,
          ),
          SlideElement(
            id: _uuid.v4(),
            type: ElementType.text,
            x: 120,
            y: 500,
            width: 1680,
            height: 80,
            text: 'Modern High-Contrast Dark Deck with Native Vector Canvas',
            fontSize: 30,
            isItalic: true,
            textColor: 0xFF94A3B8,
            textAlign: 'center',
            zIndex: 2,
          ),
          SlideElement(
            id: _uuid.v4(),
            type: ElementType.shape,
            x: 840,
            y: 620,
            width: 240,
            height: 8,
            shapeType: 'rounded_rect',
            fillColor: 0xFF38BDF8,
            strokeColor: 0x00000000,
            zIndex: 3,
          ),
        ],
      ));
      slides.add(Slide(
        id: _uuid.v4(),
        title: 'Architecture Overview',
        backgroundColor: 0xFF0F172A,
        elements: [
          SlideElement(
            id: _uuid.v4(),
            type: ElementType.text,
            x: 120,
            y: 80,
            width: 1680,
            height: 90,
            text: 'High-Performance Rust Core Integration',
            fontSize: 44,
            isBold: true,
            textColor: 0xFF38BDF8,
            zIndex: 1,
          ),
          SlideElement(
            id: _uuid.v4(),
            type: ElementType.text,
            x: 120,
            y: 200,
            width: 1680,
            height: 750,
            text: '• Sub-millisecond geometric calculations\n• Real-time layout snapping with edge & center guides\n• Instant text metrics and lexical parsing\n• Hardware accelerated rendering with Impeller & Skia',
            fontSize: 30,
            textColor: 0xFFE2E8F0,
            zIndex: 2,
          ),
        ],
      ));
    } else if (templateKey == 'technical_matrix') {
      slides.add(Slide(
        id: _uuid.v4(),
        title: 'Title Slide',
        backgroundColor: 0xFF0F172A,
        elements: [
          SlideElement(
            id: _uuid.v4(),
            type: ElementType.text,
            x: 120,
            y: 340,
            width: 1680,
            height: 160,
            text: 'Damp-Proofing & Fireproofing Arrangements',
            fontSize: 54,
            isBold: true,
            textColor: 0xFFF8FAFC,
            textAlign: 'center',
            zIndex: 1,
          ),
          SlideElement(
            id: _uuid.v4(),
            type: ElementType.text,
            x: 120,
            y: 520,
            width: 1680,
            height: 80,
            text: 'Civil Engineering Standards • Technical Matrix & Construction Schedules',
            fontSize: 26,
            isItalic: true,
            textColor: 0xFF38BDF8,
            textAlign: 'center',
            zIndex: 2,
          ),
        ],
      ));
      slides.add(Slide(
        id: _uuid.v4(),
        title: 'Technical Schedule',
        backgroundColor: 0xFFFFFFFF,
        elements: [
          SlideElement(
            id: _uuid.v4(),
            type: ElementType.text,
            x: 120,
            y: 60,
            width: 1680,
            height: 60,
            text: 'PART A — TECHNICAL SCHEDULE & EDITABLE MATRIX',
            fontSize: 20,
            isBold: true,
            textColor: 0xFF0284C7,
            zIndex: 1,
          ),
          SlideElement(
            id: _uuid.v4(),
            type: ElementType.text,
            x: 120,
            y: 110,
            width: 1680,
            height: 70,
            text: 'Zone-Wise Residential Damp-Proofing Specifications',
            fontSize: 40,
            isBold: true,
            textColor: 0xFF0F172A,
            zIndex: 2,
          ),
          SlideElement(
            id: _uuid.v4(),
            type: ElementType.table,
            x: 120,
            y: 200,
            width: 1680,
            height: 780,
            tableRows: 6,
            tableCols: 5,
            tableColWidths: [0.18, 0.20, 0.24, 0.24, 0.14],
            tableData: [
              ['Residential Zone', 'Moisture Source', 'Treatment Arrangement', 'Key Specification', 'IS Code'],
              ['Plinth Level Wall', 'Capillary groundwater', 'PCC band + hot bitumen', '40 mm PCC (1:1.5:3) at +150 mm', 'IS 3067:1988'],
              ['Sunken Bathroom', 'Plumbing & splash water', '2-coat acrylic polymer slurry', '300 mm wall upturn + pipe collar', 'IS 3067:1988'],
              ['Flat Roof Terrace', 'Monsoon rain ponding', 'PU coating + brickbat coba', '1:60 slope + 75 mm corner fillet', 'IS 1346:1991'],
              ['External Facade', 'Wind-driven rain', '20 mm 2-coat sand-faced plaster', 'Hydrophobic admixture (2% wt)', 'IS 2645:2003'],
              ['Underground Sump', 'Hydrostatic pressure', 'Positive & negative tanking', 'Crystalline slurry + M25 RCC', 'IS 6494:1988'],
            ],
            tableHeaderColor: 0xFF1D4ED8,
            tableRowColor: 0xFFFFFFFF,
            tableAltRowColor: 0xFFF0F9FF,
            tableBorderColor: 0xFFCBD5E1,
            tableFontSize: 18,
            zIndex: 3,
          ),
        ],
      ));
    } else {
      // Clean Blank Presentation
      slides.add(Slide(
        id: _uuid.v4(),
        title: 'Slide 1',
        backgroundColor: 0xFFFFFFFF,
        elements: [
          SlideElement(
            id: _uuid.v4(),
            type: ElementType.text,
            x: 120,
            y: 360,
            width: 1680,
            height: 140,
            text: effectiveTitle,
            fontSize: 56,
            isBold: true,
            textColor: 0xFF0F172A,
            textAlign: 'center',
            zIndex: 1,
          ),
          SlideElement(
            id: _uuid.v4(),
            type: ElementType.text,
            x: 120,
            y: 520,
            width: 1680,
            height: 80,
            text: 'Double-tap to add subtitle',
            fontSize: 28,
            isItalic: true,
            textColor: 0xFF64748B,
            textAlign: 'center',
            zIndex: 2,
          ),
        ],
      ));
    }

    _presentation = Presentation(
      id: deckId,
      title: effectiveTitle,
      author: 'Avionti User',
      slides: slides,
    );
    _currentSlideIndex = 0;
    _selectedElementId = null;
    _editingTextElementId = null;
    notifyListeners();
  }

  void updateElementFormat(
    String id, {
    double? fontSize,
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
    int? textColor,
    String? textAlign,
    int? backgroundColor,
  }) =>
      updateElementTextStyle(
        id,
        fontSize: fontSize,
        isBold: isBold,
        isItalic: isItalic,
        isUnderline: isUnderline,
        textColor: textColor,
        textAlign: textAlign,
        backgroundColor: backgroundColor,
      );
}
