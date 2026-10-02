import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gta_app/src/features/seller/product/views/widgets/color_picker_field.dart';

void main() {
  Widget host({String? hex, required ValueChanged<String> onChanged}) {
    return MaterialApp(
      home: Scaffold(
        body: ColorSelectField(valueHex: hex, onChanged: onChanged),
      ),
    );
  }

  testWidgets('shows placeholder when no color chosen', (tester) async {
    await tester.pumpWidget(host(hex: null, onChanged: (_) {}));
    expect(find.text('Select a color'), findsOneWidget);
  });

  testWidgets('shows the resolved name for a known hex', (tester) async {
    await tester.pumpWidget(host(hex: '#000080', onChanged: (_) {}));
    expect(find.text('Navy Blue'), findsOneWidget);
  });

  testWidgets('tapping the field opens a sheet with search + grid', (tester) async {
    await tester.pumpWidget(host(hex: '#000080', onChanged: (_) {}));
    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();

    expect(find.text('Select Color'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);

    // Search to bring the currently selected color into view, and confirm
    // it renders as pre-checked (GridView only builds visible tiles, so this
    // has to be searched into view rather than found in the full ~100-color list).
    await tester.enterText(find.byType(TextField), 'navy blue');
    await tester.pumpAndSettle();
    // One "Navy Blue" behind the sheet (the field itself) and one in the grid tile.
    expect(find.text('Navy Blue'), findsNWidgets(2));
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('searching filters the grid to matching names', (tester) async {
    await tester.pumpWidget(host(hex: null, onChanged: (_) {}));
    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'navy');
    await tester.pumpAndSettle();

    expect(find.text('Navy Blue'), findsOneWidget);
    expect(find.text('Maroon'), findsNothing);
  });

  testWidgets('search with no matches shows an empty state, not a crash', (tester) async {
    await tester.pumpWidget(host(hex: null, onChanged: (_) {}));
    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzzznotacolor');
    await tester.pumpAndSettle();

    expect(find.textContaining('No colors match'), findsOneWidget);
    // Custom-color escape hatch should still be reachable.
    expect(find.text("Can't find it? Mix a custom color"), findsOneWidget);
  });

  testWidgets('picking a color from the grid returns its hex and closes the sheet', (
    tester,
  ) async {
    String? picked;
    await tester.pumpWidget(host(hex: null, onChanged: (hex) => picked = hex));
    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'navy blue');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Navy Blue').last);
    await tester.pumpAndSettle();

    expect(picked, '#000080');
    // Sheet should have closed.
    expect(find.text('Select Color'), findsNothing);
  });
}
