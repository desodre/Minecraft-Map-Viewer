import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mc_map_viewer/state/map_state.dart';
import 'package:mc_map_viewer/widget/minecraft_grid_painter.dart';
import 'package:mc_map_viewer/widget/tile_widget.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  late TextEditingController _seedController;
  late AnimationController _animationController;
  Animation<double>? _centerXAnimation;
  Animation<double>? _centerZAnimation;
  Animation<double>? _zoomAnimation;

  // Track gesture details
  double _lastScale = 1.0;
  Offset _lastFocalPoint = Offset.zero;

  @override
  void initState() {
    super.initState();
    final state = Provider.of<MapState>(context, listen: false);
    _seedController = TextEditingController(text: state.seed);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..addListener(() {
        if (_centerXAnimation != null &&
            _centerZAnimation != null &&
            _zoomAnimation != null) {
          state.setCenter(
            _centerXAnimation!.value,
            _centerZAnimation!.value,
          );
          state.setZoom(_zoomAnimation!.value);
        }
      });
  }

  @override
  void dispose() {
    _seedController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Smoothly animate map camera to a target location and zoom
  void _animateMapTo(double targetX, double targetZ, double targetZoom) {
    final state = Provider.of<MapState>(context, listen: false);
    _centerXAnimation = Tween<double>(
      begin: state.centerX,
      end: targetX,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    ));

    _centerZAnimation = Tween<double>(
      begin: state.centerZ,
      end: targetZ,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    ));

    _zoomAnimation = Tween<double>(
      begin: state.zoom,
      end: targetZoom,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    ));

    _animationController.forward(from: 0.0);
  }

  // Generates a random 64-bit Minecraft seed
  String _generateRandomSeed() {
    final rand = math.Random();
    final int upper = rand.nextInt(2147483647);
    final int lower = rand.nextInt(2147483647);
    final int sign = rand.nextBool() ? 1 : -1;
    final int seedVal = ((upper << 32) | lower) * sign;
    return seedVal.toString();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MapState>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F), // Dark deep background
      body: LayoutBuilder(
        builder: (context, constraints) {
          final Size viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
          final double halfW = viewportSize.width / 2.0;
          final double halfH = viewportSize.height / 2.0;

          // Coordinate calculations
          final double scale = state.scale;
          final int z = state.integerZoom;

          // Get dimensions in blocks of tile at current integer zoom
          final double tileSizeInBlocks = state.getTileSizeInBlocks(z);

          // Boundaries in Minecraft blocks
          final double xMin = state.centerX - halfW * scale;
          final double xMax = state.centerX + halfW * scale;
          final double zMin = state.centerZ - halfH * scale;
          final double zMax = state.centerZ + halfH * scale;

          // Visible tile index bounds
          final int txMin = (xMin / tileSizeInBlocks).floor();
          final int txMax = (xMax / tileSizeInBlocks).floor();
          final int tyMin = (zMin / tileSizeInBlocks).floor();
          final int tyMax = (zMax / tileSizeInBlocks).floor();

          // Generate tile widgets list
          final List<Widget> tileWidgets = [];

          // Render background tiles from previous integer zoom level (stretched/shrunk)
          final int prevZ = state.previousIntegerZoom;
          if (prevZ != z) {
            final double prevTileSizeInBlocks = state.getTileSizeInBlocks(prevZ);

            final int prevTxMin = (xMin / prevTileSizeInBlocks).floor();
            final int prevTxMax = (xMax / prevTileSizeInBlocks).floor();
            final int prevTyMin = (zMin / prevTileSizeInBlocks).floor();
            final int prevTyMax = (zMax / prevTileSizeInBlocks).floor();

            // Clamp bounds to prevent rendering crashes
            final int clampedPrevTxMin = prevTxMin.clamp(prevTxMin, prevTxMin + 25);
            final int clampedPrevTxMax = prevTxMax.clamp(clampedPrevTxMin, clampedPrevTxMin + 25);
            final int clampedPrevTyMin = prevTyMin.clamp(prevTyMin, prevTyMin + 25);
            final int clampedPrevTyMax = prevTyMax.clamp(clampedPrevTyMin, clampedPrevTyMin + 25);

            for (int tx = clampedPrevTxMin; tx <= clampedPrevTxMax; tx++) {
              for (int ty = clampedPrevTyMin; ty <= clampedPrevTyMax; ty++) {
                if (state.isTileCached(tx, ty, prevZ)) {
                  final double tileX = tx * prevTileSizeInBlocks;
                  final double tileZ = ty * prevTileSizeInBlocks;

                  // Screen coordinates at current scale
                  final double screenX = halfW + (tileX - state.centerX) / scale;
                  final double screenZ = halfH + (tileZ - state.centerZ) / scale;
                  final double sizeOnScreen = prevTileSizeInBlocks / scale;

                  tileWidgets.add(
                    Positioned(
                      key: ValueKey('bg-${state.seed}-${state.dimension}-$prevZ-$tx-$ty'),
                      left: screenX,
                      top: screenZ,
                      width: sizeOnScreen + 0.5,
                      height: sizeOnScreen + 0.5,
                      child: TileWidget(
                        key: ValueKey('bg-tile-${state.seed}-${state.dimension}-$prevZ-$tx-$ty'),
                        seed: state.seed,
                        dimension: state.dimension,
                        zoom: prevZ,
                        tx: tx,
                        ty: ty,
                        size: sizeOnScreen,
                      ),
                    ),
                  );
                }
              }
            }
          }
          
          // Clamp bounds to prevent rendering crashes on extreme invalid states
          final int clampedTxMin = txMin.clamp(txMin, txMin + 25);
          final int clampedTxMax = txMax.clamp(clampedTxMin, clampedTxMin + 25);
          final int clampedTyMin = tyMin.clamp(tyMin, tyMin + 25);
          final int clampedTyMax = tyMax.clamp(clampedTyMin, clampedTyMin + 25);

          for (int tx = clampedTxMin; tx <= clampedTxMax; tx++) {
            for (int ty = clampedTyMin; ty <= clampedTyMax; ty++) {
              final double tileX = tx * tileSizeInBlocks;
              final double tileZ = ty * tileSizeInBlocks;

              // Top-left screen coordinate of this tile
              final double screenX = halfW + (tileX - state.centerX) / scale;
              final double screenZ = halfH + (tileZ - state.centerZ) / scale;

              // Size on screen
              final double sizeOnScreen = tileSizeInBlocks / scale;

              tileWidgets.add(
                Positioned(
                  key: ValueKey('fg-${state.seed}-${state.dimension}-$z-$tx-$ty'),
                  left: screenX,
                  top: screenZ,
                  width: sizeOnScreen + 0.5, // Tiny overlap to fix seam lines
                  height: sizeOnScreen + 0.5,
                  child: TileWidget(
                    key: ValueKey('fg-tile-${state.seed}-${state.dimension}-$z-$tx-$ty'),
                    seed: state.seed,
                    dimension: state.dimension,
                    zoom: z,
                    tx: tx,
                    ty: ty,
                    size: sizeOnScreen,
                  ),
                ),
              );
            }
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Map Tiles Layer with Drag, Pinch-Zoom & Scroll gestures
              Listener(
                onPointerSignal: (pointerSignal) {
                  if (pointerSignal is PointerScrollEvent) {
                    final double scrollDelta = pointerSignal.scrollDelta.dy;
                    // dy > 0 means scroll down (zoom out), dy < 0 means scroll up (zoom in)
                    final double zoomDelta = -scrollDelta / 240.0;
                    
                    if (_animationController.isAnimating) {
                      _animationController.stop();
                    }
                    
                    state.updateZoom(
                      zoomDelta,
                      pointerSignal.localPosition,
                      viewportSize,
                    );
                  }
                },
                child: GestureDetector(
                  onScaleStart: (details) {
                    if (_animationController.isAnimating) {
                      _animationController.stop();
                    }
                    _lastScale = 1.0;
                    _lastFocalPoint = details.localFocalPoint;
                  },
                  onScaleUpdate: (details) {
                    // Calculate translation delta
                    final Offset delta = details.localFocalPoint - _lastFocalPoint;
                    _lastFocalPoint = details.localFocalPoint;
                    state.pan(delta.dx, delta.dy);

                    // Calculate zoom delta
                    if (details.scale != 1.0) {
                      final double currentScale = details.scale;
                      final double zoomDelta = (math.log(currentScale) / math.log(2.0)) -
                          (math.log(_lastScale) / math.log(2.0));
                      _lastScale = currentScale;
                      state.updateZoom(zoomDelta, details.localFocalPoint, viewportSize);
                    }
                  },
                  child: MouseRegion(
                    onHover: (event) => state.updateHover(event.localPosition, viewportSize),
                    onExit: (_) => state.clearHover(),
                    cursor: SystemMouseCursors.grab,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Dark empty canvas background
                        Container(color: const Color(0xFF111111)),
                        
                        // Map Slippy Tiles
                        ...tileWidgets,
                        
                        // Custom Painter for axes and grid overlay
                        CustomPaint(
                          painter: MinecraftGridPainter(
                            centerX: state.centerX,
                            centerZ: state.centerZ,
                            scale: scale,
                            zoom: state.zoom,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Crosshair indicator in the center of the screen
              IgnorePointer(
                child: Center(
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF00FF88), width: 1.5),
                    ),
                    child: Center(
                      child: Container(
                        width: 2,
                        height: 2,
                        color: const Color(0xFF00FF88),
                      ),
                    ),
                  ),
                ),
              ),

              // 3. Floating Glassmorphic Top Bar (Seed Editor)
              Positioned(
                top: 20,
                left: 20,
                right: 20,
                child: SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E).withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF00FF88).withValues(alpha: 0.35),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00FF88).withValues(alpha: 0.08),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.map_outlined,
                                          color: Color(0xFF00FF88),
                                          size: 18,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'SEED MAP',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'ZOOM: ${state.zoom.toStringAsFixed(1)}x',
                                      style: TextStyle(
                                        color: const Color(0xFF00FF88).withValues(alpha: 0.8),
                                        fontSize: 10,
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _seedController,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace',
                                        ),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          hintText: 'Digite a Seed (String ou Número)',
                                          hintStyle: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.35),
                                            fontSize: 14,
                                          ),
                                          filled: true,
                                          fillColor: Colors.black.withValues(alpha: 0.3),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                        ),
                                        onSubmitted: (val) => state.setSeed(val),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Generate Random Seed Button
                                    IconButton(
                                      tooltip: 'Seed Aleatória',
                                      icon: const Icon(Icons.casino_outlined, color: Colors.white),
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.all(10),
                                      ),
                                      onPressed: () {
                                        final newSeed = _generateRandomSeed();
                                        _seedController.text = newSeed;
                                        state.setSeed(newSeed);
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    // Apply Seed Button
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF00C853),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                      ),
                                      onPressed: () => state.setSeed(_seedController.text),
                                      child: const Text(
                                        'CARREGAR',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 3.5. Floating Glassmorphic Dimension Selector
              Positioned(
                top: 145,
                left: 20,
                right: 20,
                child: SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E).withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                                width: 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Overworld
                                Expanded(
                                  child: _buildDimensionButton(
                                    context,
                                    label: 'Overworld',
                                    dimensionId: 0,
                                    activeColor: const Color(0xFF00FF88),
                                    icon: Icons.public_rounded,
                                    activeDimension: state.dimension,
                                    onTap: () => state.setDimension(0),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                // Nether
                                Expanded(
                                  child: _buildDimensionButton(
                                    context,
                                    label: 'Nether',
                                    dimensionId: -1,
                                    activeColor: const Color(0xFFFF3D00),
                                    icon: Icons.local_fire_department_rounded,
                                    activeDimension: state.dimension,
                                    onTap: () => state.setDimension(-1),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                // The End
                                Expanded(
                                  child: _buildDimensionButton(
                                    context,
                                    label: 'The End',
                                    dimensionId: 1,
                                    activeColor: const Color(0xFFAA00FF),
                                    icon: Icons.brightness_2_rounded,
                                    activeDimension: state.dimension,
                                    onTap: () => state.setDimension(1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 4. Floating Zoom & Navigation Controls Column
              Positioned(
                bottom: 120,
                right: 20,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Zoom In Button
                    FloatingActionButton.small(
                      heroTag: 'zoom_in',
                      tooltip: 'Aproximar (Zoom In)',
                      backgroundColor: const Color(0xFF1E1E1E),
                      foregroundColor: const Color(0xFF00FF88),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: const Color(0xFF00FF88).withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      onPressed: () {
                        final double targetZoom = (state.zoom + 1.0).clamp(state.minZoom, state.maxZoom);
                        _animateMapTo(state.centerX, state.centerZ, targetZoom);
                      },
                      child: const Icon(Icons.add),
                    ),
                    const SizedBox(height: 8),
                    // Zoom Out Button
                    FloatingActionButton.small(
                      heroTag: 'zoom_out',
                      tooltip: 'Afastar (Zoom Out)',
                      backgroundColor: const Color(0xFF1E1E1E),
                      foregroundColor: const Color(0xFF00FF88),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: const Color(0xFF00FF88).withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      onPressed: () {
                        final double targetZoom = (state.zoom - 1.0).clamp(state.minZoom, state.maxZoom);
                        _animateMapTo(state.centerX, state.centerZ, targetZoom);
                      },
                      child: const Icon(Icons.remove),
                    ),
                    const SizedBox(height: 16),
                    // Center on Spawn Button
                    FloatingActionButton(
                      heroTag: 'center_spawn',
                      tooltip: 'Centralizar no Spawn (0,0)',
                      backgroundColor: const Color(0xFF1E1E1E),
                      foregroundColor: const Color(0xFF00FF88),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFF00FF88), width: 1.5),
                      ),
                      onPressed: () => _animateMapTo(0.0, 0.0, 2.0),
                      child: const Icon(Icons.gps_fixed),
                    ),
                  ],
                ),
              ),

              // 5. Floating Glassmorphic Footer (Coordinates Panel)
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: SafeArea(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E).withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                                width: 1,
                              ),
                            ),
                            child: LayoutBuilder(
                              builder: (context, footerConstraints) {
                                final bool isNarrow = footerConstraints.maxWidth < 580;
                                if (isNarrow) {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          _buildCoordsColumn(state),
                                          _buildChunkColumn(state),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Container(
                                        height: 1,
                                        color: Colors.white.withValues(alpha: 0.08),
                                      ),
                                      const SizedBox(height: 10),
                                      _buildBiomeColumn(state),
                                    ],
                                  );
                                }
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildCoordsColumn(state),
                                    _buildBiomeColumn(state),
                                    _buildChunkColumn(state),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCoordLabel(String axis, int val) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$axis: ',
            style: TextStyle(
              color: axis == 'X' ? const Color(0xFFFF5555) : const Color(0xFF55FF55),
              fontWeight: FontWeight.w900,
              fontSize: 16,
              fontFamily: 'monospace',
            ),
          ),
          TextSpan(
            text: '$val',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  String _getChunkCoord(int val) {
    return (val / 16).floor().toString();
  }

  Widget _buildTextBadge(String label, String xVal, String zVal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $xVal, $zVal',
        style: const TextStyle(
          color: Color(0xFFDDDDDD),
          fontSize: 11,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRegionBadge(int x, int z) {
    final int rx = (x / 512).floor();
    final int rz = (z / 512).floor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF00FF88).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFF00FF88).withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Text(
        'r.$rx.$rz.mca',
        style: const TextStyle(
          color: Color(0xFF00FF88),
          fontSize: 11,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBiomeBadge(String? biome) {
    final String label = biome != null ? biome.toUpperCase().replaceAll('_', ' ') : 'UNKNOWN';
    final bool isKnown = biome != null && biome != 'unknown';
    
    Color badgeColor = const Color(0xFF888888);
    Color textColor = Colors.white;
    
    if (isKnown) {
      final name = biome.toLowerCase();
      if (name.contains('nether') || name.contains('crimson') || name.contains('warped') || name.contains('basalt') || name.contains('valley')) {
        badgeColor = const Color(0xFFD50000); // Nether Crimson Red
      } else if (name.contains('end')) {
        badgeColor = const Color(0xFFAA00FF); // End Void Purple
      } else if (name.contains('ocean') || name.contains('river') || name == 'swamp') {
        badgeColor = const Color(0xFF2979FF); // Blueish
      } else if (name.contains('desert') || name.contains('beach')) {
        badgeColor = const Color(0xFFFFD600); // Yellowish
        textColor = Colors.black;
      } else if (name.contains('forest') || name == 'plains' || name.contains('grove') || name.contains('meadow')) {
        badgeColor = const Color(0xFF00E676); // Emerald Green
      } else if (name.contains('mountain') || name.contains('hills') || name.contains('peaks') || name.contains('slopes')) {
        badgeColor = const Color(0xFFCFD8DC); // Greyish
        textColor = Colors.black;
      } else if (name.contains('badlands')) {
        badgeColor = const Color(0xFFFF3D00); // Orange/Redstone Red
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCoordsColumn(MapState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          state.hoverX != null ? 'CURSOR POSITION' : 'CENTER (LOOKING AT)',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCoordLabel('X', state.hoverX ?? state.centerX.round()),
            const SizedBox(width: 16),
            _buildCoordLabel('Z', state.hoverZ ?? state.centerZ.round()),
          ],
        ),
      ],
    );
  }

  Widget _buildBiomeColumn(MapState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'BIOME',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        _buildBiomeBadge(state.hoverBiome),
      ],
    );
  }

  Widget _buildChunkColumn(MapState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'CHUNK & REGION',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextBadge(
              'Chunk',
              _getChunkCoord(state.hoverX ?? state.centerX.round()),
              _getChunkCoord(state.hoverZ ?? state.centerZ.round()),
            ),
            const SizedBox(width: 8),
            _buildRegionBadge(
              state.hoverX ?? state.centerX.round(),
              state.hoverZ ?? state.centerZ.round(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDimensionButton(
    BuildContext context, {
    required String label,
    required int dimensionId,
    required Color activeColor,
    required IconData icon,
    required int activeDimension,
    required VoidCallback onTap,
  }) {
    final bool isActive = activeDimension == dimensionId;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive 
              ? activeColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive 
                ? activeColor.withValues(alpha: 0.4)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? activeColor : Colors.white.withValues(alpha: 0.5),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
