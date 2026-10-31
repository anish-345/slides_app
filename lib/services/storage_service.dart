import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/presentation_controller.dart';
import '../models/presentation.dart';
import 'pptx_service.dart';

class StorageService {
  static const String _recentKey = 'avionti_recent_presentations';

  /// Loads recent presentations list from persistent device storage
  static Future<List<Presentation>> loadRecentPresentations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_recentKey);
      if (list != null && list.isNotEmpty) {
        return list.map((jsonStr) {
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          return Presentation.fromJson(map);
        }).toList();
      }
    } catch (e) {
      debugPrint('Error loading recent presentations: $e');
    }
    return [];
  }

  /// Saves or updates a presentation in the recent list
  static Future<void> saveRecentPresentation(Presentation pres) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentList = await loadRecentPresentations();
      final updatedList = [
        pres,
        ...currentList.where((p) => p.id != pres.id),
      ];
      // Keep up to 20 recent presentations
      final trimmed = updatedList.take(20).toList();
      final encodedList = trimmed.map((p) => jsonEncode(p.toJson())).toList();
      await prefs.setStringList(_recentKey, encodedList);
    } catch (e) {
      debugPrint('Error saving recent presentation: $e');
    }
  }

  /// Removes a presentation from the recent list
  static Future<void> deleteRecentPresentation(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentList = await loadRecentPresentations();
      final updatedList = currentList.where((p) => p.id != id).toList();
      final encodedList = updatedList.map((p) => jsonEncode(p.toJson())).toList();
      await prefs.setStringList(_recentKey, encodedList);
    } catch (e) {
      debugPrint('Error deleting recent presentation: $e');
    }
  }

  /// Exports presentation as native project file (.agy_slides)
  static Future<bool> saveProject(PresentationController controller) async {
    final jsonString = controller.exportToJson();
    final bytes = Uint8List.fromList(utf8.encode(jsonString));

    final uri = await FilePicker.saveFile(
      dialogTitle: 'Save Presentation Project',
      fileName: '${controller.presentation.title.replaceAll(' ', '_')}.agy_slides',
      bytes: bytes,
    );

    if (uri != null) {
      await saveRecentPresentation(controller.presentation);
      return true;
    }
    return false;
  }

  /// Exports presentation as standard OpenXML PowerPoint (.pptx)
  static Future<bool> exportPptx(PresentationController controller) async {
    final bytes = PptxService.exportPptx(controller.presentation);

    final uri = await FilePicker.saveFile(
      dialogTitle: 'Export PowerPoint Presentation (.pptx)',
      fileName: '${controller.presentation.title.replaceAll(' ', '_')}.pptx',
      bytes: bytes,
    );

    return uri != null;
  }

  /// Picks and imports a .pptx or native presentation file from disk
  static Future<Presentation?> pickAndLoadPresentation() async {
    final files = await FilePicker.pickFiles(
      dialogTitle: 'Open Presentation or PPTX File',
      type: FileType.custom,
      allowedExtensions: ['pptx', 'ppt', 'agy_slides', 'json'],
    );

    if (files.isNotEmpty) {
      final file = files.first;
      final bytes = await file.readAsBytes();
      final name = file.name.toLowerCase();

      Presentation presentation;
      if (name.endsWith('.pptx') || name.endsWith('.ppt')) {
        presentation = PptxService.importPptx(
          bytes,
          title: file.name.replaceAll(RegExp(r'\.pptx?$'), ''),
        );
      } else {
        final content = utf8.decode(bytes);
        presentation = Presentation.fromJson(jsonDecode(content) as Map<String, dynamic>);
      }

      await saveRecentPresentation(presentation);
      return presentation;
    }
    return null;
  }

  /// Loads presentation directly into the controller
  static Future<bool> loadProject(PresentationController controller) async {
    final pres = await pickAndLoadPresentation();
    if (pres != null) {
      controller.loadPresentation(pres);
      return true;
    }
    return false;
  }
}
