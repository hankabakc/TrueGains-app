import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/network/api_response.dart';
import 'package:gymapp_v2/features/finance/models/finance_models.dart';
import 'package:gymapp_v2/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:gymapp_v2/features/finance/repository/finance_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockFinanceRepository extends Mock implements FinanceRepository {}

/// Para akışının istemci tarafı. Buradaki en tehlikeli hata, backend ödemeyi
/// reddettiği hâlde arayüzün başarı göstermesidir: kullanıcı ödediğini sanır,
/// aboneliği yoktur.
void main() {
  late MockFinanceRepository repository;

  final subscription = ClientSubscriptionModel(
    id: 1,
    clientName: 'Ali Vural',
    coachName: 'Ahmet Yilmaz',
    packageName: 'Standard',
    startDate: DateTime(2026, 1, 1),
    endDate: DateTime(2026, 1, 31),
    isActive: true,
    daysRemaining: 30,
    price: 150.0,
  );

  ApiResponse<T> ok<T>(T? data, [String message = 'Başarılı']) => ApiResponse<T>(
        success: true,
        message: message,
        data: data,
        timestamp: '2026-01-01T00:00:00Z',
      );

  ApiResponse<T> fail<T>(String message) => ApiResponse<T>(
        success: false,
        message: message,
        timestamp: '2026-01-01T00:00:00Z',
      );

  setUp(() {
    repository = MockFinanceRepository();
    // Başarılı akışlar işlem listesini tazeler; sürekli stub'lanmasın diye burada.
    when(() => repository.getMyTransactions())
        .thenAnswer((_) async => ok<List<PaymentTransactionModel>>(const []));
  });

  FinanceBloc buildBloc() => FinanceBloc(repository: repository);

  PayCartTransaction payEvent() => PayCartTransaction(
        transactionId: 100,
        cardNumber: '1234567890123456',
        cardHolderName: 'Ali Vural',
        expiryDate: '12/30',
        cvv: '123',
      );

  void stubPayment(ApiResponse<ClientSubscriptionModel> response) {
    when(() => repository.processPaymentForTransaction(
          transactionId: any(named: 'transactionId'),
          cardNumber: any(named: 'cardNumber'),
          cardHolderName: any(named: 'cardHolderName'),
          expiryDate: any(named: 'expiryDate'),
          cvv: any(named: 'cvv'),
        )).thenAnswer((_) async => response);
  }

  group('Ödeme', () {
    blocTest<FinanceBloc, FinanceState>(
      'ödeme başarılı olduğunda → paymentSuccess durumu ve abonelik bilgisi taşınır',
      build: () {
        stubPayment(ok<ClientSubscriptionModel>(subscription));
        return buildBloc();
      },
      act: (bloc) => bloc.add(payEvent()),
      wait: const Duration(milliseconds: 50),
      // DİKKAT: `paymentSuccess` GEÇİCİ bir durumdur; hemen ardından tetiklenen
      // LoadMyTransactions durumu `loaded`a çevirir. Bu yüzden son duruma değil,
      // yayımlanan diziye bakılır. Arayüz bu durumu BlocListener ile yakalamalıdır;
      // BlocBuilder ile beklenseydi başarı ekranı hiç görünmezdi. Bu kısıt kayıt altındadır.
      expect: () => contains(
        isA<FinanceState>()
            .having((s) => s.status, 'status', FinanceStatus.paymentSuccess)
            .having((s) => s.subscription, 'subscription', subscription),
      ),
    );

    blocTest<FinanceBloc, FinanceState>(
      'backend ödemeyi reddettiğinde → hata durumu, abonelik KESİNLİKLE set edilmez',
      build: () {
        stubPayment(fail<ClientSubscriptionModel>('Bu işlemin ödemesi zaten gerçekleştirilmiş.'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(payEvent()),
      verify: (bloc) {
        expect(bloc.state.status, FinanceStatus.error);
        expect(bloc.state.error, 'Bu işlemin ödemesi zaten gerçekleştirilmiş.');
        // Kullanıcıya "ödendi" izlenimi verilmemeli.
        expect(bloc.state.subscription, isNull);
      },
    );

    blocTest<FinanceBloc, FinanceState>(
      'ağ hatası oluştuğunda → hata durumu, abonelik set edilmez',
      build: () {
        when(() => repository.processPaymentForTransaction(
              transactionId: any(named: 'transactionId'),
              cardNumber: any(named: 'cardNumber'),
              cardHolderName: any(named: 'cardHolderName'),
              expiryDate: any(named: 'expiryDate'),
              cvv: any(named: 'cvv'),
            )).thenThrow(Exception('bağlantı yok'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(payEvent()),
      verify: (bloc) {
        expect(bloc.state.status, FinanceStatus.error);
        expect(bloc.state.subscription, isNull);
      },
    );

    blocTest<FinanceBloc, FinanceState>(
      'ödeme başarılı olduğunda → işlem listesi yeniden yüklenir',
      build: () {
        stubPayment(ok<ClientSubscriptionModel>(subscription));
        return buildBloc();
      },
      act: (bloc) => bloc.add(payEvent()),
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        // Tazelenmezse sepette ödenmiş işlem görünmeye devam eder ve kullanıcı
        // ikinci kez ödemeye çalışır.
        verify(() => repository.getMyTransactions()).called(1);
      },
    );
  });

  group('Sepete ekleme', () {
    blocTest<FinanceBloc, FinanceState>(
      'sepete ekleme başarılı olduğunda → cartUpdated durumu yayımlanır',
      build: () {
        when(() => repository.addToCart(10))
            .thenAnswer((_) async => ok<PaymentTransactionModel>(null, 'Sepete eklendi'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(AddPackageToCart(10)),
      wait: const Duration(milliseconds: 50),
      // `cartUpdated` de geçicidir (bkz. yukarıdaki not).
      expect: () => contains(
        isA<FinanceState>()
            .having((s) => s.status, 'status', FinanceStatus.cartUpdated)
            .having((s) => s.successMessage, 'successMessage', 'Sepete eklendi'),
      ),
    );

    blocTest<FinanceBloc, FinanceState>(
      'backend sepete eklemeyi reddettiğinde → hata durumu ve backend mesajı',
      build: () {
        when(() => repository.addToCart(10))
            .thenAnswer((_) async => fail<PaymentTransactionModel>('Bu paketin kontenjanı dolu.'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(AddPackageToCart(10)),
      verify: (bloc) {
        expect(bloc.state.status, FinanceStatus.error);
        expect(bloc.state.error, 'Bu paketin kontenjanı dolu.');
      },
    );
  });
}
