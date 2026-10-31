import 'slide_element.dart';

class Slide {
  final String id;
  String title;
  int backgroundColor;
  List<int>? backgroundGradient;
  String? backgroundImagePath;
  List<SlideElement> elements;
  String notes;

  Slide({
    required this.id,
    this.title = 'Untitled Slide',
    this.backgroundColor = 0xFFFFFFFF,
    this.backgroundGradient,
    this.backgroundImagePath,
    List<SlideElement>? elements,
    this.notes = '',
  }) : elements = elements ?? [];

  Slide copyWith({
    String? id,
    String? title,
    int? backgroundColor,
    List<int>? backgroundGradient,
    String? backgroundImagePath,
    List<SlideElement>? elements,
    String? notes,
  }) {
    return Slide(
      id: id ?? this.id,
      title: title ?? this.title,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      backgroundImagePath: backgroundImagePath ?? this.backgroundImagePath,
      elements: elements ?? this.elements.map((e) => e.copyWith()).toList(),
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'backgroundColor': backgroundColor,
      'backgroundGradient': backgroundGradient,
      'backgroundImagePath': backgroundImagePath,
      'elements': elements.map((e) => e.toJson()).toList(),
      'notes': notes,
    };
  }

  factory Slide.fromJson(Map<String, dynamic> json) {
    return Slide(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled Slide',
      backgroundColor: (json['backgroundColor'] as num?)?.toInt() ?? 0xFFFFFFFF,
      backgroundGradient: (json['backgroundGradient'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      backgroundImagePath: json['backgroundImagePath'] as String?,
      elements: (json['elements'] as List<dynamic>?)
              ?.map((e) => SlideElement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      notes: json['notes'] as String? ?? '',
    );
  }
}
