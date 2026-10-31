import 'package:flutter/material.dart';

enum ElementType { text, image, shape, table }

class TextRunSpan {
  String text;
  double fontSize;
  bool isBold;
  bool isItalic;
  bool isUnderline;
  int textColor;

  TextRunSpan({
    required this.text,
    this.fontSize = 28.0,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.textColor = 0xFF1E293B,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'fontSize': fontSize,
        'isBold': isBold,
        'isItalic': isItalic,
        'isUnderline': isUnderline,
        'textColor': textColor,
      };

  factory TextRunSpan.fromJson(Map<String, dynamic> json) => TextRunSpan(
        text: json['text'] as String? ?? '',
        fontSize: (json['fontSize'] as num?)?.toDouble() ?? 28.0,
        isBold: json['isBold'] as bool? ?? false,
        isItalic: json['isItalic'] as bool? ?? false,
        isUnderline: json['isUnderline'] as bool? ?? false,
        textColor: (json['textColor'] as num?)?.toInt() ?? 0xFF1E293B,
      );

  TextRunSpan copyWith({
    String? text,
    double? fontSize,
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
    int? textColor,
  }) =>
      TextRunSpan(
        text: text ?? this.text,
        fontSize: fontSize ?? this.fontSize,
        isBold: isBold ?? this.isBold,
        isItalic: isItalic ?? this.isItalic,
        isUnderline: isUnderline ?? this.isUnderline,
        textColor: textColor ?? this.textColor,
      );
}

class TextParagraphSpan {
  String text;
  double fontSize;
  bool isBold;
  bool isItalic;
  bool isUnderline;
  int textColor;
  String textAlign;
  double spaceAfter;
  List<TextRunSpan> runs;

  TextParagraphSpan({
    required this.text,
    this.fontSize = 28.0,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.textColor = 0xFF1E293B,
    this.textAlign = 'left',
    this.spaceAfter = 8.0,
    List<TextRunSpan>? runs,
  }) : runs = runs ?? [];

  Map<String, dynamic> toJson() => {
        'text': text,
        'fontSize': fontSize,
        'isBold': isBold,
        'isItalic': isItalic,
        'isUnderline': isUnderline,
        'textColor': textColor,
        'textAlign': textAlign,
        'spaceAfter': spaceAfter,
        'runs': runs.map((r) => r.toJson()).toList(),
      };

  factory TextParagraphSpan.fromJson(Map<String, dynamic> json) => TextParagraphSpan(
        text: json['text'] as String? ?? '',
        fontSize: (json['fontSize'] as num?)?.toDouble() ?? 28.0,
        isBold: json['isBold'] as bool? ?? false,
        isItalic: json['isItalic'] as bool? ?? false,
        isUnderline: json['isUnderline'] as bool? ?? false,
        textColor: (json['textColor'] as num?)?.toInt() ?? 0xFF1E293B,
        textAlign: json['textAlign'] as String? ?? 'left',
        spaceAfter: (json['spaceAfter'] as num?)?.toDouble() ?? 8.0,
        runs: (json['runs'] as List<dynamic>?)
                ?.map((r) => TextRunSpan.fromJson(r as Map<String, dynamic>))
                .toList() ??
            [],
      );

  TextParagraphSpan copyWith({
    String? text,
    double? fontSize,
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
    int? textColor,
    String? textAlign,
    double? spaceAfter,
    List<TextRunSpan>? runs,
  }) =>
      TextParagraphSpan(
        text: text ?? this.text,
        fontSize: fontSize ?? this.fontSize,
        isBold: isBold ?? this.isBold,
        isItalic: isItalic ?? this.isItalic,
        isUnderline: isUnderline ?? this.isUnderline,
        textColor: textColor ?? this.textColor,
        textAlign: textAlign ?? this.textAlign,
        spaceAfter: spaceAfter ?? this.spaceAfter,
        runs: runs ?? this.runs,
      );
}

class SlideElement {
  final String id;
  final ElementType type;
  double x;
  double y;
  double width;
  double height;
  double rotation; // in radians
  double opacity;
  int zIndex;

  // Text specific
  String text;
  double fontSize;
  String fontFamily;
  bool isBold;
  bool isItalic;
  bool isUnderline;
  int textColor;
  String textAlign; // 'left', 'center', 'right'
  int? backgroundColor;
  int? borderColor;
  double borderWidth;
  List<TextParagraphSpan> paragraphs;

  // Image specific
  String? imagePath;
  String? imageBase64;
  String fit; // 'contain', 'cover', 'fill'
  double borderRadius;

  // Shape specific
  String shapeType; // 'rectangle', 'circle', 'rounded_rect', 'triangle', 'arrow', 'star', 'hexagon'
  int fillColor;
  int strokeColor;
  double strokeWidth;

