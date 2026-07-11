import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dengue_reader/app.dart';
import 'package:dengue_reader/core/constants/build_info.dart';
import 'package:dengue_reader/shared/widgets/app_version_label.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Default test surface (800x600) is shorter than a real phone and
    // overflows the capture screen's body layout; size it like a phone.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(child: DengueReaderApp()),
    );
  });

  testWidgets('Home screen shows the GitHub commit label',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(child: DengueReaderApp()),
    );
    await tester.pump();

    expect(find.byType(AppVersionLabel), findsOneWidget);
    expect(find.textContaining(BuildInfo.commitHash), findsOneWidget);
  });
}
