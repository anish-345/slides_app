import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

// FFI Native & Dart Typedefs
typedef RustVersionNative = ffi.Pointer<Utf8> Function();
typedef RustVersionDart = ffi.Pointer<Utf8> Function();

typedef RustFreeStringNative = ffi.Void Function(ffi.Pointer<Utf8>);
typedef RustFreeStringDart = void Function(ffi.Pointer<Utf8>);

typedef RustSnapAxisNative = ffi.Double Function(ffi.Double, ffi.Double, ffi.Double, ffi.Double);
typedef RustSnapAxisDart = double Function(double, double, double, double);

final class NativeTextStats extends ffi.Struct {
  @ffi.Uint32()
  external int wordCount;

  @ffi.Uint32()
  external int charCount;

  @ffi.Uint32()
  external int lineCount;
}

typedef RustAnalyzeTextNative = NativeTextStats Function(ffi.Pointer<Utf8>);
typedef RustAnalyzeTextDart = NativeTextStats Function(ffi.Pointer<Utf8>);

// Avionti Native C Typedefs
typedef AviontiGetVersionNative = ffi.Pointer<Utf8> Function();
typedef AviontiGetVersionDart = ffi.Pointer<Utf8> Function();

typedef AviontiCreateDefaultDeckNative = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8> title);
typedef AviontiCreateDefaultDeckDart = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8> title);

typedef AviontiAddSlideToDeckNative = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8> deckJson, ffi.Pointer<Utf8> layout);
typedef AviontiAddSlideToDeckDart = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8> deckJson, ffi.Pointer<Utf8> layout);

typedef AviontiAddShapeToSlideNative = ffi.Pointer<Utf8> Function(
  ffi.Pointer<Utf8> deckJson,
  ffi.Int32 slideIdx,
  ffi.Pointer<Utf8> shapeType,
  ffi.Pointer<Utf8> fillColor,
  ffi.Float x,
  ffi.Float y,
  ffi.Float w,
  ffi.Float h,
);
typedef AviontiAddShapeToSlideDart = ffi.Pointer<Utf8> Function(
  ffi.Pointer<Utf8> deckJson,
  int slideIdx,
  ffi.Pointer<Utf8> shapeType,
  ffi.Pointer<Utf8> fillColor,
  double x,
  double y,
  double w,
  double h,
);

typedef AviontiFreeStringNative = ffi.Void Function(ffi.Pointer<Utf8> ptr);
typedef AviontiFreeStringDart = void Function(ffi.Pointer<Utf8> ptr);

class TextAnalysisResult {
  final int wordCount;
  final int charCount;
  final int lineCount;

  TextAnalysisResult({
    required this.wordCount,
    required this.charCount,
    required this.lineCount,
  });
}

class RustEngineService {
  static ffi.DynamicLibrary? _lib;
  static bool _initialized = false;
  static String _version = 'Dart Fallback Engine';

  static RustVersionDart? _rustVersion;
  static RustFreeStringDart? _rustFreeString;
  static RustSnapAxisDart? _rustSnapAxis;
  static RustAnalyzeTextDart? _rustAnalyzeText;

  static AviontiGetVersionDart? _aviontiGetVersion;
  static AviontiCreateDefaultDeckDart? _aviontiCreateDefaultDeck;
  static AviontiAddSlideToDeckDart? _aviontiAddSlideToDeck;
  static AviontiAddShapeToSlideDart? _aviontiAddShapeToSlide;
  static AviontiFreeStringDart? _aviontiFreeString;

  static void init() {
    if (_initialized) return;
    _initialized = true;

    try {
      if (Platform.isWindows) {
        final possiblePaths = [
          'rust_engine.dll',
          'rust_engine/target/release/rust_engine.dll',
          'rust_engine/target/debug/rust_engine.dll',
          '${File(Platform.resolvedExecutable).parent.path}\\rust_engine.dll',
        ];

        for (final p in possiblePaths) {
          if (File(p).existsSync()) {
            _lib = ffi.DynamicLibrary.open(p);
            break;
          }
        }
      } else if (Platform.isAndroid) {
        _lib = ffi.DynamicLibrary.open('librust_engine.so');
      }

      if (_lib != null) {
        _rustVersion = _lib!
            .lookup<ffi.NativeFunction<RustVersionNative>>('rust_engine_version')
            .asFunction<RustVersionDart>();
        _rustFreeString = _lib!
            .lookup<ffi.NativeFunction<RustFreeStringNative>>('rust_free_string')
            .asFunction<RustFreeStringDart>();
        _rustSnapAxis = _lib!
            .lookup<ffi.NativeFunction<RustSnapAxisNative>>('rust_snap_axis')
            .asFunction<RustSnapAxisDart>();
        _rustAnalyzeText = _lib!
            .lookup<ffi.NativeFunction<RustAnalyzeTextNative>>('rust_analyze_text')
            .asFunction<RustAnalyzeTextDart>();

        // Avionti bindings
        try {
          _aviontiGetVersion = _lib!
              .lookup<ffi.NativeFunction<AviontiGetVersionNative>>('avionti_get_version')
              .asFunction<AviontiGetVersionDart>();
          _aviontiCreateDefaultDeck = _lib!
              .lookup<ffi.NativeFunction<AviontiCreateDefaultDeckNative>>('avionti_create_default_deck')
              .asFunction<AviontiCreateDefaultDeckDart>();
          _aviontiAddSlideToDeck = _lib!
              .lookup<ffi.NativeFunction<AviontiAddSlideToDeckNative>>('avionti_add_slide_to_deck')
              .asFunction<AviontiAddSlideToDeckDart>();
          _aviontiAddShapeToSlide = _lib!
              .lookup<ffi.NativeFunction<AviontiAddShapeToSlideNative>>('avionti_add_shape_to_slide')
              .asFunction<AviontiAddShapeToSlideDart>();
          _aviontiFreeString = _lib!
              .lookup<ffi.NativeFunction<AviontiFreeStringNative>>('avionti_free_string')
              .asFunction<AviontiFreeStringDart>();
        } catch (e) {
          debugPrint('Notice: Avionti symbols lookup: $e');
        }

        if (_rustVersion != null) {
          final ptr = _rustVersion!();
          _version = ptr.toDartString();
          if (_rustFreeString != null) {
            _rustFreeString!(ptr);
          }
        }
      }
    } catch (_) {
      _lib = null;
    }
  }

