import 'dart:math' as math;
import 'package:flutter/material.dart';

class MinecraftGridPainter extends CustomPainter {
  final double centerX;
  final double centerZ;
  final double scale;
  final double zoom;

  MinecraftGridPainter({
    required this.centerX,
    required this.centerZ,
    required this.scale,
    required this.zoom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    final double halfW = width / 2.0;
    final double halfH = height / 2.0;

    // Viewport bounds in Minecraft coordinates
    final double xMin = centerX - halfW * scale;
    final double xMax = centerX + halfW * scale;
    final double zMin = centerZ - halfH * scale;
    final double zMax = centerZ + halfH * scale;

    // Dynamic grid spacing calculation based on scale
    // Target spacing is ~180 pixels on screen
    final double targetSpacing = 180.0 * scale;
    final double power = (math.log(targetSpacing) / math.log(2.0)).roundToDouble();
    // Keep spacing at least at chunk level (16 blocks)
    final double spacing = math.pow(2.0, math.max(4.0, power)).toDouble();

    // Paint configurations
    final Paint gridPaint = Paint()
      ..color = const Color(0xFF333333).withValues(alpha: 0.4)
      ..strokeWidth = 1.0;

    final Paint chunkPaint = Paint()
      ..color = const Color(0xFF00FF88).withValues(alpha: 0.08) // Very subtle chunk grid overlay
      ..strokeWidth = 0.5;

    // Origin Axes (X = 0, Z = 0)
    final Paint axisXPaint = Paint()
      ..color = const Color(0xFFFF5555).withValues(alpha: 0.7) // Redstone Red for X-Axis
      ..strokeWidth = 2.0;

    final Paint axisZPaint = Paint()
      ..color = const Color(0xFF55FF55).withValues(alpha: 0.7) // Lime Green for Z-Axis (typically vertical on maps)
      ..strokeWidth = 2.0;

    // 1. Draw Sub-Chunk grid lines (16 blocks) only if zoomed in enough
    if (scale < 4.0) {
      const double chunkSpacing = 16.0;
      final double firstChunkX = (xMin / chunkSpacing).floor() * chunkSpacing;
      final double firstChunkZ = (zMin / chunkSpacing).floor() * chunkSpacing;

      for (double x = firstChunkX; x <= xMax; x += chunkSpacing) {
        if (x == 0.0) continue; // Axis will cover this
        final double sx = halfW + (x - centerX) / scale;
        canvas.drawLine(Offset(sx, 0), Offset(sx, height), chunkPaint);
      }
      for (double z = firstChunkZ; z <= zMax; z += chunkSpacing) {
        if (z == 0.0) continue; // Axis will cover this
        final double sy = halfH + (z - centerZ) / scale;
        canvas.drawLine(Offset(0, sy), Offset(width, sy), chunkPaint);
      }
    }

    // 2. Draw Main Grid Lines
    final double firstX = (xMin / spacing).floor() * spacing;
    final double firstZ = (zMin / spacing).floor() * spacing;

    for (double x = firstX; x <= xMax; x += spacing) {
      if (x == 0.0) continue;
      final double sx = halfW + (x - centerX) / scale;
      canvas.drawLine(Offset(sx, 0), Offset(sx, height), gridPaint);
      
      // Draw labels along the top/bottom boundary
      _drawText(
        canvas,
        '${x.toInt()}',
        Offset(sx + 4, 8),
        color: const Color(0xFF888888),
      );
    }

    for (double z = firstZ; z <= zMax; z += spacing) {
      if (z == 0.0) continue;
      final double sy = halfH + (z - centerZ) / scale;
      canvas.drawLine(Offset(0, sy), Offset(width, sy), gridPaint);

      // Draw labels along the left/right boundary
      _drawText(
        canvas,
        '${z.toInt()}',
        Offset(8, sy + 4),
        color: const Color(0xFF888888),
      );
    }

    // 3. Draw Axis Lines
    // Draw vertical axis (X = 0)
    if (xMin <= 0 && xMax >= 0) {
      final double sx = halfW + (0.0 - centerX) / scale;
      canvas.drawLine(Offset(sx, 0), Offset(sx, height), axisZPaint);
      _drawText(
        canvas,
        'Z-Axis (North/South)',
        Offset(sx + 6, height - 24),
        color: const Color(0xFF55FF55),
        fontSize: 10,
        bold: true,
      );
    }

    // Draw horizontal axis (Z = 0)
    if (zMin <= 0 && zMax >= 0) {
      final double sy = halfH + (0.0 - centerZ) / scale;
      canvas.drawLine(Offset(0, sy), Offset(width, sy), axisXPaint);
      _drawText(
        canvas,
        'X-Axis (East/West)',
        Offset(width - 120, sy - 18),
        color: const Color(0xFFFF5555),
        fontSize: 10,
        bold: true,
      );
    }

    // 4. Draw Center (Spawn) Indicator if visible
    if (xMin <= 0 && xMax >= 0 && zMin <= 0 && zMax >= 0) {
      final double sx = halfW + (0.0 - centerX) / scale;
      final double sy = halfH + (0.0 - centerZ) / scale;

      // Glowing circle at (0,0)
      final Paint spawnPaint = Paint()
        ..color = const Color(0xFF00FF88)
        ..style = PaintingStyle.fill;
      final Paint spawnStroke = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(Offset(sx, sy), 6.0, spawnPaint);
      canvas.drawCircle(Offset(sx, sy), 6.0, spawnStroke);
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    required Color color,
    double fontSize = 9,
    bool bold = false,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          fontFamily: 'monospace',
          shadows: const [
            Shadow(
              color: Colors.black,
              offset: Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant MinecraftGridPainter oldDelegate) {
    return oldDelegate.centerX != centerX ||
        oldDelegate.centerZ != centerZ ||
        oldDelegate.scale != scale ||
        oldDelegate.zoom != zoom;
  }
}
