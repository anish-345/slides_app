import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart';
import '../models/presentation.dart';
import '../models/slide.dart';
import '../models/slide_element.dart';

class PptxService {
  static const double _emuScale = 6350.0; // 12,192,000 EMUs / 1920 px ≈ 6350

  /// Imports an existing .pptx file and converts it into a high-fidelity Presentation
  static Presentation importPptx(Uint8List fileBytes, {String title = 'Imported Presentation'}) {
    const uuid = Uuid();
    final archive = ZipDecoder().decodeBytes(fileBytes);
    final archiveMap = <String, ArchiveFile>{};
    for (final file in archive.files) {
      final path = file.name.replaceAll('\\', '/');
      archiveMap[path] = file;
      archiveMap[path.toLowerCase()] = file;
    }

    // 1. Discover all slides
    final slideFiles = archiveMap.keys
        .where((k) => k.startsWith('ppt/slides/slide') && k.endsWith('.xml') && !k.contains('_rels'))
        .toSet()
        .toList();

    slideFiles.sort((a, b) {
      final numA = _extractSlideNumber(a);
      final numB = _extractSlideNumber(b);
      return numA.compareTo(numB);
    });

    final List<Slide> importedSlides = [];

    for (int i = 0; i < slideFiles.length; i++) {
      final slidePath = slideFiles[i];
      final slideXmlFile = archiveMap[slidePath];
      if (slideXmlFile == null) continue;

      final slideXmlStr = utf8.decode(slideXmlFile.content as List<int>);
      final slideDoc = XmlDocument.parse(slideXmlStr);

      // Load relationships for images & layouts
      final relsPath = _getSlideRelsPath(slidePath);
      final Map<String, String> rels = {};
      if (archiveMap.containsKey(relsPath)) {
        final relsXml = utf8.decode(archiveMap[relsPath]!.content as List<int>);
        final relsDoc = XmlDocument.parse(relsXml);
        for (final elem in relsDoc.findAllElements('Relationship')) {
          final id = _getAttr(elem, 'Id');
          final target = _getAttr(elem, 'Target');
          if (id != null && target != null) {
            var normalizedTarget = target.replaceAll('\\', '/');
            if (normalizedTarget.startsWith('../')) {
              normalizedTarget = 'ppt/${normalizedTarget.substring(3)}';
            } else if (!normalizedTarget.startsWith('ppt/')) {
              normalizedTarget = 'ppt/slides/$normalizedTarget';
            }
            rels[id] = normalizedTarget;
          }
        }
      }

      int slideBgColor = 0xFFFFFFFF; // Default white

      // 1. Check explicit slide background: <p:bg><p:bgPr><a:solidFill>... or <p:bgRef>
      for (final bg in slideDoc.findAllElements('p:bg')) {
        final solidFill = bg.findAllElements('a:solidFill').firstOrNull;
        if (solidFill != null) {
          slideBgColor = _resolveColor(solidFill, defaultColor: slideBgColor);
        } else {
          final srgb = bg.findAllElements('a:srgbClr').firstOrNull;
          if (srgb != null) {
            final hex = _getAttr(srgb, 'val');
            if (hex != null && hex.length == 6) {
              slideBgColor = int.parse('FF$hex', radix: 16);
            }
          }
          final scheme = bg.findAllElements('a:schemeClr').firstOrNull;
          if (scheme != null) {
            slideBgColor = _resolveColor(bg.findAllElements('a:solidFill').firstOrNull ?? bg, defaultColor: 0xFF102C57);
          }
        }
      }

      // Check slide layout for background if slide background is still default white
      if (slideBgColor == 0xFFFFFFFF) {
        for (final target in rels.values) {
          if (target.contains('slideLayout') && (archiveMap.containsKey(target) || archiveMap.containsKey(target.toLowerCase()))) {
            final layoutFile = archiveMap[target] ?? archiveMap[target.toLowerCase()];
            if (layoutFile != null) {
              final layoutXml = utf8.decode(layoutFile.content as List<int>);
              final layoutDoc = XmlDocument.parse(layoutXml);
              final layoutBg = layoutDoc.findAllElements('p:bg').firstOrNull;
              if (layoutBg != null) {
                final solidFill = layoutBg.findAllElements('a:solidFill').firstOrNull;
                if (solidFill != null) {
                  slideBgColor = _resolveColor(solidFill, defaultColor: 0xFFFFFFFF);
                }
              }
            }
            break;
          }
        }
      }

      final List<SlideElement> elements = [];
      int zIndexCounter = 1;

      // 2. Parse Shapes & Full-bleed backgrounds (<p:sp>)
      for (final sp in slideDoc.findAllElements('p:sp')) {
        final bounds = _extractBounds(sp);

        // Check if this shape is a full-bleed background slide fill (e.g. 1920x1080 at 0,0)
        final solidFill = sp.findAllElements('a:solidFill').firstOrNull;
        int? shapeFillColor;
        if (solidFill != null) {
          shapeFillColor = _resolveColor(solidFill, defaultColor: 0xFFCBD5E1);
        }

        final textBody = sp.findAllElements('p:txBody').firstOrNull;
        final hasText = textBody != null && textBody.findAllElements('a:t').any((t) => t.innerText.trim().isNotEmpty);

        if (!hasText && bounds.x <= 20 && bounds.y <= 20 && bounds.width >= 1880 && bounds.height >= 1040) {
          if (shapeFillColor != null) {
            slideBgColor = shapeFillColor;
          }
          continue; // Handled as slide background!
        }

        if (textBody != null && hasText) {
          final List<TextParagraphSpan> paragraphs = [];
          final fullBuffer = StringBuffer();
          double maxFontSize = 24.0;
          int firstTextColor = 0xFF1E293B;

          for (final p in textBody.findAllElements('a:p')) {
            final pPr = p.findAllElements('a:pPr').firstOrNull;
            String textAlign = 'left';
            if (pPr != null) {
              final aln = _getAttr(pPr, 'algn');
              if (aln == 'ctr') textAlign = 'center';
              if (aln == 'r') textAlign = 'right';
            }

            final List<TextRunSpan> runs = [];
            final pTextBuffer = StringBuffer();
            double pFontSize = 24.0;
            bool pIsBold = false;
            bool pIsItalic = false;
            int pTextColor = 0xFF1E293B;

            for (final r in p.findAllElements('a:r')) {
              final t = r.findAllElements('a:t').firstOrNull?.innerText ?? '';
              if (t.isEmpty) continue;

              pTextBuffer.write(t);
              fullBuffer.write(t);

              double rFontSize = 24.0;
              bool rIsBold = false;
              bool rIsItalic = false;
              bool rIsUnderline = false;
              int rTextColor = 0xFF1E293B;

              final rPr = r.findAllElements('a:rPr').firstOrNull;
              if (rPr != null) {
                final szAttr = _getAttr(rPr, 'sz');
                if (szAttr != null) {
                  final pt = (double.tryParse(szAttr) ?? 1200) / 100.0;
                  rFontSize = (pt * 2.1).clamp(10.0, 120.0);
                  if (rFontSize > pFontSize) pFontSize = rFontSize;
                  if (rFontSize > maxFontSize) maxFontSize = rFontSize;
                }
                if (_getAttr(rPr, 'b') == '1') {
                  rIsBold = true;
                  pIsBold = true;
                }
                if (_getAttr(rPr, 'i') == '1') {
                  rIsItalic = true;
                  pIsItalic = true;
                }
                if (_getAttr(rPr, 'u') != null && _getAttr(rPr, 'u') != 'none') {
                  rIsUnderline = true;
                }

                final rSolidFill = rPr.findAllElements('a:solidFill').firstOrNull;
                rTextColor = _resolveColor(rSolidFill, defaultColor: 0xFF1E293B, isDarkBg: slideBgColor < 0xFF888888);
                pTextColor = rTextColor;
              }

              runs.add(TextRunSpan(
                text: t,
                fontSize: rFontSize,
                isBold: rIsBold,
                isItalic: rIsItalic,
                isUnderline: rIsUnderline,
                textColor: rTextColor,
              ));
            }
            fullBuffer.writeln();

            final pText = pTextBuffer.toString().trim();
            if (pText.isNotEmpty) {
              paragraphs.add(TextParagraphSpan(
                text: pText,
                fontSize: pFontSize.clamp(12.0, 96.0),
                isBold: pIsBold,
                isItalic: pIsItalic,
                textColor: pTextColor,
                textAlign: textAlign,
                runs: runs,
              ));
              if (paragraphs.length == 1) {
                firstTextColor = pTextColor;
              }
            }
          }

          final rawText = fullBuffer.toString().trim();
          if (rawText.isNotEmpty) {
            elements.add(SlideElement(
              id: uuid.v4(),
              type: ElementType.text,
              x: bounds.x,
              y: bounds.y,
              width: bounds.width > 50 ? bounds.width : 500,
              height: bounds.height > 30 ? bounds.height : 120,
              text: rawText,
              fontSize: maxFontSize.clamp(14.0, 72.0),
              textColor: firstTextColor,
              paragraphs: paragraphs,
              zIndex: zIndexCounter++,
            ));
            continue;
          }
        }

        // Geometric shape with dimensions - only create if it has explicit bounds and explicit fill
        if (bounds.hasExplicitBounds && bounds.width > 20 && bounds.height > 20 && shapeFillColor != null) {
          final prstGeom = sp.findAllElements('a:prstGeom').firstOrNull;
          final prst = prstGeom != null ? _getAttr(prstGeom, 'prst') : 'rect';
          String shapeType = 'rectangle';
          if (prst == 'ellipse') shapeType = 'circle';
          if (prst == 'roundRect') shapeType = 'rounded_rect';
          if (prst == 'triangle') shapeType = 'triangle';

          elements.add(SlideElement(
            id: uuid.v4(),
            type: ElementType.shape,
            x: bounds.x,
            y: bounds.y,
            width: bounds.width,
            height: bounds.height,
            shapeType: shapeType,
            fillColor: shapeFillColor,
            strokeColor: 0xFF64748B,
            strokeWidth: 1.5,
            zIndex: zIndexCounter++,
          ));
        }
      }

      // 3. Parse Pictures (<p:pic>) & Shapes with image fills (<p:sp> with <a:blipFill>)
      final pictureElements = <XmlElement>[];
      pictureElements.addAll(slideDoc.findAllElements('p:pic'));
      for (final sp in slideDoc.findAllElements('p:sp')) {
        if (sp.findAllElements('a:blipFill').isNotEmpty) {
          pictureElements.add(sp);
        }
      }

      for (final pic in pictureElements) {
        final blip = pic.findAllElements('a:blip').firstOrNull;
        if (blip != null) {
          final embedId = _getAttr(blip, 'embed') ?? _getAttr(blip, 'link');
          if (embedId != null && rels.containsKey(embedId)) {
            final imageFilePath = rels[embedId]!;
            ArchiveFile? imageArchiveFile = archiveMap[imageFilePath] ?? archiveMap[imageFilePath.toLowerCase()];
            if (imageArchiveFile == null) {
              final fn = imageFilePath.split('/').last.toLowerCase();
              for (final k in archiveMap.keys) {
                if (k.toLowerCase().endsWith('/$fn') || k.toLowerCase() == 'ppt/media/$fn') {
                  imageArchiveFile = archiveMap[k];
                  break;
                }
              }
            }
            if (imageArchiveFile != null) {
              final imgBytes = Uint8List.fromList(imageArchiveFile.content as List<int>);
              final base64Img = base64Encode(imgBytes);
              final bounds = _extractBounds(pic);

              elements.add(SlideElement(
                id: uuid.v4(),
                type: ElementType.image,
                x: bounds.x,
                y: bounds.y,
                width: bounds.width > 20 ? bounds.width : 500,
                height: bounds.height > 20 ? bounds.height : 400,
                imageBase64: base64Img,
                fit: 'cover',
                zIndex: zIndexCounter++,
              ));
            }
          }
        }
      }

      // 4. Parse Tables (<p:graphicFrame> containing <a:tbl>)
      for (final gf in slideDoc.findAllElements('p:graphicFrame')) {
        final tbl = gf.findAllElements('a:tbl').firstOrNull;
        if (tbl != null) {
          final bounds = _extractBounds(gf);

          // Extract column grid widths
          final List<double> colFractions = [];
          final gridCols = tbl.findAllElements('a:gridCol').toList();
          double totalEmuW = 0.0;
          for (final gc in gridCols) {
            final wAttr = _getAttr(gc, 'w');
            final wEmu = double.tryParse(wAttr ?? '0') ?? 1000000.0;
            colFractions.add(wEmu);
            totalEmuW += wEmu;
          }
          if (totalEmuW > 0) {
            for (int k = 0; k < colFractions.length; k++) {
              colFractions[k] = colFractions[k] / totalEmuW;
            }
          }

          final List<List<String>> tableData = [];
          int headerColor = 0xFF1D4ED8; // Royal blue default

          final rows = tbl.findAllElements('a:tr').toList();
          for (int r = 0; r < rows.length; r++) {
            final tr = rows[r];
            final List<String> rowCells = [];
            final cells = tr.findAllElements('a:tc').toList();

            for (int c = 0; c < cells.length; c++) {
              final tc = cells[c];
              final textBuffer = StringBuffer();
              for (final p in tc.findAllElements('a:p')) {
                for (final rr in p.findAllElements('a:r')) {
                  final t = rr.findAllElements('a:t').firstOrNull?.innerText ?? '';
                  textBuffer.write(t);
                }
              }

              // Extract header cell background color from first row
              if (r == 0) {
                final tcPr = tc.findAllElements('a:tcPr').firstOrNull;
                final srgb = tcPr?.findAllElements('a:srgbClr').firstOrNull;
                if (srgb != null) {
                  final hex = _getAttr(srgb, 'val');
                  if (hex != null && hex.length == 6) {
                    headerColor = int.parse('FF$hex', radix: 16);
                  }
                }
              }

              rowCells.add(textBuffer.toString().trim());
            }
            if (rowCells.isNotEmpty) {
              tableData.add(rowCells);
            }
          }

          if (tableData.isNotEmpty) {
            elements.add(SlideElement(
              id: uuid.v4(),
              type: ElementType.table,
              x: bounds.x,
              y: bounds.y,
              width: bounds.width > 200 ? bounds.width : 1200,
              height: bounds.height > 100 ? bounds.height : 500,
              tableRows: tableData.length,
              tableCols: tableData.first.length,
              tableData: tableData,
              tableColWidths: colFractions.isNotEmpty ? colFractions : null,
              tableHeaderColor: headerColor,
              tableRowColor: 0xFFFFFFFF,
              tableAltRowColor: 0xFFF0F7FF,
              tableBorderColor: 0xFFCBD5E1,
              tableFontSize: 16.0,
              zIndex: zIndexCounter++,
            ));
          }
        }
      }

      _resolveLayoutCollisions(elements);

      importedSlides.add(Slide(
        id: uuid.v4(),
        title: 'Slide ${i + 1}',
        backgroundColor: slideBgColor,
        elements: elements,
      ));
    }

    if (importedSlides.isEmpty) {
      importedSlides.add(Slide(id: uuid.v4(), title: 'Slide 1'));
    }

    return Presentation(
      id: uuid.v4(),
      title: title,
      slides: importedSlides,
    );
  }

