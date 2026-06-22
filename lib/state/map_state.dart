import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:mc_map_viewer/domain/biome_color_map.dart';

class TileData {
  final ui.Image image;
  final ByteData rgbaBytes;

  TileData({required this.image, required this.rgbaBytes});
}

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

  // Hovered biome name
  String? _hoverBiome;
  String? get hoverBiome => _hoverBiome;

  // LRU cache for tile pixel data (key: "zoom-tx-ty")
  final Map<String, TileData> _tileCache = {};
  static const int maxCacheSize = 100;

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
      _tileCache.clear();
      _hoverBiome = null;
      notifyListeners();
    }
  }

  // Register loaded tile data in the cache
  void registerTile(int tx, int ty, int zoomLevel, TileData tileData) {
    final String key = '$zoomLevel-$tx-$ty';
    if (_tileCache.containsKey(key)) return;

    // Cache eviction (LRU policy)
    if (_tileCache.length >= maxCacheSize) {
      final String oldestKey = _tileCache.keys.first;
      _tileCache.remove(oldestKey);
    }

    _tileCache[key] = tileData;
    
    // If user is currently hovering on this tile, update the biome immediately
    if (_hoverX != null && _hoverZ != null) {
      _updateBiomeForHover(_hoverX!, _hoverZ!);
    }
  }

  // Check if a tile is already loaded/cached
  bool isTileCached(int tx, int ty, int zoomLevel) {
    return _tileCache.containsKey('$zoomLevel-$tx-$ty');
  }

  // Get cached TileData
  TileData? getCachedTile(int tx, int ty, int zoomLevel) {
    return _tileCache['$zoomLevel-$tx-$ty'];
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

    final int x = (_centerX + (localPosition.dx - halfW) * s).floor();
    final int z = (_centerZ + (localPosition.dy - halfH) * s).floor();

    _hoverX = x;
    _hoverZ = z;

    _updateBiomeForHover(x, z);
    notifyListeners();
  }

  // Extract pixel color from the tile and find the closest biome name
  void _updateBiomeForHover(int x, int z) {
    final int zInt = integerZoom;
    final double tileSizeInBlocks = getTileSizeInBlocks(zInt);
    
    final int tx = (x / tileSizeInBlocks).floor();
    final int ty = (z / tileSizeInBlocks).floor();

    final String key = '$zInt-$tx-$ty';
    final TileData? tileData = _tileCache[key];

    if (tileData != null) {
      // Offset from tile top-left in blocks
      final double dx = x - tx * tileSizeInBlocks;
      final double dz = z - ty * tileSizeInBlocks;

      // Scale (blocks per pixel) inside the tile
      final double scaleAtZ = tileSizeInBlocks / 256.0;

      // Pixel coordinates (0 to 255)
      final int px = (dx / scaleAtZ).floor().clamp(0, 255);
      final int py = (dz / scaleAtZ).floor().clamp(0, 255);

      final int offset = (py * 256 + px) * 4;

      if (offset + 2 < tileData.rgbaBytes.lengthInBytes) {
        final int r = tileData.rgbaBytes.getUint8(offset);
        final int g = tileData.rgbaBytes.getUint8(offset + 1);
        final int b = tileData.rgbaBytes.getUint8(offset + 2);
        
        _hoverBiome = BiomeColorMap.getBiomeNameByColor(r, g, b);
      } else {
        _hoverBiome = null;
      }
    } else {
      _hoverBiome = null;
    }
  }

  // Clear hover coordinates when the mouse leaves the area
  void clearHover() {
    _hoverX = null;
    _hoverZ = null;
    _hoverBiome = null;
    notifyListeners();
  }

  // Animate map center back to (0, 0)
  void centerOnSpawn(TickerProvider vsync) {
    _centerX = 0.0;
    _centerZ = 0.0;
    _zoom = 2.0;
    notifyListeners();
  }
}
