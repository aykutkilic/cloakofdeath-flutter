import 'package:flutter/material.dart';

/// Hand-drawn inventory symbols on a 32-unit grid. Shared by every item surface.
/// Material colors reinforce identity; silhouettes also distinguish item states.
class InventoryIconPainter extends CustomPainter {
  const InventoryIconPainter(this.object);

  final String object;

  static const supportedObjects = {
    'BALL',
    'BAR',
    'BAR PIECES',
    'BIBLE',
    'BOOK',
    'WINE',
    'BREAD',
    'CANDLE',
    'LIT CANDLE',
    'CHAIR',
    'CHEST',
    'COAL',
    'CRUCIFIX',
    'GOBLET',
    'WATER',
    'GOBLET OF WATER',
    'HOLY WATER',
    'HAMMER',
    'IRON',
    'KEY',
    'GATE KEY',
    'KNIFE',
    'LETTER',
    'MATCHES',
    'PAINTING',
    'RAG',
    'SAW',
    'WIRE',
  };

  static const brass = Color(0xFFE0BB7A);
  static const metal = Color(0xFFB9CCCA);
  static const paper = Color(0xFFECE0C3);
  static const teal = Color(0xFF81B7A8);
  static const leather = Color(0xFFAB7162);
  static const ink = Color(0xFF293D38);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 32, size.height / 32);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    void line(List<double> points, [Color color = brass]) {
      final path = Path()..moveTo(points[0], points[1]);
      for (var i = 2; i < points.length; i += 2) {
        path.lineTo(points[i], points[i + 1]);
      }
      canvas.drawPath(path, stroke..color = color);
    }

    void shape(List<double> points, Color fill, [Color edge = brass]) {
      final path = Path()..moveTo(points[0], points[1]);
      for (var i = 2; i < points.length; i += 2) {
        path.lineTo(points[i], points[i + 1]);
      }
      path.close();
      canvas.drawPath(path, Paint()..color = fill);
      canvas.drawPath(path, stroke..color = edge);
    }

    void box(
      double x,
      double y,
      double w,
      double h,
      Color fill, [
      Color edge = brass,
    ]) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h),
        const Radius.circular(2),
      );
      canvas.drawRRect(rect, Paint()..color = fill);
      canvas.drawRRect(rect, stroke..color = edge);
    }

    void circle(
      double x,
      double y,
      double radius,
      Color fill, [
      Color edge = brass,
    ]) {
      canvas.drawCircle(Offset(x, y), radius, Paint()..color = fill);
      canvas.drawCircle(Offset(x, y), radius, stroke..color = edge);
    }

    switch (object) {
      case 'BIBLE':
      case 'BOOK':
        box(7, 5, 19, 23, paper);
        box(6, 4, 19, 21, object == 'BIBLE' ? leather : ink);
        line([10, 5, 10, 24]);
        if (object == 'BIBLE') {
          line([18, 9, 18, 19], paper);
          line([14, 13, 22, 13], paper);
        } else {
          line([14, 11, 21, 11]);
          line([14, 16, 19, 16]);
        }
      case 'CANDLE':
      case 'LIT CANDLE':
        line([7, 28, 25, 28]);
        box(12, 13, 8, 13, paper);
        line([13, 17, 15, 17, 15, 20], leather);
        line([16, 10, 16, 13], paper);
        if (object == 'LIT CANDLE') {
          final flame = Path()
            ..moveTo(17, 2)
            ..cubicTo(17, 6, 22, 8, 18, 11)
            ..cubicTo(12, 14, 11, 8, 17, 2);
          canvas.drawPath(flame, Paint()..color = brass);
          line([16, 8, 16, 10], paper);
        }
      case 'KEY':
        circle(10, 10, 5, ink);
        line([14, 14, 26, 26, 28, 23]);
        line([22, 22, 25, 19]);
      case 'GATE KEY':
        box(10, 3, 12, 10, ink);
        line([16, 7, 16, 28]);
        line([16, 22, 25, 22, 25, 27, 21, 27, 21, 25]);
      case 'BAR':
        shape([6, 24, 23, 5, 27, 8, 10, 27], ink, metal);
        line([10, 23, 23, 9], metal);
      case 'BAR PIECES':
        shape([4, 23, 12, 14, 16, 17, 8, 27], ink, metal);
        shape([17, 12, 24, 4, 28, 7, 21, 15], ink, metal);
        line([6, 8, 10, 10], brass);
        line([21, 23, 25, 25], brass);
      case 'CRUCIFIX':
        shape([
          13,
          3,
          19,
          3,
          19,
          11,
          26,
          11,
          26,
          16,
          19,
          16,
          19,
          29,
          13,
          29,
          13,
          16,
          6,
          16,
          6,
          11,
          13,
          11,
        ], ink);
        line([16, 7, 16, 24], paper);
      case 'GOBLET':
      case 'GOBLET OF WATER':
      case 'HOLY WATER':
        shape([7, 7, 25, 7, 23, 17, 19, 21, 13, 21, 9, 17], ink);
        if (object != 'GOBLET') {
          shape([10, 12, 22, 12, 20, 17, 17, 19, 14, 18], teal, teal);
        }
        line([16, 21, 16, 28]);
        line([10, 28, 22, 28]);
        if (object == 'HOLY WATER') {
          line([26, 2, 26, 10], paper);
          line([23, 5, 29, 5], paper);
        }
      case 'WATER':
        final drop = Path()
          ..moveTo(16, 4)
          ..cubicTo(13, 11, 6, 15, 8, 22)
          ..cubicTo(11, 31, 24, 29, 25, 21)
          ..cubicTo(25, 16, 19, 10, 16, 4);
        canvas.drawPath(drop, Paint()..color = teal);
        line([12, 19, 12, 23, 15, 25], paper);
      case 'WINE':
        box(13, 3, 6, 8, ink, teal);
        shape([13, 10, 19, 10, 23, 16, 23, 28, 9, 28, 9, 16], ink, teal);
        box(10, 18, 12, 7, paper, paper);
        circle(16, 21.5, 2, leather, leather);
      case 'HAMMER':
        shape([13, 13, 18, 14, 15, 29, 11, 28], leather);
        shape([7, 5, 24, 8, 27, 13, 21, 12, 20, 16, 6, 12], ink, metal);
      case 'SAW':
        shape(
          [
            11,
            10,
            28,
            21,
            25,
            24,
            22,
            22,
            20,
            24,
            17,
            21,
            15,
            23,
            12,
            20,
            10,
            21,
            6,
            17,
          ],
          metal,
          metal,
        );
        box(4, 6, 10, 12, leather);
        line([8, 10, 10, 10, 10, 14, 8, 14], ink);
      case 'KNIFE':
        shape([7, 21, 23, 4, 24, 13, 13, 25], metal, metal);
        shape([5, 24, 9, 20, 14, 25, 10, 29], leather);
      case 'IRON':
        shape([5, 12, 20, 7, 28, 12, 27, 23, 12, 28, 5, 22], ink, metal);
        line([5, 12, 12, 17, 28, 12], metal);
        line([12, 17, 12, 28], metal);
      case 'COAL':
        shape([4, 22, 8, 11, 15, 6, 24, 9, 28, 21, 21, 27, 10, 27], ink, metal);
        line([8, 11, 16, 15, 24, 9], metal);
        line([16, 15, 13, 23, 21, 27], metal);
      case 'BREAD':
        final loaf = Path()
          ..moveTo(5, 24)
          ..lineTo(4, 17)
          ..cubicTo(4, 4, 28, 4, 28, 17)
          ..lineTo(27, 24)
          ..close();
        canvas.drawPath(loaf, Paint()..color = brass);
        line([10, 12, 8, 17], leather);
        line([17, 10, 14, 17], leather);
        line([23, 12, 21, 17], leather);
        line([7, 22, 25, 22], leather);
      case 'LETTER':
        shape([4, 8, 28, 8, 28, 25, 4, 25], paper, paper);
        line([5, 9, 16, 18, 27, 9], leather);
        line([5, 24, 12, 17], leather);
        line([27, 24, 20, 17], leather);
        circle(16, 18, 2.5, leather, leather);
      case 'MATCHES':
        box(5, 11, 16, 17, leather);
        box(7, 16, 12, 7, paper, paper);
        line([11, 18, 15, 21], leather);
        line([24, 23, 26, 6], paper);
        circle(26, 5, 2, leather, leather);
      case 'PAINTING':
        box(3, 5, 26, 23, leather);
        box(6, 8, 20, 17, ink);
        circle(21, 12, 2, paper, paper);
        shape([8, 23, 13, 15, 18, 20, 21, 17, 24, 23], teal, teal);
      case 'RAG':
        shape(
          [9, 5, 26, 8, 23, 17, 26, 26, 17, 24, 11, 28, 5, 24, 8, 16],
          paper,
          paper,
        );
        line([13, 9, 11, 21, 15, 23], leather);
        line([20, 11, 18, 19], leather);
      case 'WIRE':
        final wire = Path()
          ..moveTo(4, 25)
          ..lineTo(10, 25)
          ..cubicTo(29, 25, 29, 7, 17, 7)
          ..cubicTo(3, 7, 4, 23, 16, 23)
          ..cubicTo(27, 23, 27, 11, 17, 11)
          ..cubicTo(9, 11, 9, 19, 17, 19)
          ..lineTo(28, 19);
        canvas.drawPath(wire, stroke..color = metal);
      case 'BALL':
        circle(16, 16, 11, leather);
        final seam = Path()
          ..moveTo(9, 7)
          ..quadraticBezierTo(24, 14, 23, 25);
        canvas.drawPath(seam, stroke..color = paper);
        line([6, 20, 26, 12], paper);
      case 'CHAIR':
        box(9, 4, 14, 13, ink);
        line([13, 7, 13, 14]);
        line([19, 7, 19, 14]);
        shape([9, 17, 23, 17, 27, 22, 5, 22], leather);
        line([7, 23, 7, 29]);
        line([25, 23, 25, 29]);
      case 'CHEST':
        box(4, 8, 24, 20, leather);
        line([4, 16, 28, 16]);
        line([9, 9, 9, 27]);
        line([23, 9, 23, 27]);
        box(14, 14, 4, 7, ink);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(InventoryIconPainter oldDelegate) =>
      object != oldDelegate.object;
}
