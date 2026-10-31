import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/presentation_controller.dart';
import 'slide_thumbnail_view.dart';

class PresentationModeView extends StatefulWidget {
  final PresentationController controller;

  const PresentationModeView({
    super.key,
    required this.controller,
  });

  @override
  State<PresentationModeView> createState() => _PresentationModeViewState();
}

class _PresentationModeViewState extends State<PresentationModeView> {
  late int _slideIndex;
  bool _showOverlay = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _slideIndex = widget.controller.currentSlideIndex;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _nextSlide() {
    if (_slideIndex < widget.controller.presentation.slides.length - 1) {
      setState(() => _slideIndex++);
    }
  }

  void _prevSlide() {
    if (_slideIndex > 0) {
      setState(() => _slideIndex--);
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.arrowDown ||
        event.logicalKey == LogicalKeyboardKey.space ||
        event.logicalKey == LogicalKeyboardKey.pageDown) {
      _nextSlide();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.arrowUp ||
        event.logicalKey == LogicalKeyboardKey.pageUp) {
      _prevSlide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final slides = widget.controller.presentation.slides;
    final currentSlide = slides[_slideIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: MouseRegion(
          onHover: (_) {
            if (!_showOverlay) setState(() => _showOverlay = true);
          },
          onExit: (_) {
            if (_showOverlay) setState(() => _showOverlay = false);
          },
          child: GestureDetector(
            onTapDown: (details) {
              final screenWidth = MediaQuery.of(context).size.width;
              if (details.globalPosition.dx > screenWidth * 0.7) {
                _nextSlide();
              } else if (details.globalPosition.dx < screenWidth * 0.3) {
                _prevSlide();
              } else {
                setState(() => _showOverlay = !_showOverlay);
              }
            },
            onHorizontalDragEnd: (details) {
              if ((details.primaryVelocity ?? 0) < -100) {
                _nextSlide();
              } else if ((details.primaryVelocity ?? 0) > 100) {
                _prevSlide();
              }
            },
            child: Stack(
              children: [
                // Slide Canvas
                Center(
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                      child: SlideThumbnailView(
                        key: ValueKey(currentSlide.id),
                        slide: currentSlide,
                        width: 1920,
                        height: 1080,
                      ),
                    ),
                  ),
                ),

                // Floating Overlay Controls
                if (_showOverlay)
                  Positioned(
                    bottom: 24,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xCC0F172A),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black45,
                              blurRadius: 16,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_rounded,
                                  color: Colors.white, size: 18),
                              onPressed: _slideIndex > 0 ? _prevSlide : null,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                '${_slideIndex + 1} / ${slides.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward_ios_rounded,
                                  color: Colors.white, size: 18),
                              onPressed: _slideIndex < slides.length - 1 ? _nextSlide : null,
                            ),
                            const SizedBox(width: 8),
                            Container(width: 1, height: 20, color: Colors.white24),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  color: Colors.white, size: 20),
                              tooltip: 'Exit (Esc)',
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
