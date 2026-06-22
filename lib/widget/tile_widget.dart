import 'package:flutter/material.dart';

class TileWidget extends StatelessWidget {
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

  String get tileUrl =>
      'http://localhost:8080/api/v1/map/tile?seed=$seed&zoom=$zoom&tx=$tx&ty=$ty';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Placeholder: A beautiful dark checkerboard/nether brick-like pattern
          Container(
            decoration: BoxDecoration(
              color: (tx + ty) % 2 == 0
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
                  '$tx, $ty',
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
          
          // Image loader with custom fade-in transition and error state
          Image.network(
            tileUrl,
            fit: BoxFit.fill,
            gaplessPlayback: true,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) return child;
              return AnimatedOpacity(
                opacity: frame == null ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: child,
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              // Show a subtle loading bar overlay
              return Stack(
                fit: StackFit.expand,
                children: [
                  child, // Draw what is loaded so far (if anything)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF00FF88), // Glowing emerald green
                      ),
                      minHeight: 2,
                    ),
                  ),
                ],
              );
            },
            errorBuilder: (context, error, stackTrace) {
              // Failed to load tile from local server.
              // Display a premium Minecraft "Unloaded Chunk" style indicator.
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2C1E1B), // Dark rustic/dirt tone
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
                      'T: $tx, $ty',
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
              );
            },
          ),
        ],
      ),
    );
  }
}