  /// Exports current Presentation into a standard .pptx ZIP archive
  static Uint8List exportPptx(Presentation presentation) {
    final archive = Archive();

    // 1. [Content_Types].xml
    final contentTypesXml = _buildContentTypesXml(presentation.slides.length);
    archive.addFile(ArchiveFile('[Content_Types].xml', contentTypesXml.length, utf8.encode(contentTypesXml)));

    // 2. _rels/.rels
    final rootRelsXml = _buildRootRelsXml();
    archive.addFile(ArchiveFile('_rels/.rels', rootRelsXml.length, utf8.encode(rootRelsXml)));

    // 3. ppt/presentation.xml
    final presXml = _buildPresentationXml(presentation.slides.length);
    archive.addFile(ArchiveFile('ppt/presentation.xml', presXml.length, utf8.encode(presXml)));

    // 4. ppt/_rels/presentation.xml.rels
    final presRelsXml = _buildPresentationRelsXml(presentation.slides.length);
    archive.addFile(ArchiveFile('ppt/_rels/presentation.xml.rels', presRelsXml.length, utf8.encode(presRelsXml)));

    // 5. Build each slide XML & Relationships
    int mediaCounter = 1;
    for (int i = 0; i < presentation.slides.length; i++) {
      final slide = presentation.slides[i];
      final slideIndex = i + 1;
      final slideRels = <String, String>{};

      final slideXml = _buildSlideXml(slide, slideRels, mediaCounter, archive);
      archive.addFile(ArchiveFile('ppt/slides/slide$slideIndex.xml', slideXml.length, utf8.encode(slideXml)));

      final slideRelsXml = _buildSlideRelsXml(slideRels);
      archive.addFile(ArchiveFile('ppt/slides/_rels/slide$slideIndex.xml.rels', slideRelsXml.length, utf8.encode(slideRelsXml)));

      mediaCounter += slideRels.length;
    }

    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  // --- Helpers for parsing ---

  static String? _getAttr(XmlElement elem, String localName) {
    for (final a in elem.attributes) {
      if (a.name.local.toLowerCase() == localName.toLowerCase()) {
        return a.value;
      }
    }
    return null;
  }

  static int _extractSlideNumber(String path) {
    final match = RegExp(r'slide(\d+)\.xml').firstMatch(path);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 0;
    }
    return 0;
  }

