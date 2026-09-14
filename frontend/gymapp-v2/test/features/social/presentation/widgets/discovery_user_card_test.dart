import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:gymapp_v2/features/auth/data/models/user_role.dart';
import 'package:gymapp_v2/features/social/data/models/discovery_user_model.dart';
import 'package:gymapp_v2/features/social/presentation/widgets/discovery_user_card.dart';

void main() {
  group('DiscoveryUserCard Photo Fallback', () {
    final testUser = DiscoveryUserModel(
      userId: 1,
      fullName: 'Ahmet Yılmaz',
      role: UserRole.COACH,
      profilePhotoUrl: null,
      specialization: 'Fitness, Vücut Geliştirme',
    );

    testWidgets('fotoğrafsız kartta yedek zemin çiziliyor', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiscoveryUserCard(
              user: testUser,
              onViewProfile: () {},
              onSendMessage: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      final fallbackFinder =
          find.byKey(const Key('discovery_card_photo_fallback'));
      expect(fallbackFinder, findsOneWidget);

      final container = tester.widget<Container>(fallbackFinder);
      expect(
        container.color,
        equals(AppColors.primary.withValues(alpha: 0.10)),
      );
    });

    testWidgets('yedek zemin gradyan KULLANMIYOR', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiscoveryUserCard(
              user: testUser,
              onViewProfile: () {},
              onSendMessage: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      final fallbackFinder =
          find.byKey(const Key('discovery_card_photo_fallback'));
      final container = tester.widget<Container>(fallbackFinder);
      expect(container.decoration, isNull);

      final boxDecorations = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .where(
            (d) =>
                d.decoration is BoxDecoration &&
                (d.decoration as BoxDecoration).gradient ==
                    AppColors.primaryGradient,
          );
      expect(boxDecorations, isEmpty);
    });
  });

  group('DiscoveryUserCard içeriği', () {
    Future<void> pumpCard(WidgetTester tester, DiscoveryUserModel user) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiscoveryUserCard(
              user: user,
              onViewProfile: () {},
              onSendMessage: () {},
            ),
          ),
        ),
      );
      await tester.pump();
    }

    /// Kartin tek sayisi "0 ogrenci" olunca her koc kotu gorunuyordu.
    testWidgets('öğrencisi olmayan koçta sıfır sayacı gösterilmez',
        (tester) async {
      await pumpCard(
        tester,
        DiscoveryUserModel(
          userId: 1,
          fullName: 'Ahmet Yılmaz',
          role: UserRole.COACH,
          activeStudentCount: 0,
        ),
      );

      expect(find.textContaining('öğrenci'), findsNothing);
      expect(find.byIcon(Icons.star_rounded), findsNothing);
    });

    testWidgets('öğrencisi olan koçta sayaç gösterilir', (tester) async {
      await pumpCard(
        tester,
        DiscoveryUserModel(
          userId: 1,
          fullName: 'Ahmet Yılmaz',
          role: UserRole.COACH,
          activeStudentCount: 3,
        ),
      );

      expect(find.textContaining('3 öğrenci'), findsOneWidget);
      // Puani yokken yildiz cizilirse ogrenci sayisi puan sanilir.
      expect(find.byIcon(Icons.star_rounded), findsNothing);
      expect(find.byIcon(Icons.groups_rounded), findsOneWidget);
    });

    testWidgets('puanı olan koçta yıldız gösterilir', (tester) async {
      await pumpCard(
        tester,
        DiscoveryUserModel(
          userId: 1,
          fullName: 'Ahmet Yılmaz',
          role: UserRole.COACH,
          averageRating: 4.8,
          reviewCount: 12,
        ),
      );

      expect(find.textContaining('4.8 (12)'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });

    testWidgets('konum, deneyim ve başlangıç fiyatı kartta görünür',
        (tester) async {
      await pumpCard(
        tester,
        DiscoveryUserModel(
          userId: 1,
          fullName: 'Ahmet Yılmaz',
          role: UserRole.COACH,
          province: 'İstanbul',
          district: 'Kadıköy',
          experienceYears: 8,
          minPackagePrice: 750,
          currency: 'TRY',
        ),
      );

      expect(find.text('İstanbul, Kadıköy · 8 yıl'), findsOneWidget);
      expect(find.text("₺750'den başlıyor"), findsOneWidget);
    });

    /// Koclari birbirinden ayiran asil bilgi uzmanlik; "+1" arkasina saklanmamali.
    testWidgets('uzmanlıkların hepsi gösterilir', (tester) async {
      await pumpCard(
        tester,
        DiscoveryUserModel(
          userId: 1,
          fullName: 'Ahmet Yılmaz',
          role: UserRole.COACH,
          specialization: 'Powerlifting, Fitness, Crossfit',
        ),
      );

      expect(find.text('Powerlifting'), findsOneWidget);
      expect(find.text('Fitness'), findsOneWidget);
      expect(find.text('Crossfit'), findsOneWidget);
      expect(find.textContaining('+'), findsNothing);
    });

    testWidgets('paketi olmayan koçta fiyat satırı hiç çizilmez',
        (tester) async {
      await pumpCard(
        tester,
        DiscoveryUserModel(
          userId: 1,
          fullName: 'Ahmet Yılmaz',
          role: UserRole.COACH,
        ),
      );

      expect(find.byKey(const Key('discovery_card_price')), findsNothing);
    });
  });
}
