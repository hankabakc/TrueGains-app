import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/widgets/chat_loading_skeleton.dart';

void main() {
  Widget buildTestWidget({int? bubbleCount}) {
    return MaterialApp(
      home: Scaffold(
        body: bubbleCount != null
            ? ChatLoadingSkeleton(bubbleCount: bubbleCount)
            : const ChatLoadingSkeleton(),
      ),
    );
  }

  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(800, 3000);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  group('ChatLoadingSkeleton', () {
    testWidgets('varsayılanda 5 baloncuk çizilir', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(Align), findsNWidgets(5));
    });

    testWidgets('iskelet spinner içermez', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