  static String _getSlideRelsPath(String slidePath) {
    final parts = slidePath.split('/');
    final filename = parts.last;
    return 'ppt/slides/_rels/$filename.rels';
  }

  static int _resolveColor(XmlElement? solidFill, {int defaultColor = 0xFF1E293B, bool isDarkBg = false}) {
    if (solidFill == null) return defaultColor;

    final srgb = solidFill.findAllElements('a:srgbClr').firstOrNull;
    if (srgb != null) {
      final hex = _getAttr(srgb, 'val');
      if (hex != null && hex.length == 6) {
        return int.parse('FF$hex', radix: 16);
      }
    }

    final scheme = solidFill.findAllElements('a:schemeClr').firstOrNull;
    if (scheme != null) {
      final val = _getAttr(scheme, 'val')?.toLowerCase();
      switch (val) {
        case 'accent1':
          return 0xFF1E56A0; // SIH / PowerPoint Royal Blue
        case 'accent2':
          return 0xFFEA580C; // Vibrant Orange
        case 'accent3':
          return 0xFF10B981; // Green
        case 'accent4':
          return 0xFF8B5CF6; // Purple
        case 'accent5':
          return 0xFF06B6D4; // Cyan
        case 'accent6':
          return 0xFFF59E0B; // Amber
        case 'tx1':
        case 'dk1':
          return isDarkBg ? 0xFFFFFFFF : 0xFF102C57;
        case 'tx2':
        case 'dk2':
          return isDarkBg ? 0xFFCBD5E1 : 0xFF283241;
        case 'bg1':
        case 'lt1':
          return 0xFFFFFFFF;
        case 'bg2':
        case 'lt2':
          return 0xFFF1F5F9;
        case 'hlink':
          return 0xFF2563EB;
      }
    }

    final prst = solidFill.findAllElements('a:prstClr').firstOrNull;
    if (prst != null) {
      final val = _getAttr(prst, 'val')?.toLowerCase();
      if (val == 'white') return 0xFFFFFFFF;
      if (val == 'black') return 0xFF000000;
    }

    return defaultColor;
  }

