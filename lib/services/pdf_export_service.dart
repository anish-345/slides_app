import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/presentation.dart';
import '../models/slide_element.dart';

class PdfExportService {
  static Future<void> exportToPdf(Presentation presentation) async {
    final pdf = pw.Document();

    // 16:9 presentation slide format (960 x 540 pt)
    const pageFormat = PdfPageFormat(960, 540, marginAll: 0);
    const scale = 960.0 / 1920.0;

    for (final slide in presentation.slides) {
      final sortedElements = List.of(slide.elements)
        ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

      // Preload images for this slide
      final Map<String, Uint8List> loadedImages = {};
      for (final elem in sortedElements) {
        if (elem.type == ElementType.image) {
          if (elem.imageBase64 != null && elem.imageBase64!.isNotEmpty) {
            try {
              loadedImages[elem.id] = base64Decode(elem.imageBase64!);
            } catch (_) {}
          } else if (elem.imagePath != null && elem.imagePath!.isNotEmpty) {
            try {
              final file = File(elem.imagePath!);
              if (file.existsSync()) {
                loadedImages[elem.id] = await file.readAsBytes();
              }
            } catch (_) {}
          }
        }
      }

      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (pw.Context context) {
            return pw.Container(
              width: 960,
              height: 540,
              color: PdfColor.fromInt(slide.backgroundColor),
              child: pw.Stack(
                children: [
                  for (final elem in sortedElements)
                    pw.Positioned(
                      left: elem.x * scale,
                      top: elem.y * scale,
                      child: pw.Opacity(
                        opacity: elem.opacity,
                        child: pw.SizedBox(
                          width: elem.width * scale,
                          height: elem.height * scale,
                          child: _buildPdfElement(elem, scale, loadedImages[elem.id]),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${presentation.title.replaceAll(' ', '_')}.pdf',
    );
  }

  static pw.Widget _buildPdfElement(
    SlideElement elem,
    double scale,
    Uint8List? imageBytes,
  ) {
    switch (elem.type) {
      case ElementType.text:
        return pw.Container(
          alignment: _getPdfAlignment(elem.textAlign),
          child: pw.Text(
            elem.text,
            textAlign: _getPdfTextAlign(elem.textAlign),
            style: pw.TextStyle(
              fontSize: elem.fontSize * scale,
              fontWeight: elem.isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontStyle: elem.isItalic ? pw.FontStyle.italic : pw.FontStyle.normal,
              color: PdfColor.fromInt(elem.textColor),
            ),
          ),
        );

      case ElementType.image:
        if (imageBytes != null) {
          return pw.ClipRRect(
            horizontalRadius: elem.borderRadius * scale,
            verticalRadius: elem.borderRadius * scale,
            child: pw.Image(
              pw.MemoryImage(imageBytes),
              fit: elem.fit == 'cover' ? pw.BoxFit.cover : pw.BoxFit.contain,
            ),
          );
        }
        return pw.Container(
          color: const PdfColor(0.9, 0.9, 0.9),
          child: pw.Center(
            child: pw.Text('Image', style: const pw.TextStyle(color: PdfColors.grey)),
          ),
        );

      case ElementType.shape:
        return pw.Container(
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(elem.fillColor),
            border: elem.strokeWidth > 0
                ? pw.Border.all(
                    color: PdfColor.fromInt(elem.strokeColor),
                    width: elem.strokeWidth * scale,
                  )
                : null,
            borderRadius: elem.shapeType == 'circle'
                ? pw.BorderRadius.circular(1000)
                : pw.BorderRadius.circular(elem.borderRadius * scale),
          ),
        );

      case ElementType.table:
        final rows = elem.tableData;
        return pw.Table(
          border: pw.TableBorder.all(color: PdfColor.fromInt(elem.tableBorderColor), width: 1),
          children: [
            for (int r = 0; r < rows.length; r++)
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: r == 0 && elem.tableHasHeader
                      ? PdfColor.fromInt(elem.tableHeaderColor)
                      : (r % 2 == 1 ? PdfColor.fromInt(elem.tableRowColor) : PdfColor.fromInt(elem.tableAltRowColor)),
                ),
                children: [
                  for (final cell in rows[r])
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        cell,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: elem.tableFontSize * scale,
                          fontWeight: r == 0 && elem.tableHasHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        );
    }
  }

  static pw.Alignment _getPdfAlignment(String align) {
    switch (align) {
      case 'center':
        return pw.Alignment.center;
      case 'right':
        return pw.Alignment.centerRight;
      default:
        return pw.Alignment.centerLeft;
    }
  }

  static pw.TextAlign _getPdfTextAlign(String align) {
    switch (align) {
      case 'center':
        return pw.TextAlign.center;
      case 'right':
        return pw.TextAlign.right;
      default:
        return pw.TextAlign.left;
    }
  }
}
