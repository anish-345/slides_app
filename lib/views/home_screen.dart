import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/presentation_controller.dart';
import '../models/presentation.dart';
import '../services/pptx_service.dart';
import '../services/rust_engine_service.dart';
import '../services/storage_service.dart';
import 'slide_editor_screen.dart';

class DiscoveredFileItem {
  final String path;
  final String name;
  final int sizeBytes;
  final DateTime modified;
  final bool isPptx;

  DiscoveredFileItem({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.modified,
    required this.isPptx,
  });

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedDate {
    return '${modified.day.toString().padLeft(2, '0')}/${modified.month.toString().padLeft(2, '0')}/${modified.year} ${modified.hour.toString().padLeft(2, '0')}:${modified.minute.toString().padLeft(2, '0')}';
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const Color aviontiOrange = Color(0xFFC43E1C);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0; // 0: Presentations, 1: Browse Files
  List<Presentation> _recentPresentations = [];
  List<DiscoveredFileItem> _discoveredFiles = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortBy = 'modified'; // 'modified', 'name', 'size'
  bool _sortAscending = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    RustEngineService.init();
    _refreshAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    setState(() => _isLoading = true);

    // 1. Load recent user presentations (clean out any old hardcoded preset mock decks)
    final savedList = await StorageService.loadRecentPresentations();
    final cleanList = savedList.where((p) {
      final t = p.title.toLowerCase();
      return !t.contains('avionti pitch deck') &&
          !t.contains('modern dark deck') &&
          !t.contains('technical schedule & matrix');
    }).toList();

    // 2. Scan computer / device for actual .pptx and .ppt files (recursively up to depth 3)
    final files = await _scanStorageForPptFiles();

    if (mounted) {
      setState(() {
        _recentPresentations = cleanList;
        _discoveredFiles = files;
        _isLoading = false;
      });
    }
  }

  Future<List<DiscoveredFileItem>> _scanStorageForPptFiles() async {
    final List<DiscoveredFileItem> results = [];
    final Set<String> seenPaths = {};

    final directories = <Directory>[];

    // Current working directory and parent
    try {
      directories.add(Directory.current);
      final parent = Directory.current.parent;
      if (parent.existsSync()) directories.add(parent);
    } catch (_) {}

    // User Profile folders (Documents, Downloads, Desktop)
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      final userProfile = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
      if (userProfile != null) {
        final docs = Directory('$userProfile${Platform.pathSeparator}Documents');
        if (docs.existsSync()) directories.add(docs);

        final downloads = Directory('$userProfile${Platform.pathSeparator}Downloads');
        if (downloads.existsSync()) directories.add(downloads);

        final desktop = Directory('$userProfile${Platform.pathSeparator}Desktop');
        if (desktop.existsSync()) directories.add(desktop);
      }
    }

    void scanRecursive(Directory dir, int currentDepth, int maxDepth) {
      if (currentDepth > maxDepth) return;
      try {
        final entries = dir.listSync(followLinks: false);
        for (final entry in entries) {
          final segs = entry.uri.pathSegments.where((s) => s.isNotEmpty).toList();
          final name = segs.isNotEmpty ? segs.last : '';

          // Skip hidden directories and heavy non-document build/cache folders
          final lowerName = name.toLowerCase();
          if (lowerName.startsWith('.') ||
              lowerName == 'node_modules' ||
              lowerName == 'build' ||
              lowerName == 'target' ||
              lowerName == 'appdata' ||
              lowerName == 'windows' ||
              lowerName == 'temp' ||
              lowerName == 'cache') {
            continue;
          }

          if (entry is File) {
            final p = entry.path.toLowerCase();
            if (p.endsWith('.pptx') || p.endsWith('.ppt') || p.endsWith('.agy_slides')) {
              if (!seenPaths.contains(entry.path)) {
                seenPaths.add(entry.path);
                try {
                  final stat = entry.statSync();
                  final filename = segs.isNotEmpty ? segs.last : 'Presentation';
                  results.add(DiscoveredFileItem(
                    path: entry.path,
                    name: filename,
                    sizeBytes: stat.size,
                    modified: stat.modified,
                    isPptx: p.endsWith('.pptx') || p.endsWith('.ppt'),
                  ));
                } catch (_) {}
              }
            }
          } else if (entry is Directory) {
            scanRecursive(entry, currentDepth + 1, maxDepth);
          }
        }
      } catch (_) {}
    }