  static bool get isNativeLoaded => _lib != null;
  static String get engineVersion => _version;

  /// Returns the Avionti Rust core version
  static String getAviontiVersion() {
    init();
    if (_aviontiGetVersion != null && _aviontiFreeString != null) {
      final ptr = _aviontiGetVersion!();
      final str = ptr.toDartString();
      _aviontiFreeString!(ptr);
      return str;
    }
    return 'Avionti Core 1.0 (Managed)';
  }

  /// High-performance magnetic snapping calculation
  static double snapCoordinate({
    required double pos,
    required double size,
    required double target,
    double threshold = 15.0,
  }) {
    init();
    if (_rustSnapAxis != null) {
      return _rustSnapAxis!(pos, size, target, threshold);
    }

    // Dart fallback
    if ((pos - target).abs() <= threshold) return target;
    final center = pos + (size / 2.0);
    if ((center - target).abs() <= threshold) return target - (size / 2.0);
    final end = pos + size;
    if ((end - target).abs() <= threshold) return target - size;
    return pos;
  }

  /// High-performance text stats
  static TextAnalysisResult analyzeText(String text) {
    init();
    if (_rustAnalyzeText != null) {
      final ptr = text.toNativeUtf8();
      try {
        final stats = _rustAnalyzeText!(ptr);
        return TextAnalysisResult(
          wordCount: stats.wordCount,
          charCount: stats.charCount,
          lineCount: stats.lineCount,
        );
      } finally {
        malloc.free(ptr);
      }
    }

    // Dart fallback
    final words = text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
    final chars = text.length;
    final lines = text.split('\n').length;
    return TextAnalysisResult(
      wordCount: words,
      charCount: chars,
      lineCount: lines,
    );
  }

  /// Creates a default Avionti presentation JSON via Rust
  static Map<String, dynamic>? createAviontiDeckJson(String title) {
    init();
    if (_aviontiCreateDefaultDeck != null && _aviontiFreeString != null) {
      final titlePtr = title.toNativeUtf8();
      try {
        final resPtr = _aviontiCreateDefaultDeck!(titlePtr);
        final jsonStr = resPtr.toDartString();
        _aviontiFreeString!(resPtr);
        return jsonDecode(jsonStr) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('Error calling Rust avionti_create_default_deck: $e');
      } finally {
        malloc.free(titlePtr);
      }
    }
    return null;
  }

  /// Adds a slide to a deck via Rust
  static String? addSlideViaRust(String deckJson, String layout) {
    init();
    if (_aviontiAddSlideToDeck != null && _aviontiFreeString != null) {
      final jsonPtr = deckJson.toNativeUtf8();
      final layoutPtr = layout.toNativeUtf8();
      try {
        final resPtr = _aviontiAddSlideToDeck!(jsonPtr, layoutPtr);
        final str = resPtr.toDartString();
        _aviontiFreeString!(resPtr);
        return str;
      } catch (e) {
        debugPrint('Error in Rust avionti_add_slide_to_deck: $e');
      } finally {
        malloc.free(jsonPtr);
        malloc.free(layoutPtr);
      }
    }
    return null;
  }

  /// Adds a shape to a slide via Rust
  static String? addShapeViaRust({
    required String deckJson,
    required int slideIdx,
    required String shapeType,
    required String fillColor,
    required double x,
    required double y,
    required double w,
    required double h,
  }) {
    init();
    if (_aviontiAddShapeToSlide != null && _aviontiFreeString != null) {
      final jsonPtr = deckJson.toNativeUtf8();
      final shapePtr = shapeType.toNativeUtf8();
      final colorPtr = fillColor.toNativeUtf8();
      try {
        final resPtr = _aviontiAddShapeToSlide!(jsonPtr, slideIdx, shapePtr, colorPtr, x, y, w, h);
        final str = resPtr.toDartString();
        _aviontiFreeString!(resPtr);
        return str;
      } catch (e) {
        debugPrint('Error in Rust avionti_add_shape_to_slide: $e');
      } finally {
        malloc.free(jsonPtr);
        malloc.free(shapePtr);
        malloc.free(colorPtr);
      }
    }
    return null;
  }
}
