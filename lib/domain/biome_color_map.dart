import 'package:flutter/material.dart';

class BiomeColorMap {
  static final Map<int, String> _idToName = {};
  static final Map<String, Color> _nameToColor = {};
  static final Map<int, Color> _idToColor = {};
  static const Color defaultColor = Color(0xFF8DB360); // Plains green default

  static void register(int id, String name, Color color) {
    _idToName[id] = name;
    _idToColor[id] = color;
    _nameToColor[name.toLowerCase()] = color;
    _nameToColor['minecraft:${name.toLowerCase()}'] = color;
  }

  static String getBiomeName(int id) {
    return _idToName[id] ?? 'unknown';
  }

  static Color getColor(int id) {
    return _idToColor[id] ?? defaultColor;
  }

  static Color getColorByName(String name) {
    return _nameToColor[name.toLowerCase()] ?? defaultColor;
  }

  // Returns the name of the biome that has the closest color to the given (r, g, b)
  static String getBiomeNameByColor(int r, int g, int b) {
    if (_idToColor.isEmpty) {
      _init();
    }

    String closestBiome = 'unknown';
    double minDistance = double.maxFinite;

    for (final entry in _idToColor.entries) {
      final Color color = entry.value;
      
      // Euclidean distance in RGB space
      final double dr = (r - (color.r * 255.0).round()).toDouble();
      final double dg = (g - (color.g * 255.0).round()).toDouble();
      final double db = (b - (color.b * 255.0).round()).toDouble();
      final double distance = dr * dr + dg * dg + db * db;

      if (distance < minDistance) {
        minDistance = distance;
        closestBiome = _idToName[entry.key] ?? 'unknown';
      }
    }

    // If it's a very bad match (e.g. background grid or dark lines), return unknown
    // Max distance is 255^2 * 3 = 195075. Let's allow a threshold, e.g. 5000.
    if (minDistance > 10000) {
      return 'unknown';
    }

    return closestBiome;
  }

