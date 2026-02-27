import 'package:flutter/material.dart';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';

// Exported so the Bottom Sheet can use these colors for the Vector Math
final List<Map<String, dynamic>> plutchikEmotions = [
  {'name': 'JOY', 'color': const Color(0xFFFFD700)},
  {'name': 'TRUST', 'color': const Color(0xFF90EE90)},
  {'name': 'FEAR', 'color': const Color(0xFF228B22)},
  {'name': 'SURPRISE', 'color': const Color(0xFF87CEEB)},
  {'name': 'SADNESS', 'color': const Color(0xFF4169E1)},
  {'name': 'DISGUST', 'color': const Color(0xFF9370DB)},
  {'name': 'ANGER', 'color': const Color(0xFFFF4500)},
  {'name': 'ANTICIP', 'color': const Color(0xFFFFA500)},
];

class EmotionPicker extends StatefulWidget {
  final Function(List<double>) onChanged;

  const EmotionPicker({super.key, required this.onChanged});

  @override
  State<EmotionPicker> createState() => _EmotionPickerState();
}

class _EmotionPickerState extends State<EmotionPicker> {
  List<double> intensities = List.filled(8, 0.0);

  void _handleDrag(Offset localPosition, Size size) {
    Offset center = Offset(size.width / 2, size.height / 2);
    double dx = localPosition.dx - center.dx;
    double dy = localPosition.dy - center.dy;

    double angle = atan2(dy, dx);
    if (angle < 0) angle += 2 * pi;

    double sliceAngle = (2 * pi) / 8;
    double adjustedAngle = (angle + sliceAngle / 2) % (2 * pi);
    int petalIndex = (adjustedAngle / sliceAngle).floor();

    double distance = sqrt(dx * dx + dy * dy);
    double maxRadius = size.width / 2;
    double minRadius = maxRadius * 0.62; // Increased dormant size

    double rawIntensity = (distance - minRadius) / (maxRadius - minRadius);
    double newIntensity = rawIntensity.clamp(0.0, 1.0);

    setState(() {
      intensities[petalIndex] = newIntensity;
    });

    // Send the updated data back to the parent!
    widget.onChanged(intensities);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        Size widgetSize = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          onPanUpdate: (details) =>
              _handleDrag(details.localPosition, widgetSize),
          onTapDown: (details) =>
              _handleDrag(details.localPosition, widgetSize),
          child: CustomPaint(
            size: widgetSize,
            painter: PetalPainter(intensities: intensities),
          ),
        );
      },
    );
  }
}

class PetalPainter extends CustomPainter {
  final List<double> intensities;
  PetalPainter({required this.intensities});

  @override
  void paint(Canvas canvas, Size size) {
    Offset center = Offset(size.width / 2, size.height / 2);
    double maxRadius = size.width / 2;
    double minRadius = maxRadius * 0.62;
    double sliceAngle = (2 * pi) / 8;

    // 1. THE COLOR FIX: A much paler, dull slate-gray for resting petals
    Color restingColor = const Color(0xFF383842);

    for (int i = 0; i < 8; i++) {
      double startAngle = (i * sliceAngle) - (sliceAngle / 2);
      double intensity = intensities[i];

      double currentRadius = minRadius + ((maxRadius - minRadius) * intensity);
      Color? currentColor = Color.lerp(
        restingColor,
        plutchikEmotions[i]['color'],
        intensity,
      );

      Paint paint = Paint()
        ..color = currentColor ?? restingColor
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: currentRadius),
        startAngle,
        sliceAngle,
        true,
        paint,
      );

      // 2. THE BORDER FIX: Lightened the borders so they don't fade into the void
      Paint borderPaint = Paint()
        ..color = const Color(0xFF1E1E26)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: currentRadius),
        startAngle,
        sliceAngle,
        true,
        borderPaint,
      );

      double midAngle = i * sliceAngle;
      double textRadius = currentRadius * 0.86;

      double textX = center.dx + textRadius * cos(midAngle);
      double textY = center.dy + textRadius * sin(midAngle);

      // 3. THE TEXT FIX: Bumped the dormant text to 85% opacity so it's highly readable
      TextSpan span = TextSpan(
        style: GoogleFonts.inter(
          color: intensity > 0.4
              ? Colors.black87
              : Colors.white.withOpacity(0.85),
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
        text: plutchikEmotions[i]['name'],
      );

      TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      tp.layout();

      Offset textOffset = Offset(
        textX - (tp.width / 2),
        textY - (tp.height / 2),
      );

      canvas.save();
      canvas.translate(
        textOffset.dx + (tp.width / 2),
        textOffset.dy + (tp.height / 2),
      );

      double rotationAngle = midAngle;
      if (midAngle > pi / 2 && midAngle < 3 * pi / 2) {
        rotationAngle += pi;
      }

      canvas.rotate(rotationAngle);
      canvas.translate(
        -(textOffset.dx + (tp.width / 2)),
        -(textOffset.dy + (tp.height / 2)),
      );
      tp.paint(canvas, textOffset);
      canvas.restore();
    }

    // 4. THE BACKGROUND FIX: Lightened the center hub to match the new palette
    Paint centerPunch = Paint()
      ..color = const Color(0xFF22222A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, maxRadius * 0.45, centerPunch);
  }

  @override
  bool shouldRepaint(covariant PetalPainter oldDelegate) => true;
}
