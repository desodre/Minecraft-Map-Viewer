import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:mc_map_viewer/state/map_state.dart';

class TileWidget extends StatefulWidget {
  final String seed;
  final int zoom;
  final int tx;
  final int ty;
  final double size;

  const TileWidget({
    super.key,
    required this.seed,
    required this.zoom,
    required this.tx,
    required this.ty,
    required this.size,
  });

  @override
  State<TileWidget> createState() => _TileWidgetState();
}

class _TileWidgetState extends State<TileWidget> {
  bool _isLoading = false;
  bool _hasError = false;
  TileData? _tileData;
  String? _loadedKey;
  bool _shouldAnimate = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadTile();
  }

  @override
  void didUpdateWidget(TileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seed != widget.seed ||
        oldWidget.zoom != widget.zoom ||
        oldWidget.tx != widget.tx ||
        oldWidget.ty != widget.ty) {
      _loadTile();
    }
  }

  Future<void> _loadTile() async {
    final state = Provider.of<MapState>(context, listen: false);
    final String key = '${widget.seed}-${widget.zoom}-${widget.tx}-${widget.ty}';

    // 1. Check if already cached in global MapState
    if (state.isTileCached(widget.tx, widget.ty, widget.zoom)) {
      if (mounted) {
        setState(() {
          _tileData = state.getCachedTile(widget.tx, widget.ty, widget.zoom);
          _isLoading = false;
          _hasError = false;
          _loadedKey = key;
          _shouldAnimate = false; // Loaded from cache, show immediately
        });
      }
      return;
    }

    // 2. Prevent redundant requests if already downloading this tile
    if (_loadedKey == key && (_isLoading || _tileData != null)) {
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _tileData = null;
        _loadedKey = key;
      });
    }

    final String tileUrl =
        'http://localhost:8080/api/v1/map/tile?seed=${widget.seed}&zoom=${widget.zoom}&tx=${widget.tx}&ty=${widget.ty}';

    try {
      final response = await http.get(Uri.parse(tileUrl)).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;

        // Decode bytes to ui.Image
        final ui.Codec codec = await ui.instantiateImageCodec(bytes);
        final ui.FrameInfo frame = await codec.getNextFrame();
        final ui.Image image = frame.image;

        // Extract raw RGBA bytes
        final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        if (byteData == null) {
          throw Exception('Failed to extract image pixel bytes');
        }

        final loadedTileData = TileData(image: image, rgbaBytes: byteData);
        
        // Register in MapState cache
        state.registerTile(widget.tx, widget.ty, widget.zoom, loadedTileData);

        if (mounted && _loadedKey == key) {
          setState(() {
            _tileData = loadedTileData;
            _isLoading = false;
            _hasError = false;
            _shouldAnimate = true; // Fade-in since it is a new download
          });
        }
      } else {
        throw Exception('Server returned status ${response.statusCode}');
      }
    } catch (e) {
      if (mounted && _loadedKey == key) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _tileData = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Checkerboard pattern
          Container(
            decoration: BoxDecoration(
              color: (widget.tx + widget.ty) % 2 == 0
                  ? const Color(0xFF1E1E1E)
                  : const Color(0xFF161616),
              border: Border.all(
                color: const Color(0xFF2E2E2E),
                width: 0.5,
              ),
            ),
            child: Center(
              child: Opacity(
                opacity: 0.15,
                child: Text(
                  '${widget.tx}, ${widget.ty}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ),

          // Render Raw Image if loaded
          if (_tileData != null)
            _shouldAnimate
                ? TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: child,
                      );
                    },
                    child: RawImage(
                      image: _tileData!.image,
                      fit: BoxFit.fill,
                    ),
                  )
                : RawImage(
                    image: _tileData!.image,
                    fit: BoxFit.fill,
                  ),

          // Show Linear Loading bar if downloading
          if (_isLoading)
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFF00FF88),
                ),
                minHeight: 2,
              ),
            ),

          // Show Unloaded Chunk placeholder on error
          if (_hasError)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2C1E1B),
                border: Border.all(
                  color: const Color(0xFFFF4444).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.broken_image_outlined,
                    color: Color(0xFFFF5555),
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'T: ${widget.tx}, ${widget.ty}',
                    style: const TextStyle(
                      color: Color(0xFFFFAAAA),
                      fontSize: 8,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const Text(
                    'UNLOADED',
                    style: TextStyle(
                      color: Color(0xFFFF5555),
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
