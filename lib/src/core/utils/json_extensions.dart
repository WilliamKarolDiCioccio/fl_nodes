import 'package:flutter/widgets.dart';

extension JSONColor on Color {
  static Color fromJson(String rgba) {
    final values =
        rgba.split(',').map((value) => double.parse(value.trim())).toList();

    return Color.fromARGB(
      (values[3] * 255).round(),
      (values[0] * 255).round(),
      (values[1] * 255).round(),
      (values[2] * 255).round(),
    );
  }

  String toJson(Color color) {
    final r = color.red / 255.0;
    final g = color.green / 255.0;
    final b = color.blue / 255.0;
    final a = color.alpha / 255.0;
    return '$r,$g,$b,$a';
  }
}

extension JSONOffset on Offset {
  static Offset fromJson(List<double> json) => Offset(json[0], json[1]);

  List<double> toJson() => [dx, dy];
}

extension JSONRect on Rect {
  static Rect fromJson(Map<String, dynamic> json) {
    return Rect.fromLTWH(
      json['left'] as double,
      json['top'] as double,
      json['width'] as double,
      json['height'] as double,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'left': left,
      'top': top,
      'width': width,
      'height': height,
    };
  }
}