  static ({double x, double y, double width, double height, bool hasExplicitBounds}) _extractBounds(XmlElement parent) {
    final xfrm = parent.findAllElements('a:xfrm').firstOrNull;
    final searchRoot = xfrm ?? parent;

    final off = searchRoot.findAllElements('a:off').firstOrNull;
    XmlElement? ext;
    for (final e in searchRoot.findAllElements('a:ext')) {
      if (_getAttr(e, 'cx') != null) {
        ext = e;
        break;
      }
    }
    ext ??= searchRoot.findAllElements('a:ext').firstOrNull;

    final offXStr = off != null ? _getAttr(off, 'x') : null;
    final offYStr = off != null ? _getAttr(off, 'y') : null;
    final cxStr = ext != null ? _getAttr(ext, 'cx') : null;
    final cyStr = ext != null ? _getAttr(ext, 'cy') : null;

    final hasExplicitBounds = (offXStr != null || offYStr != null) && (cxStr != null || cyStr != null);

    final isTitlePlaceholder = parent.findAllElements('p:ph').any((ph) {
      final t = _getAttr(ph, 'type')?.toLowerCase();
      return t == 'title' || t == 'ctrtitle';
    });

    double rawX = double.tryParse(offXStr ?? '0') ?? 0.0;
    double rawY = double.tryParse(offYStr ?? '0') ?? 0.0;
    double rawCx = double.tryParse(cxStr ?? '') ?? (parent.name.local == 'sp' ? (isTitlePlaceholder ? 1400.0 * _emuScale : 400.0 * _emuScale) : 500.0 * _emuScale);
    double rawCy = double.tryParse(cyStr ?? '') ?? (parent.name.local == 'sp' ? (isTitlePlaceholder ? 100.0 * _emuScale : 120.0 * _emuScale) : 400.0 * _emuScale);

    if (isTitlePlaceholder && !hasExplicitBounds) {
      rawX = 260.0 * _emuScale;
      rawY = 40.0 * _emuScale;
    }

    return (
      x: (rawX / _emuScale).clamp(0.0, 1920.0),
      y: (rawY / _emuScale).clamp(0.0, 1080.0),
      width: (rawCx / _emuScale).clamp(20.0, 1920.0),
      height: (rawCy / _emuScale).clamp(20.0, 1080.0),
      hasExplicitBounds: hasExplicitBounds,
    );
  }

