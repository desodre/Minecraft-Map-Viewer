import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mc_map_viewer/main.dart';
import 'package:mc_map_viewer/state/map_state.dart';

void main() {
  testWidgets('MapViewer smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => MapState(),
        child: const McMapViewerApp(),
      ),
    );

    // Verify that the title is shown on screen
    expect(find.text('SEED MAP'), findsOneWidget);
  });
}
