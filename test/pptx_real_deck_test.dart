import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:slides_app/controllers/presentation_controller.dart';
import 'package:slides_app/models/slide_element.dart';
import 'package:slides_app/services/pptx_service.dart';

void main() {
  test('Imports real-world damp_proofing_and_fireproofing_arrangements.pptx correctly', () {
    final file = File(r'C:\Users\anish\Documents\damp_proofing_and_fireproofing_arrangements.pptx');
    if (!file.existsSync()) {
      return;
    }
    final bytes = file.readAsBytesSync();
    final presentation = PptxService.importPptx(bytes, title: 'Damp Proofing');

    expect(presentation.slides.length, greaterThanOrEqualTo(7));

    // Slide 1: Dark navy background
    final s1 = presentation.slides[0];
    expect(s1.backgroundColor, isNot(equals(0xFFFFFFFF)), reason: 'Slide 1 should have a dark background');

    // Slide 4: Should have an image element (rooftop terrace)
    final s4 = presentation.slides[3];
    final imagesOnS4 = s4.elements.where((e) => e.type == ElementType.image).toList();
    expect(imagesOnS4, isNotEmpty, reason: 'Slide 4 must contain the terrace photo');

    // Slide 5: Should have a table element
    final s5 = presentation.slides[4];
    final tablesOnS5 = s5.elements.where((e) => e.type == ElementType.table).toList();
    expect(tablesOnS5, isNotEmpty, reason: 'Slide 5 must contain the matrix table');
    final table = tablesOnS5.first;
    expect(table.tableCols, equals(5));
    expect(table.tableRows, greaterThanOrEqualTo(5));
  });

  test('Scans storage recursively for PPT files', () {
    final userProfile = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '';
    final roots = [
      Directory('$userProfile/Desktop'),
      Directory('$userProfile/Documents'),
      Directory('$userProfile/Downloads'),
    ];

    final found = <String>[];
    void scan(Directory dir, int currentDepth, int maxDepth) {
      if (currentDepth > maxDepth) return;
      try {
        for (final entity in dir.listSync(followLinks: false)) {
          final name = entity.uri.pathSegments.where((s) => s.isNotEmpty).lastOrNull ?? '';
          if (name.startsWith('.') || name == 'node_modules' || name == 'build' || name == 'target' || name == 'AppData' || name == 'Windows') {
            continue;
          }
          if (entity is File) {
            final p = entity.path.toLowerCase();
            if (p.endsWith('.pptx') || p.endsWith('.ppt') || p.endsWith('.agy_slides')) {
              found.add(entity.path);
            }
          } else if (entity is Directory) {
            scan(entity, currentDepth + 1, maxDepth);
          }
        }
      } catch (_) {}
    }

    for (final r in roots) {
      if (r.existsSync()) scan(r, 0, 3);
    }

    expect(found, isNotEmpty, reason: 'Should discover at least the PPTX files on Desktop/sih');
  });

  test('Verify Kabadiwala presentation styling, runs, and no phantom shapes', () {
    final file = File(r'C:\Users\anish\Desktop\sih\Kabadiwala_Connect_SIH2026_Idea_Presentation.pptx');
    if (!file.existsSync()) return;
    final bytes = file.readAsBytesSync();
    final pres = PptxService.importPptx(bytes, title: 'Kabadiwala');

    final s2 = pres.slides[1];
    // Check that there is NO phantom shape at (0, 0)
    final phantomShapes = s2.elements.where((e) => e.type == ElementType.shape && e.x == 0 && e.y == 0 && e.text.isEmpty).toList();
    expect(phantomShapes, isEmpty, reason: 'There should be no phantom grey shape covering the title');

    // Check title text exists
    final titleElem = s2.elements.firstWhere((e) => e.text.contains('KABADIWALA CONNECT'));
    expect(titleElem, isNotNull);

    // Check multi-paragraph runs with colors
    final bodyElem = s2.elements.firstWhere((e) => e.text.contains('100% Offline-First Architecture'));
    expect(bodyElem.paragraphs, isNotEmpty);
    
    // Find the paragraph with multiple runs (100% Offline-First Architecture)
    final pWithRuns = bodyElem.paragraphs.firstWhere((p) => p.text.contains('100% Offline-First'));
    expect(pWithRuns.runs.length, greaterThanOrEqualTo(2));
    
    // Verify run colors are preserved (e.g. SIH Blue 0xFF1E56A0 or Navy 0xFF102C57)
    final blueOrNavyRuns = pWithRuns.runs.where((r) => r.textColor != 0xFF1E293B).toList();
    expect(blueOrNavyRuns, isNotEmpty, reason: 'Rich run colors must be preserved from PPTX');
  });

  test('Verify live text preview synchronizes elem.paragraphs on updateElementText and updateElementTextStyle', () {
    final controller = PresentationController();
    controller.addTextElement(x: 100, y: 100, text: 'Initial Text Line 1\nInitial Text Line 2');
    final elem = controller.currentSlide.elements.last;

    expect(elem.text, contains('Initial Text Line 1'));

    // 1. Test updating text
    controller.updateElementText(elem.id, 'Updated Line 1\nUpdated Line 2');
    expect(elem.text, equals('Updated Line 1\nUpdated Line 2'));
    expect(elem.paragraphs.length, equals(2));
    expect(elem.paragraphs[0].text, equals('Updated Line 1'));
    expect(elem.paragraphs[0].runs.first.text, equals('Updated Line 1'));
    expect(elem.paragraphs[1].text, equals('Updated Line 2'));
    expect(elem.paragraphs[1].runs.first.text, equals('Updated Line 2'));

    // 2. Test updating text color
    controller.updateElementTextColor(elem.id, 0xFFEF4444);
    expect(elem.textColor, equals(0xFFEF4444));
    expect(elem.paragraphs[0].textColor, equals(0xFFEF4444));
    expect(elem.paragraphs[0].runs.first.textColor, equals(0xFFEF4444));

    // 3. Test updating font size
    controller.updateElementFontSize(elem.id, 36.0);
    expect(elem.fontSize, equals(36.0));
    expect(elem.paragraphs[0].fontSize, equals(36.0));
    expect(elem.paragraphs[0].runs.first.fontSize, equals(36.0));
  });
}
