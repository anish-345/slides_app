import 'package:flutter/material.dart';
import '../models/slide_element.dart';

class TextElementView extends StatefulWidget {
  final SlideElement element;
  final double scale;
  final bool isEditing;
  final ValueChanged<String> onTextChanged;
  final VoidCallback? onEditingComplete;

  const TextElementView({
    super.key,
    required this.element,
    required this.scale,
    required this.isEditing,
    required this.onTextChanged,
    this.onEditingComplete,
  });

  @override
  State<TextElementView> createState() => _TextElementViewState();
}

class _TextElementViewState extends State<TextElementView> {
  late TextEditingController _textController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.element.text);
    _focusNode = FocusNode();
    if (widget.isEditing) {
      _focusNode.requestFocus();
    }
  }

  @override
  void didUpdateWidget(covariant TextElementView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEditing && !oldWidget.isEditing) {
      _textController.text = widget.element.text;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
      _focusNode.requestFocus();
    } else if (!widget.isEditing && widget.element.text != _textController.text) {
      _textController.text = widget.element.text;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  TextStyle _buildTextStyle() {
    return TextStyle(
      fontSize: widget.element.fontSize * widget.scale,
      fontWeight: widget.element.isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: widget.element.isItalic ? FontStyle.italic : FontStyle.normal,
      decoration: widget.element.isUnderline ? TextDecoration.underline : TextDecoration.none,
      color: Color(widget.element.textColor),
      height: 1.25,
    );
  }

  @override
  Widget build(BuildContext context) {
    final elem = widget.element;
    final scale = widget.scale;
    final style = _buildTextStyle();

    final decoration = BoxDecoration(
      color: elem.backgroundColor != null ? Color(elem.backgroundColor!) : null,
      border: elem.borderColor != null && elem.borderWidth > 0
          ? Border.all(
              color: Color(elem.borderColor!),
              width: elem.borderWidth * scale,
            )
          : null,
      borderRadius: BorderRadius.circular(4 * scale),
    );

    if (widget.isEditing) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: elem.width * scale,
            height: elem.height * scale,
            decoration: BoxDecoration(
              color: elem.backgroundColor != null
                  ? Color(elem.backgroundColor!)
                  : Colors.transparent,
              border: Border.all(color: const Color(0xFF0284C7), width: 2),
              borderRadius: BorderRadius.circular(4 * scale),
            ),
            padding: EdgeInsets.all(8 * scale),
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              maxLines: null,
              expands: true,
              style: style.copyWith(
                color: Color(elem.textColor),
              ),
              cursorColor: const Color(0xFF0284C7),
              textAlign: elem.dartTextAlign,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (text) {
                widget.onTextChanged(text);
              },
              onEditingComplete: widget.onEditingComplete,
            ),
          ),
          // Floating "Done Editing" badge above the text box
          Positioned(
            top: -32,
            left: 0,
            child: Material(
              color: const Color(0xFF0284C7),
              borderRadius: BorderRadius.circular(6),
              elevation: 4,
              child: InkWell(
                onTap: widget.onEditingComplete,
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Done Editing',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Render multi-paragraph rich layout if paragraphs exist
    if (elem.paragraphs.isNotEmpty) {
      return Container(
        width: elem.width * scale,
        height: elem.height * scale,
        decoration: decoration,
        padding: EdgeInsets.all(8 * scale),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final p in elem.paragraphs)
                Padding(
                  padding: EdgeInsets.only(bottom: (p.spaceAfter * scale).clamp(2.0, 16.0)),
                  child: p.runs.isNotEmpty
                      ? RichText(
                          textAlign: _getTextAlign(p.textAlign),
                          text: TextSpan(
                            children: [
                              for (final run in p.runs)
                                TextSpan(
                                  text: run.text,
                                  style: TextStyle(
                                    fontSize: (run.fontSize * scale).clamp(8.0, 120.0),
                                    fontWeight: run.isBold ? FontWeight.bold : FontWeight.normal,
                                    fontStyle: run.isItalic ? FontStyle.italic : FontStyle.normal,
                                    decoration: run.isUnderline ? TextDecoration.underline : TextDecoration.none,
                                    color: Color(run.textColor),
                                    height: 1.25,
                                  ),
                                ),
                            ],
                          ),
                        )
                      : Text(
                          p.text,
                          textAlign: _getTextAlign(p.textAlign),
                          style: TextStyle(
                            fontSize: (p.fontSize * scale).clamp(10.0, 120.0),
                            fontWeight: p.isBold ? FontWeight.bold : FontWeight.normal,
                            fontStyle: p.isItalic ? FontStyle.italic : FontStyle.normal,
                            decoration: p.isUnderline ? TextDecoration.underline : TextDecoration.none,
                            color: Color(p.textColor),
                            height: 1.25,
                          ),
                        ),
                ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: elem.width * scale,
      height: elem.height * scale,
      decoration: decoration,
      padding: EdgeInsets.all(8 * scale),
      alignment: _getAlignment(elem.dartTextAlign),
      child: Text(
        elem.text.isEmpty ? 'Empty text' : elem.text,
        style: style,
        textAlign: elem.dartTextAlign,
        overflow: TextOverflow.visible,
      ),
    );
  }

  TextAlign _getTextAlign(String align) {
    switch (align) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'justify':
        return TextAlign.justify;
      default:
        return TextAlign.left;
    }
  }

  Alignment _getAlignment(TextAlign align) {
    switch (align) {
      case TextAlign.center:
        return Alignment.center;
      case TextAlign.right:
        return Alignment.centerRight;
      default:
        return Alignment.centerLeft;
    }
  }
}