  static void _resolveLayoutCollisions(List<SlideElement> elements) {
    SlideElement? topLeftBadge;
    for (final el in elements) {
      if (el.x < 350 && el.y < 200 && el.width < 400 && el.height < 250) {
        final t = el.text.toLowerCase();
        if (t.contains('team') || t.contains('logo') || t.contains('name') || el.shapeType == 'circle') {
          topLeftBadge = el;
          break;
        }
      }
    }

    if (topLeftBadge != null) {
      // Remove any opaque background so it never obscures underlying or adjacent title text
      topLeftBadge.backgroundColor = null;
      topLeftBadge.borderColor = 0xFFCBD5E1;
      topLeftBadge.borderWidth = 1.0;

      final badgeRight = topLeftBadge.x + topLeftBadge.width;
      for (final el in elements) {
        if (el.id == topLeftBadge.id) continue;
        final isTopTitle = el.type == ElementType.text &&
            el.y < 160 &&
            (el.fontSize >= 28 || el.text.toLowerCase().contains('title') || el.text.contains(':'));
        if (isTopTitle) {
          if (el.x < badgeRight + 16.0) {
            final shift = (badgeRight + 28.0) - el.x;
            el.x = badgeRight + 28.0;
            el.y = (el.y < 30.0) ? 35.0 : el.y;
            el.width = (el.width - shift).clamp(400.0, 1920.0);
          }
        }
      }
    }
  }