  // Table specific
  int tableRows;
  int tableCols;
  List<List<String>> tableData;
  List<double> tableColWidths; // Fractional widths (e.g. 0.2, 0.3...)
  List<List<int>>? tableCellColors;
  List<List<int>>? tableCellTextColors;
  List<List<bool>>? tableCellBolds;
  int tableHeaderColor;
  int tableRowColor;
  int tableAltRowColor;
  int tableBorderColor;
  double tableFontSize;
  bool tableHasHeader;

  SlideElement({
    required this.id,
    required this.type,
    this.x = 100,
    this.y = 100,
    this.width = 300,
    this.height = 150,
    this.rotation = 0.0,
    this.opacity = 1.0,
    this.zIndex = 0,
    // Text defaults
    this.text = 'Double tap to edit text',
    this.fontSize = 32.0,
    this.fontFamily = 'Inter',
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.textColor = 0xFF1E293B, // slate-800
    this.textAlign = 'left',
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0.0,
    List<TextParagraphSpan>? paragraphs,
    // Image defaults
    this.imagePath,
    this.imageBase64,
    this.fit = 'contain',
    this.borderRadius = 8.0,
    // Shape defaults
    this.shapeType = 'rectangle',
    this.fillColor = 0xFF3B82F6, // blue-500
    this.strokeColor = 0xFF1D4ED8, // blue-700
    this.strokeWidth = 2.0,
    // Table defaults
    this.tableRows = 3,
    this.tableCols = 3,
    List<List<String>>? tableData,
    List<double>? tableColWidths,
    this.tableCellColors,
    this.tableCellTextColors,
    this.tableCellBolds,
    this.tableHeaderColor = 0xFF1D4ED8, // Royal Blue
    this.tableRowColor = 0xFFFFFFFF,    // Clean white
    this.tableAltRowColor = 0xFFF0F7FF, // Subtle light blue
    this.tableBorderColor = 0xFFCBD5E1, // Light slate border
    this.tableFontSize = 18.0,
    this.tableHasHeader = true,
  })  : paragraphs = paragraphs ?? [],
        tableData = tableData ??
            [
              ['Header 1', 'Header 2', 'Header 3'],
              ['Row 1, Col 1', 'Row 1, Col 2', 'Row 1, Col 3'],
              ['Row 2, Col 1', 'Row 2, Col 2', 'Row 2, Col 3'],
            ],
        tableColWidths = tableColWidths ?? [1.0, 1.0, 1.0];

  SlideElement copyWith({
    String? id,
    ElementType? type,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    double? opacity,
    int? zIndex,
    String? text,
    double? fontSize,
    String? fontFamily,
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
    int? textColor,
    String? textAlign,
    int? backgroundColor,
    int? borderColor,
    double? borderWidth,
    List<TextParagraphSpan>? paragraphs,
    String? imagePath,
    String? imageBase64,
    String? fit,
    double? borderRadius,
    String? shapeType,
    int? fillColor,
    int? strokeColor,
    double? strokeWidth,
    int? tableRows,
    int? tableCols,
    List<List<String>>? tableData,
    List<double>? tableColWidths,
    List<List<int>>? tableCellColors,
    List<List<int>>? tableCellTextColors,
    List<List<bool>>? tableCellBolds,
    int? tableHeaderColor,
    int? tableRowColor,
    int? tableAltRowColor,
    int? tableBorderColor,
    double? tableFontSize,
    bool? tableHasHeader,
  }) {
    return SlideElement(
      id: id ?? this.id,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      opacity: opacity ?? this.opacity,
      zIndex: zIndex ?? this.zIndex,
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      isUnderline: isUnderline ?? this.isUnderline,
      textColor: textColor ?? this.textColor,
      textAlign: textAlign ?? this.textAlign,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      paragraphs: paragraphs ?? this.paragraphs.map((p) => p.copyWith()).toList(),
      imagePath: imagePath ?? this.imagePath,
      imageBase64: imageBase64 ?? this.imageBase64,
      fit: fit ?? this.fit,
      borderRadius: borderRadius ?? this.borderRadius,
      shapeType: shapeType ?? this.shapeType,
      fillColor: fillColor ?? this.fillColor,
      strokeColor: strokeColor ?? this.strokeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      tableRows: tableRows ?? this.tableRows,
      tableCols: tableCols ?? this.tableCols,
      tableData: tableData ?? this.tableData.map((r) => List<String>.from(r)).toList(),
      tableColWidths: tableColWidths ?? List<double>.from(this.tableColWidths),
      tableCellColors: tableCellColors ?? this.tableCellColors,
      tableCellTextColors: tableCellTextColors ?? this.tableCellTextColors,
      tableCellBolds: tableCellBolds ?? this.tableCellBolds,
      tableHeaderColor: tableHeaderColor ?? this.tableHeaderColor,
      tableRowColor: tableRowColor ?? this.tableRowColor,
      tableAltRowColor: tableAltRowColor ?? this.tableAltRowColor,
      tableBorderColor: tableBorderColor ?? this.tableBorderColor,
      tableFontSize: tableFontSize ?? this.tableFontSize,
      tableHasHeader: tableHasHeader ?? this.tableHasHeader,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'rotation': rotation,
      'opacity': opacity,
      'zIndex': zIndex,
      'text': text,
      'fontSize': fontSize,
      'fontFamily': fontFamily,
      'isBold': isBold,
      'isItalic': isItalic,
      'isUnderline': isUnderline,
      'textColor': textColor,
      'textAlign': textAlign,
      'backgroundColor': backgroundColor,
      'borderColor': borderColor,
      'borderWidth': borderWidth,
      'paragraphs': paragraphs.map((p) => p.toJson()).toList(),
      'imagePath': imagePath,
      'imageBase64': imageBase64,
      'fit': fit,
      'borderRadius': borderRadius,
      'shapeType': shapeType,
      'fillColor': fillColor,
      'strokeColor': strokeColor,
      'strokeWidth': strokeWidth,
      'tableRows': tableRows,
      'tableCols': tableCols,
      'tableData': tableData,
      'tableColWidths': tableColWidths,
      'tableHeaderColor': tableHeaderColor,
      'tableRowColor': tableRowColor,
      'tableAltRowColor': tableAltRowColor,
      'tableBorderColor': tableBorderColor,
      'tableFontSize': tableFontSize,
      'tableHasHeader': tableHasHeader,
    };
  }

