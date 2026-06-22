import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mc_map_viewer/page/map_screen.dart';
import 'package:mc_map_viewer/state/map_state.dart';

void main(List<String> args) {
  runApp(
    ChangeNotifierProvider(
      create: (_) => MapState(),
      child: const McMapViewerApp(),
    ),
  );
}

class McMapViewerApp extends StatelessWidget {
  const McMapViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minecraft World Map Viewer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF00FF88),
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        useMaterial3: true,
      ),
      home: const MapScreen(),
    );
  }
}