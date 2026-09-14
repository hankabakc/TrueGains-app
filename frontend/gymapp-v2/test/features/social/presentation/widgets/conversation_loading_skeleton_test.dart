import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/features/social/presentation/widgets/conversation_loading_skeleton.dart';

void main() {
  Widget buildTestWidget({int? rowCount}) {
    return MaterialApp(
      home: Scaffold(
        body: rowCount != null
            ? ConversationLoadingSkeleton(rowCount: rowCount)
            : const ConversationLoadingSkeleton(),
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

  group('ConversationLoadingSkeleton', () {
    testWidgets('varsayılanda 5 iskelet satırı çizilir', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(GlassContainer), findsNWidgets(5));
    });

    testWidgets('rowCount verilirse o kadar satır çizilir', (tester) async {
      await tester.pumpWidget(buildTestWidget(rowCount: 3));
      await tester.pump();

      expect(find.byType(GlassContainer), findsNWidgets(3));
    });

    testWidgets('iskelet spinner içermez', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