  // --- XML Generators for Export ---

  static String _buildContentTypesXml(int slideCount) {
    final buffer = StringBuffer('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n');
    buffer.write('<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">\n');
    buffer.write('  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>\n');
    buffer.write('  <Default Extension="xml" ContentType="application/xml"/>\n');
    buffer.write('  <Default Extension="png" ContentType="image/png"/>\n');
    buffer.write('  <Default Extension="jpeg" ContentType="image/jpeg"/>\n');
    buffer.write('  <Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>\n');
    for (int i = 1; i <= slideCount; i++) {
      buffer.write('  <Override PartName="/ppt/slides/slide$i.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>\n');
    }
    buffer.write('</Types>');
    return buffer.toString();
  }

  static String _buildRootRelsXml() {
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n'
        '  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="ppt/presentation.xml"/>\n'
        '</Relationships>';
  }

  static String _buildPresentationXml(int slideCount) {
    final buffer = StringBuffer('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n');
    buffer.write('<p:presentation xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">\n');
    buffer.write('  <p:sldIdLst>\n');
    for (int i = 1; i <= slideCount; i++) {
      buffer.write('    <p:sldId id="${255 + i}" r:id="rId$i"/>\n');
    }
    buffer.write('  </p:sldIdLst>\n');
    buffer.write('  <p:sldSz cx="12192000" cy="6858000"/>\n');
    buffer.write('</p:presentation>');
    return buffer.toString();
  }

  static String _buildPresentationRelsXml(int slideCount) {
    final buffer = StringBuffer('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n');
    buffer.write('<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n');
    for (int i = 1; i <= slideCount; i++) {
      buffer.write('  <Relationship Id="rId$i" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide$i.xml"/>\n');
    }
    buffer.write('</Relationships>');
    return buffer.toString();
  }

