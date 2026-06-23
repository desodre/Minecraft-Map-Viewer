class Structure {
  final String type;
  final String biome;
  final int x;
  final int z;

  Structure({
    required this.type,
    required this.biome,
    required this.x,
    required this.z,
  });

  factory Structure.fromJson(Map<String, dynamic> json) {
    return Structure(
      type: json['type'] as String,
      biome: json['biome'] as String,
      x: json['x'] as int,
      z: json['z'] as int,
    );
  }
}
