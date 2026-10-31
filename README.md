# Avionti Slides App

A modern, high-performance Native Office Presentation Suite built with Flutter and Rust.

## Features
- **High-Performance Rust Core**: Native FFI for instant snap calculations, OpenXML geometric transforms, and fast layout operations.
- **Full PPTX Import & Export**: Import real-world PowerPoint (.pptx) decks with multi-paragraph text runs, font styling, tables, shapes, and images.
- **WYSIWYG Live Canvas & Inspector**: Real-time canvas preview and left filmstrip thumbnail live-sync with inline text editing and property inspector.
- **Rich Elements Support**:
  - Multi-line text boxes with typography, colors, alignments, and run spans.
  - Interactive table grid with customizable row/column counts, header swatches, and cell editing.
  - Vector shapes (rectangles, ellipses, rounded shapes) with fill and stroke.
  - Image element support with aspect fitting.
- **Dual-Mode Desktop & Mobile UX**: Responsive ribbon bar and inspector for desktop, adapted touch controls for mobile.
- **Offline-First & Persistent**: Auto-saving to local storage with project export (`.agy_slides` and `.pptx`).

## Getting Started

### Prerequisites
- Flutter SDK (>= 3.3.0)
- Rust & Cargo (optional, for compiling `rust_engine`)
- Windows C++ Build Tools (for Windows desktop runner) / Android SDK (for Android APK)

### Run the App
```bash
# Windows
flutter run -d windows

# Android
flutter run -d android
```

### Build
```bash
# Windows Debug/Release
flutter build windows

# Android APK
flutter build apk
```