  static String _buildSlideXml(Slide slide, Map<String, String> slideRels, int startMediaId, Archive archive) {
    final buffer = StringBuffer('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n');
    buffer.write('<p:sld xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">\n');

    final bgHex = (slide.backgroundColor & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
    buffer.write('  <p:cSld>\n');
    buffer.write('    <p:spTree>\n');
    buffer.write('      <p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>\n');
    buffer.write('      <p:grpSpPr/>\n');

    // Background full-bleed rect
    buffer.write('      <p:sp>\n');
    buffer.write('        <p:nvSpPr><p:cNvPr id="2" name="Background"/><p:cNvSpPr/><p:nvPr/></p:nvSpPr>\n');
    buffer.write('        <p:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="12192000" cy="6858000"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom><a:solidFill><a:srgbClr val="$bgHex"/></a:solidFill><a:ln><a:noFill/></a:ln></p:spPr>\n');
    buffer.write('      </p:sp>\n');

    int idCounter = 3;
    int currentMediaId = startMediaId;

    for (final elem in slide.elements) {
      final xEmu = (elem.x * _emuScale).toInt();
      final yEmu = (elem.y * _emuScale).toInt();
      final wEmu = (elem.width * _emuScale).toInt();
      final hEmu = (elem.height * _emuScale).toInt();

      if (elem.type == ElementType.text) {
        buffer.write('      <p:sp>\n');
        buffer.write('        <p:nvSpPr><p:cNvPr id="${idCounter++}" name="Text ${elem.id.substring(0, 4)}"/><p:cNvSpPr txBox="1"/><p:nvPr/></p:nvSpPr>\n');
        buffer.write('        <p:spPr><a:xfrm><a:off x="$xEmu" y="$yEmu"/><a:ext cx="$wEmu" cy="$hEmu"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom><a:noFill/></p:spPr>\n');
        buffer.write('        <p:txBody>\n');
        buffer.write('          <a:bodyPr wrap="square"/>\n');

        if (elem.paragraphs.isNotEmpty) {
          for (final p in elem.paragraphs) {
            final align = p.textAlign == 'center' ? 'ctr' : (p.textAlign == 'right' ? 'r' : 'l');
            final hexColor = (p.textColor & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
            final escapedText = const HtmlEscape().convert(p.text);
            buffer.write('          <a:p>\n');
            buffer.write('            <a:pPr algn="$align"/>\n');
            buffer.write('            <a:r>\n');
            buffer.write('              <a:rPr sz="${(p.fontSize * 100).toInt()}" b="${p.isBold ? 1 : 0}" i="${p.isItalic ? 1 : 0}">\n');
            buffer.write('                <a:solidFill><a:srgbClr val="$hexColor"/></a:solidFill>\n');
            buffer.write('              </a:rPr>\n');
            buffer.write('              <a:t>$escapedText</a:t>\n');
            buffer.write('            </a:r>\n');
            buffer.write('          </a:p>\n');
          }
        } else {
          final hexColor = (elem.textColor & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
          final align = elem.textAlign == 'center' ? 'ctr' : (elem.textAlign == 'right' ? 'r' : 'l');
          final escapedText = const HtmlEscape().convert(elem.text);
          buffer.write('          <a:p>\n');
          buffer.write('            <a:pPr algn="$align"/>\n');
          buffer.write('            <a:r>\n');
          buffer.write('              <a:rPr sz="${(elem.fontSize * 100).toInt()}" b="${elem.isBold ? 1 : 0}" i="${elem.isItalic ? 1 : 0}">\n');
          buffer.write('                <a:solidFill><a:srgbClr val="$hexColor"/></a:solidFill>\n');
          buffer.write('              </a:rPr>\n');
          buffer.write('              <a:t>$escapedText</a:t>\n');
          buffer.write('            </a:r>\n');
          buffer.write('          </a:p>\n');
        }

        buffer.write('        </p:txBody>\n');
        buffer.write('      </p:sp>\n');
      } else if (elem.type == ElementType.image) {
        Uint8List? imgBytes;
        if (elem.imageBase64 != null && elem.imageBase64!.isNotEmpty) {
          try {
            imgBytes = base64Decode(elem.imageBase64!);
          } catch (_) {}
        }

        if (imgBytes != null) {
          final relId = 'rId${slideRels.length + 1}';
          final mediaFileName = 'image$currentMediaId.png';
          slideRels[relId] = '../media/$mediaFileName';
          archive.addFile(ArchiveFile('ppt/media/$mediaFileName', imgBytes.length, imgBytes));
          currentMediaId++;

          buffer.write('      <p:pic>\n');
          buffer.write('        <p:nvPicPr><p:cNvPr id="${idCounter++}" name="Image"/><p:cNvPicPr/><p:nvPr/></p:nvPicPr>\n');
          buffer.write('        <p:blipFill><a:blip r:embed="$relId"/><a:stretch><a:fillRect/></a:stretch></p:blipFill>\n');
          buffer.write('        <p:spPr><a:xfrm><a:off x="$xEmu" y="$yEmu"/><a:ext cx="$wEmu" cy="$hEmu"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></p:spPr>\n');
          buffer.write('      </p:pic>\n');
        }
      } else if (elem.type == ElementType.table) {
        final rows = elem.tableData;
        final rowCount = rows.length;
        final colCount = rows.isNotEmpty ? rows.first.length : 1;
        final colWidthEmu = (wEmu / colCount).toInt();
        final rowHeightEmu = (hEmu / rowCount).toInt();

        buffer.write('      <p:graphicFrame>\n');
        buffer.write('        <p:nvGraphicFramePr><p:cNvPr id="${idCounter++}" name="Table"/><p:cNvGraphicFramePr><a:graphicFrameLocks noGrp="1"/></p:cNvGraphicFramePr><p:nvPr/></p:nvGraphicFramePr>\n');
        buffer.write('        <p:xfrm><a:off x="$xEmu" y="$yEmu"/><a:ext cx="$wEmu" cy="$hEmu"/></p:xfrm>\n');
        buffer.write('        <a:graphic>\n');
        buffer.write('          <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/table">\n');
        buffer.write('            <a:tbl>\n');
        buffer.write('              <a:tblPr firstRow="${elem.tableHasHeader ? 1 : 0}"/>\n');
        buffer.write('              <a:tblGrid>\n');
        for (int c = 0; c < colCount; c++) {
          buffer.write('                <a:gridCol w="$colWidthEmu"/>\n');
        }
        buffer.write('              </a:tblGrid>\n');

        for (int r = 0; r < rowCount; r++) {
          buffer.write('              <a:tr h="$rowHeightEmu">\n');
          for (int c = 0; c < colCount; c++) {
            final cellText = c < rows[r].length ? rows[r][c] : '';
            final escapedCell = const HtmlEscape().convert(cellText);
            buffer.write('                <a:tc>\n');
            buffer.write('                  <a:txBody>\n');
            buffer.write('                    <a:bodyPr/>\n');
            buffer.write('                    <a:p>\n');
            buffer.write('                      <a:pPr algn="ctr"/>\n');
            buffer.write('                      <a:r>\n');
            buffer.write('                        <a:rPr sz="${(elem.tableFontSize * 100).toInt()}" b="${r == 0 && elem.tableHasHeader ? 1 : 0}"/>\n');
            buffer.write('                        <a:t>$escapedCell</a:t>\n');
            buffer.write('                      </a:r>\n');
            buffer.write('                    </a:p>\n');
            buffer.write('                  </a:txBody>\n');
            buffer.write('                </a:tc>\n');
          }
          buffer.write('              </a:tr>\n');
        }

        buffer.write('            </a:tbl>\n');
        buffer.write('          </a:graphicData>\n');
        buffer.write('        </a:graphic>\n');
        buffer.write('      </p:graphicFrame>\n');
      } else if (elem.type == ElementType.shape) {
        final fillHex = (elem.fillColor & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
        final geom = elem.shapeType == 'circle' ? 'ellipse' : (elem.shapeType == 'rounded_rect' ? 'roundRect' : 'rect');
        buffer.write('      <p:sp>\n');
        buffer.write('        <p:nvSpPr><p:cNvPr id="${idCounter++}" name="Shape"/><p:cNvSpPr/><p:nvPr/></p:nvSpPr>\n');
        buffer.write('        <p:spPr>\n');
        buffer.write('          <a:xfrm><a:off x="$xEmu" y="$yEmu"/><a:ext cx="$wEmu" cy="$hEmu"/></a:xfrm>\n');
        buffer.write('          <a:prstGeom prst="$geom"><a:avLst/></a:prstGeom>\n');
        buffer.write('          <a:solidFill><a:srgbClr val="$fillHex"/></a:solidFill>\n');
        buffer.write('        </p:spPr>\n');
        buffer.write('      </p:sp>\n');
      }
    }

    buffer.write('    </p:spTree>\n');
    buffer.write('  </p:cSld>\n');
    buffer.write('</p:sld>');
    return buffer.toString();
  }

  static String _buildSlideRelsXml(Map<String, String> rels) {
    final buffer = StringBuffer('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n');
    buffer.write('<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n');
    for (final entry in rels.entries) {
      buffer.write('  <Relationship Id="${entry.key}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="${entry.value}"/>\n');
    }
    buffer.write('</Relationships>');
    return buffer.toString();
  }
}