  factory SlideElement.fromJson(Map<String, dynamic> json) {
    List<List<String>> parsedTable = [];
    if (json['tableData'] != null) {
      parsedTable = (json['tableData'] as List<dynamic>)
          .map((row) => (row as List<dynamic>).map((cell) => cell.toString()).toList())
          .toList();
    }

    List<double> parsedColWidths = [];
    if (json['tableColWidths'] != null) {
      parsedColWidths = (json['tableColWidths'] as List<dynamic>)
          .map((w) => (w as num).toDouble())
          .toList();
    }

    List<TextParagraphSpan> parsedParagraphs = [];
    if (json['paragraphs'] != null) {
      parsedParagraphs = (json['paragraphs'] as List<dynamic>)
          .map((p) => TextParagraphSpan.fromJson(p as Map<String, dynamic>))
          .toList();
    }

    return SlideElement(
      id: json['id'] as String,
      type: ElementType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ElementType.text,
      ),
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      zIndex: (json['zIndex'] as num?)?.toInt() ?? 0,
      text: json['text'] as String? ?? '',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 32.0,
      fontFamily: json['fontFamily'] as String? ?? 'Inter',
      isBold: json['isBold'] as bool? ?? false,
      isItalic: json['isItalic'] as bool? ?? false,
      isUnderline: json['isUnderline'] as bool? ?? false,
      textColor: (json['textColor'] as num?)?.toInt() ?? 0xFF1E293B,
      textAlign: json['textAlign'] as String? ?? 'left',
      backgroundColor: (json['backgroundColor'] as num?)?.toInt(),
      borderColor: (json['borderColor'] as num?)?.toInt(),
      borderWidth: (json['borderWidth'] as num?)?.toDouble() ?? 0.0,
      paragraphs: parsedParagraphs,
      imagePath: json['imagePath'] as String?,
      imageBase64: json['imageBase64'] as String?,
      fit: json['fit'] as String? ?? 'contain',
      borderRadius: (json['borderRadius'] as num?)?.toDouble() ?? 8.0,
      shapeType: json['shapeType'] as String? ?? 'rectangle',
      fillColor: (json['fillColor'] as num?)?.toInt() ?? 0xFF3B82F6,
      strokeColor: (json['strokeColor'] as num?)?.toInt() ?? 0xFF1D4ED8,
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 2.0,
      tableRows: (json['tableRows'] as num?)?.toInt() ?? 3,
      tableCols: (json['tableCols'] as num?)?.toInt() ?? 3,
      tableData: parsedTable.isNotEmpty ? parsedTable : null,
      tableColWidths: parsedColWidths.isNotEmpty ? parsedColWidths : null,
      tableHeaderColor: (json['tableHeaderColor'] as num?)?.toInt() ?? 0xFF1D4ED8,
      tableRowColor: (json['tableRowColor'] as num?)?.toInt() ?? 0xFFFFFFFF,
      tableAltRowColor: (json['tableAltRowColor'] as num?)?.toInt() ?? 0xFFF0F7FF,
      tableBorderColor: (json['tableBorderColor'] as num?)?.toInt() ?? 0xFFCBD5E1,
      tableFontSize: (json['tableFontSize'] as num?)?.toDouble() ?? 18.0,
      tableHasHeader: json['tableHasHeader'] as bool? ?? true,
    );
  }

  TextAlign get dartTextAlign {
    switch (textAlign) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'justify':
        return TextAlign.justify;
      default:
        return TextAlign.left;
    }
  }

  BoxFit get dartBoxFit {
    switch (fit) {
      case 'cover':
        return BoxFit.cover;
      case 'fill':
        return BoxFit.fill;
      default:
        return BoxFit.contain;
    }
  }
}
