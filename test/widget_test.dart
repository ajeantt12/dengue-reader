import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dengue_reader/app.dart';
import 'package:dengue_reader/core/constants/build_info.dart';
import 'package:dengue_reader/shared/widgets/app_version_label.dart';

void main() {
  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'DengueReader',
      packageName: 'com.denguereader.dengue_reader',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
      installerStore: null,
    );
  });

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

  testWidgets('Home screen shows the version and build label',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(child: DengueReaderApp()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppVersionLabel), findsOneWidget);
    expect(find.textContaining('v1.0.0+1'), findsOneWidget);
    expect(find.textContaining(BuildInfo.commitHash), findsOneWidget);
  });
}