  static void _init() {
    // Oceans
    register(0, "ocean", const Color(0xFF000070));
    register(24, "deep_ocean", const Color(0xFF000030));
    register(44, "warm_ocean", const Color(0xFF0000A0));
    register(45, "lukewarm_ocean", const Color(0xFF007FFF));
    register(46, "cold_ocean", const Color(0xFF202070));
    register(47, "deep_warm_ocean", const Color(0xFF000060));
    register(48, "deep_lukewarm_ocean", const Color(0xFF004080));
    register(49, "deep_cold_ocean", const Color(0xFF202060));
    register(50, "deep_frozen_ocean", const Color(0xFF202040));
    register(10, "frozen_ocean", const Color(0xFF7070D6));

    // Plains & Meadows
    register(1, "plains", const Color(0xFF8DB360));
    register(129, "sunflower_plains", const Color(0xFFB5DB88));
    register(185, "meadow", const Color(0xFF2C8C44));

    // Deserts & Beaches
    register(2, "desert", const Color(0xFFFAE2A2));
    register(130, "desert_lakes", const Color(0xFFFFEBB4));
    register(16, "beach", const Color(0xFFFADE55));
    register(25, "stony_shore", const Color(0xFFA2A2A2));
    register(26, "snowy_beach", const Color(0xFFFAF0C0));

    // Forests
    register(4, "forest", const Color(0xFF056621));
    register(18, "forest_hills", const Color(0xFF056621));
    register(132, "flower_forest", const Color(0xFF2D8E49));
    register(27, "birch_forest", const Color(0xFF307444));
    register(28, "birch_forest_hills", const Color(0xFF307444));
    register(155, "old_growth_birch_forest", const Color(0xFF1E5A32));
    register(29, "dark_forest", const Color(0xFF40511A));
    register(157, "dark_forest_hills", const Color(0xFF40511A));
    register(191, "cherry_grove", const Color(0xFFFFB5D8));

    // Taigas & Snowy Plains
    register(5, "taiga", const Color(0xFF0B4D2C));
    register(19, "taiga_hills", const Color(0xFF0B4D2C));
    register(133, "taiga_mountains", const Color(0xFF0B4D2C));
    register(30, "snowy_taiga", const Color(0xFF31554A));
    register(31, "snowy_taiga_hills", const Color(0xFF31554A));
    register(158, "snowy_taiga_mountains", const Color(0xFF31554A));
    register(32, "old_growth_pine_taiga", const Color(0xFF596651));
    register(33, "old_growth_spruce_taiga", const Color(0xFF2D5D30));
    register(12, "snowy_plains", const Color(0xFFFFFFFF));
    register(140, "ice_spikes", const Color(0xFFB4DCFF));

    // Swamps
    register(6, "swamp", const Color(0xFF07F9B2));
    register(134, "swamp_hills", const Color(0xFF07F9B2));
    register(192, "mangrove_swamp", const Color(0xFF383A15));

    // Rivers
    register(7, "river", const Color(0xFF0000FF));
    register(11, "frozen_river", const Color(0xFFA0A0FF));

    // Mountains & Peaks
    register(3, "windswept_hills", const Color(0xFF606060));
    register(34, "wooded_mountains", const Color(0xFF606060));
    register(131, "windswept_gravelly_hills", const Color(0xFF888888));
    register(162, "modified_gravelly_mountains", const Color(0xFF888888));
    register(186, "grove", const Color(0xFF5B8772));
    register(187, "snowy_slopes", const Color(0xFFF2F2F2));
    register(188, "jagged_peaks", const Color(0xFFFFFFFF));
    register(189, "frozen_peaks", const Color(0xFFF0F0FF));
    register(190, "stony_peaks", const Color(0xFF8C8C8C));

    // Jungles
    register(21, "jungle", const Color(0xFF22B600));
    register(22, "jungle_hills", const Color(0xFF22B600));
    register(23, "sparse_jungle", const Color(0xFF62B600));
    register(149, "modified_jungle", const Color(0xFF22B600));
    register(151, "modified_jungle_edge", const Color(0xFF62B600));
    register(168, "bamboo_jungle", const Color(0xFF768E14));
    register(169, "bamboo_jungle_hills", const Color(0xFF768E14));

    // Savanna
    register(35, "savanna", const Color(0xFFBDB15A));
    register(36, "savanna_plateau", const Color(0xFFA79D52));
    register(163, "shattered_savanna", const Color(0xFFE5D982));
    register(164, "shattered_savanna_plateau", const Color(0xFFCFB57A));

    // Badlands
    register(37, "badlands", const Color(0xFFD94515));
    register(38, "wooded_badlands", const Color(0xFFB09765));
    register(39, "badlands_plateau", const Color(0xFFB06565));
    register(165, "eroded_badlands", const Color(0xFFFF6D3D));
    register(166, "modified_badlands_plateau", const Color(0xFFCE8383));

    // Caves
    register(182, "dripstone_caves", const Color(0xFF42372C));
    register(183, "lush_caves", const Color(0xFF3A592D));
    register(184, "deep_dark", const Color(0xFF03161C));

    // Nether
    register(8, "nether_wastes", const Color(0xFF8B2222));
    register(178, "soul_sand_valley", const Color(0xFF5E4D41));
    register(179, "crimson_forest", const Color(0xFF981A1A));
    register(180, "warped_forest", const Color(0xFF1A7068));
    register(181, "basalt_deltas", const Color(0xFF423D3D));

    // End
    register(9, "the_end", const Color(0xFF383818));
    register(40, "small_end_islands", const Color(0xFF4A4A25));
    register(41, "end_midlands", const Color(0xFF5A5A30));
    register(42, "end_highlands", const Color(0xFF6C6C38));
    register(43, "end_barrens", const Color(0xFF3C3C1B));
  }
}
