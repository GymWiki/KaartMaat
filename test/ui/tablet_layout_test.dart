import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/core/ui/content_width.dart';
import 'package:kaartmaat/features/games/ui/home_screen.dart';

import 'package:kaartmaat/features/games/data/game_repository.dart';

import '../helpers.dart';

void main() {
  Future<void> pumpHome(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpApp(
      tester,
      const HomeScreen(),
      scaffold: false,
      overrides: [unfinishedIdsProvider.overrideWith((ref) => Stream.value(const <int>[]))],
    );
    await tester.pump();
  }

  double cardWidth(WidgetTester tester) =>
      tester.getSize(find.ancestor(of: find.text('Boerenbridge'), matching: find.byType(Material)).first).width;

  testWidgets('phone width: two columns, like before', (tester) async {
    await pumpHome(tester, const Size(400, 900));
    final grid = tester.widget<GridView>(find.byType(GridView));
    expect((grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount).crossAxisCount, 2);
  });

  testWidgets('tablet width: three columns, content kept at 720', (tester) async {
    await pumpHome(tester, const Size(800, 1280));
    final grid = tester.widget<GridView>(find.byType(GridView));
    expect((grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount).crossAxisCount, 3);
    expect(tester.getSize(find.byType(GridView)).width, lessThanOrEqualTo(kContentMaxWidth));
    expect(cardWidth(tester), lessThan(260));
  });

  testWidgets('ContentWidth does not touch a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpApp(tester, const ContentWidth(child: SizedBox.expand(key: Key('c'))));
    expect(tester.getSize(find.byKey(const Key('c'))).width, 400);
  });

  testWidgets('ContentWidth centers on a wide screen', (tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpApp(tester, const ContentWidth(child: SizedBox.expand(key: Key('c'))));
    expect(tester.getSize(find.byKey(const Key('c'))).width, kContentMaxWidth);
    expect(tester.getCenter(find.byKey(const Key('c'))).dx, 500);
  });

  testWidgets("contentPadding: nothing extra on a phone, a margin on a tablet", (tester) async {
    late EdgeInsets phone, tablet;
    for (final (w, set) in [(400.0, true), (1000.0, false)]) {
      tester.view.physicalSize = Size(w, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpApp(tester, Builder(builder: (c) {
        final p = contentPadding(c, const EdgeInsets.all(16));
        if (set) { phone = p; } else { tablet = p; }
        return const SizedBox();
      }));
    }
    expect(phone, const EdgeInsets.all(16));
    expect(tablet, const EdgeInsets.symmetric(horizontal: 16 + 140, vertical: 16));
  });
}
