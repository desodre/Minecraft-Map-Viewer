import 'package:flutter_test/flutter_test.dart';
import 'package:mc_map_viewer/state/map_state.dart';

void main() {
  test('MapState seed and dimension initialization', () {
    final state = MapState();
    expect(state.seed, isNotEmpty);
    expect(state.dimension, equals(0)); // Defaults to Overworld
  });

  test('MapState dimension change clears cache', () {
    final state = MapState();
    state.setDimension(-1); // Nether
    expect(state.dimension, equals(-1));
    
    // Changing dimension should trigger notifications and ensure cache is clear
    state.setDimension(1); // The End
    expect(state.dimension, equals(1));
  });

  test('MapState coordinates and zoom clamping', () {
    final state = MapState();
    
    state.setZoom(5.0);
    expect(state.zoom, equals(5.0));

    // Clamping limits
    state.setZoom(20.0);
    expect(state.zoom, equals(state.maxZoom));

    state.setZoom(-10.0);
    expect(state.zoom, equals(state.minZoom));
  });
}
