import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/widgets/glass_container.dart';
import 'package:gymapp_v2/features/social/presentation/widgets/discovery_loading_skeleton.dart';

void main() {
  Widget buildTestWidget({int? cardCount}) {
    return MaterialApp(
      home: Scaffold(
        body: cardCount != null
            ? DiscoveryLoadingSkeleton(cardCount: cardCount)
            : const DiscoveryLoadingSkeleton(),
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

  group('DiscoveryLoadingSkeleton', () {
    testWidgets('varsayılanda 3 iskelet kartı çizilir', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(GlassContainer), findsNWidgets(3));
    });

    testWidgets('cardCount verilirse o kadar kart çizilir', (tester) async {
      await tester.pumpWidget(buildTestWidget(cardCount: 5));
      await tester.pump();

      expect(find.byType(GlassContainer), findsNWidgets(5));
    });

    testWidgets('iskelet spinner içermez', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
