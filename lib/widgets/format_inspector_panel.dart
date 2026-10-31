import 'package:flutter/material.dart';
import '../controllers/presentation_controller.dart';
import '../models/slide_element.dart';
import '../services/storage_service.dart';

class FormatInspectorPanel extends StatelessWidget {
  final PresentationController controller;

  const FormatInspectorPanel({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final elem = controller.selectedElement;
        if (elem == null) {
          return const SizedBox.shrink();
        }

        return Container(
          width: 250,
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            border: Border(left: BorderSide(color: Color(0xFF1E293B))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getElementTypeName(elem.type),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => controller.selectElement(null),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    // Position & Size Group
                    const Text(
                      'POSITION & SIZE',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: _buildNumberField(
                            label: 'X',
                            value: elem.x.toInt(),
                            onChanged: (v) => controller.setElementPosition(elem.id, v.toDouble(), elem.y),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildNumberField(
                            label: 'Y',
                            value: elem.y.toInt(),
                            onChanged: (v) => controller.setElementPosition(elem.id, elem.x, v.toDouble()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: _buildNumberField(
                            label: 'W',
                            value: elem.width.toInt(),
                            onChanged: (v) => controller.updateElementSize(elem.id, v.toDouble(), elem.height),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildNumberField(
                            label: 'H',
                            value: elem.height.toInt(),
                            onChanged: (v) => controller.updateElementSize(elem.id, elem.width, v.toDouble()),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),
                    const Divider(color: Color(0xFF1E293B)),
                    const SizedBox(height: 10),

                    // Text & Typography Section for Text Elements
                    if (elem.type == ElementType.text) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TEXT CONTENT',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: const Size(0, 26),
                            ),
                            icon: const Icon(Icons.edit, size: 12),
                            label: const Text('Edit Inline', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: () => controller.startEditingText(elem.id),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Direct multi-line text editor with real-time live preview sync
                      _InspectorTextEditor(
                        key: ValueKey(elem.id),
                        element: elem,
                        controller: controller,
                      ),
                      const SizedBox(height: 8),

                      // Real-time live preview status indicator & Save button
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 14),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Live Preview Active • Synced',
                                    style: TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0284C7),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                              icon: const Icon(Icons.save_rounded, size: 14),
                              label: const Text(
                                'Save Changes',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              onPressed: () async {
                                await StorageService.saveRecentPresentation(controller.presentation);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                          SizedBox(width: 8),
                                          Text('Presentation saved successfully!'),
                                        ],
                                      ),
                                      backgroundColor: Color(0xFF059669),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Font size stepper
                      Row(
                        children: [
                          const Text('Font Size', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.remove, size: 14, color: Colors.white),
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            onPressed: () => controller.updateElementFontSize(elem.id, (elem.fontSize - 2).clamp(8.0, 120.0)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${elem.fontSize.toInt()} pt',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 14, color: Colors.white),
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            onPressed: () => controller.updateElementFontSize(elem.id, (elem.fontSize + 2).clamp(8.0, 120.0)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Bold, Italic, Underline toggles & Alignment
                      Row(
                        children: [
                          _buildToggleIcon(
                            icon: Icons.format_bold_rounded,
                            isActive: elem.isBold,
                            onTap: () => controller.toggleElementBold(elem.id),
                          ),
                          const SizedBox(width: 4),
                          _buildToggleIcon(
                            icon: Icons.format_italic_rounded,
                            isActive: elem.isItalic,
                            onTap: () => controller.toggleElementItalic(elem.id),
                          ),
                          const SizedBox(width: 4),
                          _buildToggleIcon(
                            icon: Icons.format_underlined_rounded,
                            isActive: elem.isUnderline,
                            onTap: () => controller.toggleElementUnderline(elem.id),
                          ),
                          const Spacer(),
                          _buildToggleIcon(
                            icon: Icons.format_align_left_rounded,
                            isActive: elem.textAlign == 'left',
                            onTap: () => controller.updateElementTextAlign(elem.id, 'left'),
                          ),
                          const SizedBox(width: 4),
                          _buildToggleIcon(
                            icon: Icons.format_align_center_rounded,
                            isActive: elem.textAlign == 'center',
                            onTap: () => controller.updateElementTextAlign(elem.id, 'center'),
                          ),
                          const SizedBox(width: 4),
                          _buildToggleIcon(
                            icon: Icons.format_align_right_rounded,
                            isActive: elem.textAlign == 'right',
                            onTap: () => controller.updateElementTextAlign(elem.id, 'right'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Color palette swatches
                      const Text(
                        'TEXT COLOR',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final clr in [
                            0xFFFFFFFF,
                            0xFF102C57,
                            0xFF1E56A0,
                            0xFF0284C7,
                            0xFF10B981,
                            0xFFEA580C,
                            0xFFEF4444,
                            0xFF8B5CF6,
                            0xFFF59E0B,
                            0xFF1E293B,
                          ])
                            InkWell(
                              onTap: () => controller.updateElementTextColor(elem.id, clr),
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: Color(clr),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: elem.textColor == clr ? Colors.white : const Color(0xFF475569),
                                    width: elem.textColor == clr ? 2 : 1,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: Color(0xFF1E293B)),
                      const SizedBox(height: 10),
                    ],

                    // Table specific controls
                    if (elem.type == ElementType.table) ...[
                      const Text(
                        'TABLE STRUCTURE',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${elem.tableRows} Rows × ${elem.tableCols} Columns',
                        style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildLayerButton(
                              icon: Icons.add_rounded,
                              label: '+ Row',
                              onTap: () => controller.addTableRow(elem.id),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _buildLayerButton(
                              icon: Icons.remove_rounded,
                              label: '- Row',
                              onTap: () => controller.deleteTableRow(elem.id),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _buildLayerButton(
                              icon: Icons.add_rounded,
                              label: '+ Column',
                              onTap: () => controller.addTableColumn(elem.id),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _buildLayerButton(
                              icon: Icons.remove_rounded,
                              label: '- Column',
                              onTap: () => controller.deleteTableColumn(elem.id),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'HEADER ROW COLOR',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final clr in [
                            0xFF1D4ED8, // Royal Blue
                            0xFF102C57, // Deep Navy
                            0xFF0284C7, // Sky Blue
                            0xFF0F766E, // Teal
                            0xFF7C3AED, // Violet
                            0xFFC43E1C, // Avionti Orange
                            0xFF1E293B, // Slate
                          ])
                            InkWell(
                              onTap: () => controller.updateTableHeaderColor(elem.id, clr),
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: Color(clr),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: elem.tableHeaderColor == clr ? Colors.white : const Color(0xFF475569),
                                    width: elem.tableHeaderColor == clr ? 2 : 1,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Table Font Size',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildMiniIconButton(
                                icon: Icons.remove,
                                tooltip: 'Decrease Table Font',
                                onTap: () => controller.updateTableFontSize(elem.id, elem.tableFontSize - 1),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  '${elem.tableFontSize.toInt()} pt',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              _buildMiniIconButton(
                                icon: Icons.add,
                                tooltip: 'Increase Table Font',
                                onTap: () => controller.updateTableFontSize(elem.id, elem.tableFontSize + 1),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: Color(0xFF1E293B)),
                      const SizedBox(height: 10),
                    ],

                    // Opacity & Layering
                    const Text(
                      'OPACITY',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        value: elem.opacity,
                        min: 0.1,
                        max: 1.0,
                        activeColor: const Color(0xFF38BDF8),
                        inactiveColor: const Color(0xFF334155),
                        onChanged: (v) => controller.updateElementOpacity(elem.id, v),
                      ),
                    ),

                    const SizedBox(height: 10),
                    const Text(
                      'ARRANGE LAYERS',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildLayerButton(
                          icon: Icons.flip_to_front_rounded,
                          label: 'Bring to Front',
                          onTap: () => controller.bringToFront(elem.id),
                        ),
                        _buildLayerButton(
                          icon: Icons.flip_to_back_rounded,
                          label: 'Send to Back',
                          onTap: () => controller.sendToBack(elem.id),
                        ),
                        _buildLayerButton(
                          icon: Icons.copy_rounded,
                          label: 'Duplicate',
                          onTap: () => controller.duplicateElement(elem.id),
                        ),
                        _buildLayerButton(
                          icon: Icons.delete_outline_rounded,
                          label: 'Delete',
                          color: const Color(0xFFEF4444),
                          onTap: () => controller.deleteElement(elem.id),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),
                    const Divider(color: Color(0xFF1E293B)),
                    const SizedBox(height: 10),

                    // Universal Save & Export Presentation
                    const Text(
                      'SAVE & EXPORT',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            icon: const Icon(Icons.save_rounded, size: 14),
                            label: const Text('Save (Ctrl+S)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: () async {
                              await StorageService.saveRecentPresentation(controller.presentation);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                        SizedBox(width: 8),
                                        Text('Presentation saved successfully!'),
                                      ],
                                    ),
                                    backgroundColor: Color(0xFF059669),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF38BDF8),
                              side: const BorderSide(color: Color(0xFF0284C7)),
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            icon: const Icon(Icons.download_rounded, size: 14),
                            label: const Text('Save PPTX', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: () async {
                              final success = await StorageService.exportPptx(controller);
                              if (context.mounted && success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('PPTX exported successfully!'),
                                    backgroundColor: Color(0xFF059669),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getElementTypeName(ElementType type) {
    switch (type) {
      case ElementType.text:
        return 'Text Box Properties';
      case ElementType.image:
        return 'Picture Properties';
      case ElementType.table:
        return 'Table Properties';
      case ElementType.shape:
        return 'Shape Properties';
    }
  }

  Widget _buildNumberField({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$value',
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return IconButton(
      icon: Icon(icon, size: 14, color: Colors.white),
      tooltip: tooltip,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(),
      onPressed: onTap,
    );
  }

  Widget _buildToggleIcon({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: isActive ? const Color(0xFF38BDF8) : const Color(0xFF334155)),
        ),
        child: Icon(icon, size: 16, color: isActive ? Colors.white : const Color(0xFF94A3B8)),
      ),
    );
  }
}

class _InspectorTextEditor extends StatefulWidget {
  final SlideElement element;
  final PresentationController controller;

  const _InspectorTextEditor({
    super.key,
    required this.element,
    required this.controller,
  });

  @override
  State<_InspectorTextEditor> createState() => _InspectorTextEditorState();
}

class _InspectorTextEditorState extends State<_InspectorTextEditor> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.element.text);
  }

  @override
  void didUpdateWidget(covariant _InspectorTextEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.element.id != oldWidget.element.id) {
      _textController.text = widget.element.text;
    } else if (widget.element.text != _textController.text) {
      final currentPos = _textController.selection;
      _textController.text = widget.element.text;
      if (currentPos.start <= widget.element.text.length && currentPos.end <= widget.element.text.length) {
        _textController.selection = currentPos;
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _textController,
      maxLines: 5,
      style: const TextStyle(color: Colors.white, fontSize: 12),
      decoration: InputDecoration(
        hintText: 'Enter text here...',
        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        contentPadding: const EdgeInsets.all(10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF38BDF8)),
        ),
      ),
      onChanged: (val) {
        widget.controller.updateElementText(widget.element.id, val);
      },
    );
  }
}