    for (final dir in directories) {
      scanRecursive(dir, 0, 3);
    }

    results.sort((a, b) => b.modified.compareTo(a.modified));
    return results;
  }

  void _openEditor(Presentation pres) async {
    final controller = PresentationController();
    controller.loadPresentation(pres);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SlideEditorScreen(controller: controller),
      ),
    );

    // Save changes and refresh
    await StorageService.saveRecentPresentation(controller.presentation);
    _refreshAll();
  }

  void _createNewBlankPresentation() {
    final controller = PresentationController();
    controller.createFromTemplate('blank', customTitle: 'Untitled Presentation');
    _openEditor(controller.presentation);
  }

  Future<void> _pickAndOpenFile() async {
    try {
      final files = await FilePicker.pickFiles(
        dialogTitle: 'Select PowerPoint (.pptx / .ppt) or Presentation File',
        type: FileType.custom,
        allowedExtensions: ['pptx', 'ppt', 'agy_slides', 'json'],
      );

      if (files.isNotEmpty && files.first.path != null) {
        await _openFilePath(files.first.path!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open file: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _openFilePath(String filePath) async {
    setState(() => _isLoading = true);
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File does not exist on disk')),
          );
        }
        return;
      }

      final bytes = await file.readAsBytes();
      final filename = file.uri.pathSegments.lastWhere((s) => s.isNotEmpty, orElse: () => 'Presentation');
      final isPowerPoint = filePath.toLowerCase().endsWith('.pptx') || filePath.toLowerCase().endsWith('.ppt');

      Presentation presentation;
      if (isPowerPoint) {
        presentation = PptxService.importPptx(
          bytes,
          title: filename.replaceAll(RegExp(r'\.pptx?$', caseSensitive: false), ''),
        );
      } else {
        presentation = Presentation.fromJson(jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>);
      }

      await StorageService.saveRecentPresentation(presentation);
      if (mounted) {
        _openEditor(presentation);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading presentation: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _copyFilePath(String path) {
    Clipboard.setData(ClipboardData(text: path));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('Copied path: $path', overflow: TextOverflow.ellipsis)),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _revealInFolder(String path) {
    if (Platform.isWindows) {
      Process.run('explorer.exe', ['/select,', path]);
    } else if (Platform.isMacOS) {
      Process.run('open', ['-R', path]);
    } else if (Platform.isLinux) {
      final file = File(path);
      Process.run('xdg-open', [file.parent.path]);
    }
  }

  void _showNewPresentationSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Presentations',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFF334155)),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: HomeScreen.aviontiOrange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add_to_photos_rounded, color: HomeScreen.aviontiOrange, size: 24),
                    ),
                    title: const Text('New Blank Presentation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Start fresh with a clean 16:9 widescreen canvas', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _createNewBlankPresentation();
                    },
                  ),
                  ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: HomeScreen.aviontiOrange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                    ),
                    title: const Text('Avionti Executive Pitch Deck', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Signature orange executive deck with title, bullets & shapes', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    onTap: () {
                      Navigator.pop(ctx);
                      final c = PresentationController();
                      c.createFromTemplate('avionti_orange', customTitle: 'Avionti Pitch Deck');
                      _openEditor(c.presentation);
                    },
                  ),
                  ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF38BDF8)),
                      ),
                      child: const Center(
                        child: Icon(Icons.dark_mode_rounded, color: Color(0xFF38BDF8), size: 20),
                      ),
                    ),
                    title: const Text('Modern Dark Deck', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: const Text('High-contrast dark slate OLED presentation theme', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    onTap: () {
                      Navigator.pop(ctx);
                      final c = PresentationController();
                      c.createFromTemplate('dark_modern', customTitle: 'Modern Dark Deck');
                      _openEditor(c.presentation);
                    },
                  ),
                  ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D4ED8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(Icons.table_chart_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                    title: const Text('Technical Matrix & Schedule', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Engineering deck with interactive tables & specification matrix', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    onTap: () {
                      Navigator.pop(ctx);
                      final c = PresentationController();
                      c.createFromTemplate('technical_matrix', customTitle: 'Damp-Proofing & Fireproofing Arrangements');
                      _openEditor(c.presentation);
                    },
                  ),
                  ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.folder_open_rounded, color: Color(0xFF38BDF8), size: 24),
                    ),
                    title: const Text('Open PowerPoint (.pptx / .ppt)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Import existing slides from device storage', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAndOpenFile();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: _buildAppBar(isDesktop),
      body: isDesktop ? _buildDesktopBody() : _buildMobileBody(),
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: _currentTabIndex,
              onDestinationSelected: (idx) => setState(() => _currentTabIndex = idx),
              indicatorColor: HomeScreen.aviontiOrange.withValues(alpha: 0.2),
              backgroundColor: const Color(0xFF1E293B),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.slideshow_rounded, color: Color(0xFF94A3B8)),
                  selectedIcon: Icon(Icons.slideshow_rounded, color: HomeScreen.aviontiOrange),
                  label: 'Presentations',
                ),
                NavigationDestination(
                  icon: Icon(Icons.folder_open_rounded, color: Color(0xFF94A3B8)),
                  selectedIcon: Icon(Icons.folder_rounded, color: HomeScreen.aviontiOrange),
                  label: 'Browse Files',
                ),
              ],
            ),
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton.extended(
              onPressed: _showNewPresentationSheet,
              backgroundColor: HomeScreen.aviontiOrange,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded, size: 22),
              label: const Text('New Presentation', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDesktop) {
    return AppBar(
      backgroundColor: HomeScreen.aviontiOrange,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white24,
          ),
          child: const Center(
            child: Icon(Icons.slideshow_rounded, color: Colors.white, size: 22),
          ),
        ),
      ),
      title: Text(
        isDesktop ? 'Avionti PowerPoint & Slides Studio' : ['Presentations', 'Browse Files'][_currentTabIndex],
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      actions: [
        if (isDesktop) ...[
          if (MediaQuery.of(context).size.width >= 1050)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt_rounded, color: Colors.amber, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    RustEngineService.isNativeLoaded ? 'Rust Engine 1.0 (Active)' : 'Rust Engine (Ready)',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
            tooltip: 'Rescan storage for PPT files',
            onPressed: _refreshAll,
          ),
          TextButton.icon(
            onPressed: _pickAndOpenFile,
            icon: const Icon(Icons.folder_open_rounded, color: Colors.white, size: 18),
            label: const Text('Open (Ctrl+O)', style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _createNewBlankPresentation,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: HomeScreen.aviontiOrange,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('New Presentation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(width: 16),
        ] else ...[
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: _refreshAll,
          ),
          IconButton(
            icon: const Icon(Icons.folder_open_rounded, color: Colors.white),
            tooltip: 'Open File',
            onPressed: _pickAndOpenFile,
          ),
        ],
      ],
    );
  }

  // ==========================================
  // DESKTOP BODY (Split into Top Half & Bottom Half)
  // ==========================================
  Widget _buildDesktopBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ----------------------------------------------------
        // TOP HALF: Quick Action Cards & Recent Presentations
        // ----------------------------------------------------
        Container(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            border: Border(bottom: BorderSide(color: Color(0xFF334155), width: 1.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Row wrapped in SingleChildScrollView so it never overflows narrow windows
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildDesktopActionCard(
                      title: 'New Blank Presentation',
                      subtitle: 'Clean 16:9 widescreen presentation',
                      icon: Icons.add_to_photos_rounded,
                      accentColor: HomeScreen.aviontiOrange,
                      onTap: _createNewBlankPresentation,
                    ),
                    const SizedBox(width: 16),
                    _buildDesktopActionCard(
                      title: 'Presentation Templates',
                      subtitle: 'Executive, Dark, Technical Matrix decks',
                      icon: Icons.dashboard_customize_rounded,
                      accentColor: const Color(0xFF10B981),
                      onTap: _showNewPresentationSheet,
                    ),
                    const SizedBox(width: 16),
                    _buildDesktopActionCard(
                      title: 'Open PowerPoint (.pptx / .ppt)',
                      subtitle: 'Browse and import existing presentation slides',
                      icon: Icons.folder_open_rounded,
                      accentColor: const Color(0xFF38BDF8),
                      onTap: _pickAndOpenFile,
                    ),
                    const SizedBox(width: 16),
                    _buildDesktopStatCard(),
                  ],
                ),
              ),

              // Recent Decks Strip (if user opened/saved decks)
              if (_recentPresentations.isNotEmpty) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text(
                      'RECENT DECKS',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF334155),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_recentPresentations.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 58,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _recentPresentations.length,
                    separatorBuilder: (_, index) => const SizedBox(width: 12),
                    itemBuilder: (ctx, idx) {
                      final pres = _recentPresentations[idx];
                      return _buildRecentDeckChip(pres);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),

        // ----------------------------------------------------
        // BOTTOM HALF: Dedicated PPT Files List View
        // ----------------------------------------------------
        Expanded(
          child: _buildBottomHalfPptListView(isDesktop: true),
        ),
      ],
    );
  }

  Widget _buildDesktopStatCard() {
    return Container(
      width: 270,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF10B981), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_discoveredFiles.length} PowerPoint Files',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                const Text(
                  'Auto-indexed from storage',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF94A3B8), size: 18),
            tooltip: 'Rescan now',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: _refreshAll,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentDeckChip(Presentation pres) {
    return InkWell(
      onTap: () => _openEditor(pres),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(
          children: [
            const Icon(Icons.slideshow_rounded, color: HomeScreen.aviontiOrange, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    pres.title,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${pres.slides.length} slides',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 14, color: Color(0xFF64748B)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () async {
                await StorageService.deleteRecentPresentation(pres.id);
                _refreshAll();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // BOTTOM HALF: DEDICATED PPT FILES LIST VIEW
  // ==========================================
  Widget _buildBottomHalfPptListView({required bool isDesktop}) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: HomeScreen.aviontiOrange),
            SizedBox(height: 14),
            Text('Scanning storage for PowerPoint files...', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
          ],
        ),
      );
    }

    // Filter and sort discovered files
    final filtered = _discoveredFiles.where((f) {
      if (_searchQuery.isEmpty) return true;
      return f.name.toLowerCase().contains(_searchQuery) || f.path.toLowerCase().contains(_searchQuery);
    }).toList();

    filtered.sort((a, b) {
      int cmp = 0;
      if (_sortBy == 'name') {
        cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      } else if (_sortBy == 'size') {
        cmp = a.sizeBytes.compareTo(b.sizeBytes);
      } else {
        cmp = a.modified.compareTo(b.modified);
      }
      return _sortAscending ? cmp : -cmp;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Bottom Half Toolbar Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
          ),
          child: Row(
            children: [
              // Section Title with PPT Icon
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: HomeScreen.aviontiOrange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: HomeScreen.aviontiOrange.withValues(alpha: 0.5)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.folder_special_rounded, color: HomeScreen.aviontiOrange, size: 14),
                    SizedBox(width: 4),
                    Text('PPT FILES', style: TextStyle(color: HomeScreen.aviontiOrange, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${filtered.length})',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
              const Spacer(),

              // Sort Menu Button
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort_rounded, color: Color(0xFF94A3B8), size: 18),
                tooltip: 'Sort PPT files',
                color: const Color(0xFF1E293B),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onSelected: (val) {
                  setState(() {
                    if (_sortBy == val) {
                      _sortAscending = !_sortAscending;
                    } else {
                      _sortBy = val;
                      _sortAscending = false;
                    }
                  });
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'modified',
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: _sortBy == 'modified' ? HomeScreen.aviontiOrange : Colors.white70),
                        const SizedBox(width: 8),
                        Text(
                          'Date Modified ${_sortBy == 'modified' ? (_sortAscending ? '▲' : '▼') : ''}',
                          style: TextStyle(color: _sortBy == 'modified' ? HomeScreen.aviontiOrange : Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'name',
                    child: Row(
                      children: [
                        Icon(Icons.sort_by_alpha, size: 16, color: _sortBy == 'name' ? HomeScreen.aviontiOrange : Colors.white70),
                        const SizedBox(width: 8),
                        Text(
                          'File Name ${_sortBy == 'name' ? (_sortAscending ? '▲' : '▼') : ''}',
                          style: TextStyle(color: _sortBy == 'name' ? HomeScreen.aviontiOrange : Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'size',
                    child: Row(
                      children: [
                        Icon(Icons.data_usage, size: 16, color: _sortBy == 'size' ? HomeScreen.aviontiOrange : Colors.white70),
                        const SizedBox(width: 8),
                        Text(
                          'File Size ${_sortBy == 'size' ? (_sortAscending ? '▲' : '▼') : ''}',
                          style: TextStyle(color: _sortBy == 'size' ? HomeScreen.aviontiOrange : Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),

              // Search Filter Field
              Container(
                width: isDesktop ? 180 : 130,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Search PPT...',
                    hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    border: InputBorder.none,
                    isDense: true,
                    icon: const Icon(Icons.search, size: 15, color: Color(0xFF64748B)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 13, color: Color(0xFF94A3B8)),
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF94A3B8), size: 18),
                tooltip: 'Refresh list',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                onPressed: _refreshAll,
              ),
            ],
          ),
        ),

        // 2. Table Column Headers (Desktop List View)
        if (isDesktop && filtered.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            color: const Color(0xFF0F172A),
            child: const Row(
              children: [
                SizedBox(width: 58),
                Expanded(
                  child: Text(
                    'PRESENTATION NAME & LOCATION',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                ),
                SizedBox(width: 12),
                SizedBox(
                  width: 75,
                  child: Text(
                    'SIZE',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                ),
                SizedBox(width: 12),
                SizedBox(
                  width: 125,
                  child: Text(
                    'LAST MODIFIED',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                ),
                SizedBox(width: 12),
                SizedBox(
                  width: 185,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'ACTIONS',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // 3. The List View of PPT Files
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 6),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, idx) {
                    final file = filtered[idx];
                    return _buildPptFileRow(file, isDesktop: isDesktop);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPptFileRow(DiscoveredFileItem file, {required bool isDesktop}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          hoverColor: const Color(0xFF273549),
          onTap: () => _openFilePath(file.path),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // PPT Icon Badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEA580C), Color(0xFFC43E1C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.slideshow_rounded, color: Colors.white, size: 20),
                      Text(
                        file.isPptx ? 'PPTX' : 'PPT',
                        style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Name & Location
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        file.name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.folder_outlined, size: 12, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              file.path,
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Size
                if (isDesktop) ...[
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 80,
                    child: Text(
                      file.formattedSize,
                      style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],

                // Date Modified
                if (isDesktop) ...[
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 130,
                    child: Text(
                      file.formattedDate,
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
                    ),
                  ),
                ],

                // Action Buttons
                if (isDesktop) ...[
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 15, color: Color(0xFF94A3B8)),
                        tooltip: 'Copy path',
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                        onPressed: () => _copyFilePath(file.path),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.folder_open_rounded, size: 16, color: Color(0xFF94A3B8)),
                        tooltip: 'Reveal in folder',
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                        onPressed: () => _revealInFolder(file.path),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HomeScreen.aviontiOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: const Size(0, 30),
                        ),
                        icon: const Icon(Icons.edit_note_rounded, size: 16),
                        label: const Text('Open & Edit', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        onPressed: () => _openFilePath(file.path),
                      ),
                    ],
                  ),
                ] else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HomeScreen.aviontiOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 30),
                    ),
                    onPressed: () => _openFilePath(file.path),
                    child: const Text('Open', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.slideshow_rounded, size: 36, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            Text(
              _searchQuery.isNotEmpty ? 'No files match "$_searchQuery"' : 'No PowerPoint presentations detected in storage',
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Checked Desktop, Documents, Downloads & workspace subfolders.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickAndOpenFile,
              style: ElevatedButton.styleFrom(backgroundColor: HomeScreen.aviontiOrange),
              icon: const Icon(Icons.folder_open_rounded, size: 18),
              label: const Text('Browse for .pptx File'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // MOBILE BODY
  // ==========================================
  Widget _buildMobileBody() {
    return Column(
      children: [
        // Top Action Area
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF1E293B),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _createNewBlankPresentation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HomeScreen.aviontiOrange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('New Slide', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickAndOpenFile,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF38BDF8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.folder_open_rounded, color: Color(0xFF38BDF8), size: 18),
                  label: const Text('Open PPT', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),

        // Bottom Half: Dedicated List View
        Expanded(
          child: _buildBottomHalfPptListView(isDesktop: false),
        ),
      ],
    );
  }
}
