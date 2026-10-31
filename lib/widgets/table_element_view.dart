import 'package:flutter/material.dart';
import '../models/slide_element.dart';

class TableElementView extends StatefulWidget {
  final SlideElement element;
  final double scale;
  final bool isSelected;
  final void Function(int row, int col, String value) onCellChanged;

  const TableElementView({
    super.key,
    required this.element,
    required this.scale,
    required this.isSelected,
    required this.onCellChanged,
  });

  @override
  State<TableElementView> createState() => _TableElementViewState();
}

class _TableElementViewState extends State<TableElementView> {
  int? _editingRow;
  int? _editingCol;
  late TextEditingController _cellTextController;
  final FocusNode _cellFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _cellTextController = TextEditingController();
  }

  @override
  void dispose() {
    _cellTextController.dispose();
    _cellFocusNode.dispose();
    super.dispose();
  }

  void _startEditing(int r, int c, String currentVal) {
    setState(() {
      _editingRow = r;
      _editingCol = c;
      _cellTextController.text = currentVal;
    });
    _cellFocusNode.requestFocus();
  }

  void _finishEditing() {
    if (_editingRow != null && _editingCol != null) {
      widget.onCellChanged(_editingRow!, _editingCol!, _cellTextController.text);
      setState(() {
        _editingRow = null;
        _editingCol = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final elem = widget.element;
    final scale = widget.scale;
    final rows = elem.tableData;
    final rowCount = rows.length;
    final colCount = rows.isNotEmpty ? rows.first.length : 1;

    // Proportional column weights
    final colFlexes = <int>[];
    for (int c = 0; c < colCount; c++) {
      if (c < elem.tableColWidths.length) {
        colFlexes.add((elem.tableColWidths[c] * 1000).toInt().clamp(100, 5000));
      } else {
        colFlexes.add(1000);
      }
    }

    return Container(
      width: elem.width * scale,
      height: elem.height * scale,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4 * scale),
        border: Border.all(color: Color(elem.tableBorderColor), width: 1.5 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6 * scale,
            offset: Offset(0, 3 * scale),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int r = 0; r < rowCount; r++)
            Expanded(
              child: Row(
                children: [
                  for (int c = 0; c < colCount; c++)
                    Expanded(
                      flex: c < colFlexes.length ? colFlexes[c] : 1000,
                      child: _buildCell(
                        rowIdx: r,
                        colIdx: c,
                        cellText: r < rows.length && c < rows[r].length ? rows[r][c] : '',
                        isHeader: r == 0 && elem.tableHasHeader,
                        isFirstCol: c == 0 && r > 0,
                        elem: elem,
                        scale: scale,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCell({
    required int rowIdx,
    required int colIdx,
    required String cellText,
    required bool isHeader,
    required bool isFirstCol,
    required SlideElement elem,
    required double scale,
  }) {
    final isEditingThisCell = _editingRow == rowIdx && _editingCol == colIdx;

    Color cellBg;
    Color textColor;
    if (isHeader) {
      cellBg = Color(elem.tableHeaderColor);
      textColor = Colors.white;
    } else if (rowIdx % 2 == 1) {
      cellBg = Color(elem.tableRowColor);
      textColor = const Color(0xFF0F172A);
    } else {
      cellBg = Color(elem.tableAltRowColor);
      textColor = const Color(0xFF0F172A);
    }

    final isBold = isHeader || isFirstCol;

    return GestureDetector(
      onDoubleTap: () => _startEditing(rowIdx, colIdx, cellText),
      child: Container(
        decoration: BoxDecoration(
          color: cellBg,
          border: Border.all(
            color: Color(elem.tableBorderColor).withValues(alpha: 0.5),
            width: 0.5 * scale,
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 6 * scale),
        alignment: isHeader ? Alignment.centerLeft : Alignment.centerLeft,
        child: isEditingThisCell
            ? TextField(
                controller: _cellTextController,
                focusNode: _cellFocusNode,
                style: TextStyle(
                  color: textColor,
                  fontSize: (elem.tableFontSize * scale).clamp(9.0, 32.0),
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (_) => _finishEditing(),
                onTapOutside: (_) => _finishEditing(),
              )
            : Text(
                cellText.isEmpty ? '-' : cellText,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: (elem.tableFontSize * scale).clamp(9.0, 32.0),
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                ),
              ),
      ),
    );
  }
}
