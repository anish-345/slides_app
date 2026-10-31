import 'slide.dart';

class Presentation {
  final String id;
  String title;
  String author;
  List<Slide> slides;
  double canvasWidth;
  double canvasHeight;
  DateTime createdAt;
  DateTime updatedAt;

  Presentation({
    required this.id,
    this.title = 'New Presentation',
    this.author = 'Avionti User',
    List<Slide>? slides,
    this.canvasWidth = 1920.0,
    this.canvasHeight = 1080.0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : slides = slides ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'slides': slides.map((s) => s.toJson()).toList(),
      'canvasWidth': canvasWidth,
      'canvasHeight': canvasHeight,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Presentation.fromJson(Map<String, dynamic> json) {
    return Presentation(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled Presentation',
      author: json['author'] as String? ?? 'Avionti User',
      slides: (json['slides'] as List<dynamic>?)
              ?.map((s) => Slide.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      canvasWidth: (json['canvasWidth'] as num?)?.toDouble() ?? 1920.0,
      canvasHeight: (json['canvasHeight'] as num?)?.toDouble() ?? 1080.0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }
}
