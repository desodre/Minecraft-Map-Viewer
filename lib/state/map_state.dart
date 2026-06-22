import 'dart:math' as math;
import 'package:flutter/material.dart';

class MapState extends ChangeNotifier {
  // World Seed
  String _seed = '1234567890';
  String get seed => _seed;

  // Center position of the map viewport in Minecraft coordinates (X, Z)
  double _centerX = 0.0;
  double _centerZ = 0.0;
  double get centerX => _centerX;
  double get centerZ => _centerZ;

  // Zoom level. Represents the detail level.
  // Higher zoom = closer look (fewer blocks per pixel).
  // Lower zoom = wider look (more blocks per pixel).
  double _zoom = 2.0;
  double get zoom => _zoom;

  // Minimum and maximum zoom levels
  final double minZoom = -6.0;
  final double maxZoom = 10.0;

  // Default depth factor for scaling.
  // At zoom = 4.0, scale is 1.0 (1 pixel = 1 block).
  static const double defaultDepth = 4.0;

  // Hovered Minecraft coordinate (X, Z)
  int? _hoverX;
  int? _hoverZ;
  int? get hoverX => _hoverX;
  int? get hoverZ => _hoverZ;

  // Scale: number of blocks represented by 1 screen pixel
  double get scale => math.pow(2.0, defaultDepth - _zoom).toDouble();

  // Nearest integer zoom level for loading tiles
  int get integerZoom => _zoom.round();

  // Width of a tile in Minecraft blocks at the current integer zoom level
  double getTileSizeInBlocks(int z) {
    // 256 pixels * (blocks per pixel at zoom z)
    final double scaleAtZ = math.pow(2.0, defaultDepth - z).toDouble();
    return 256.0 * scaleAtZ;
  }

  void setSeed(String value) {
    if (_seed != value) {
      _seed = value.trim();
      notifyListeners();
    }
  }

  // Pan the map center by a pixel delta (dx, dy)
  void pan(double dx, double dy) {
    final double s = scale;
    _centerX -= dx * s;
    _centerZ -= dy * s;
    notifyListeners();
  }

  // Set absolute center
  void setCenter(double x, double z) {
    _centerX = x;
    _centerZ = z;
    notifyListeners();
  }

  // Zoom relative to the screen focal point
  void updateZoom(double zoomDelta, Offset focalPoint, Size viewportSize) {
    final double oldScale = scale;
    
    // Clamp zoom level
    _zoom = (_zoom + zoomDelta).clamp(minZoom, maxZoom);
    
    final double newScale = scale;
    
    // Zoom focus logic: adjust center so the Minecraft coordinate under the focal point remains stable
    final double halfW = viewportSize.width / 2.0;
    final double halfH = viewportSize.height / 2.0;
    
    final double xOffsetFromCenter = focalPoint.dx - halfW;
    final double zOffsetFromCenter = focalPoint.dy - halfH;
    
    _centerX += xOffsetFromCenter * (oldScale - newScale);
    _centerZ += zOffsetFromCenter * (oldScale - newScale);
    
    notifyListeners();
  }

  // Set absolute zoom
  void setZoom(double value) {
    _zoom = value.clamp(minZoom, maxZoom);
    notifyListeners();
  }

  // Update hover position on the screen
  void updateHover(Offset localPosition, Size viewportSize) {
    final double s = scale;
    final double halfW = viewportSize.width / 2.0;
    final double halfH = viewportSize.height / 2.0;

    _hoverX = (_centerX + (localPosition.dx - halfW) * s).floor();
    _hoverZ = (_centerZ + (localPosition.dy - halfH) * s).floor();
    notifyListeners();
  }

  // Clear hover coordinates when the mouse leaves the area
  void clearHover() {
    _hoverX = null;
    _hoverZ = null;
    notifyListeners();
  }

  // Animate map center back to (0, 0)
  void centerOnSpawn(TickerProvider vsync) {
    // We can run a quick AnimationController to interpolate centerX, centerZ and zoom
    // But to keep map state pure, we will handle the animation in the MapScreen widget
    // by calling setCenter and setZoom incrementally. 
    // We provide this helper to jump there instantly if needed.
    _centerX = 0.0;
    _centerZ = 0.0;
    _zoom = 2.0;
    notifyListeners();
  }
}
