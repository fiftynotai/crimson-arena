import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crimson_arena/main.dart';

void main() {
  setUp(() {
    // Mock path_provider channel for GetStorage in test environment.
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => '/tmp',
    );
  });

  testWidgets('CrimsonArenaApp renders without errors',
      (WidgetTester tester) async {
    // Use a web-dashboard-appropriate viewport (default 800x600 is too narrow).
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const CrimsonArenaApp());

    // Verify the app title renders.
    expect(find.text('CRIMSON ARENA'), findsWidgets);
  });
}
