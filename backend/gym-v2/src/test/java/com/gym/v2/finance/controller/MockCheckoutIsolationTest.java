package com.gym.v2.finance.controller;

import com.gym.v2.finance.service.MockPaymentProviderImpl;
import java.lang.reflect.Method;
import java.util.Arrays;
import org.junit.jupiter.api.Test;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Doğrulamasız ödeme ucunun üretime sızamayacağını garanti eder.
 * <p>
 * {@code /api/v1/finance/checkout/{transactionId}} hiçbir ödeme sağlayıcısına sormadan
 * abonelik açar. Sağlayıcı seçilene kadar gereklidir, ama gerçek entegrasyon geldiğinde
 * <b>mutlaka</b> silinmelidir. Bunu unutmamanın yolu, ucu {@link MockPaymentProviderImpl}
 * sınıfına derleme düzeyinde bağlamaktır: mock silinince kod derlenmez.
 * </p>
 * <p>
 * Bu testler o korumayı canlı tutar. İkisinden biri kırmızıya dönerse, koruma sessizce
 * kaldırılmış demektir.
 * </p>
 */
class MockCheckoutIsolationTest {

	@Test
	void mockCheckoutController_isCompileCoupledToTheMockProvider() {
		boolean dependsOnMock = Arrays.stream(MockCheckoutController.class.getDeclaredConstructors())
			.flatMap(constructor -> Arrays.stream(constructor.getParameterTypes()))
			.anyMatch(MockPaymentProviderImpl.class::equals);

		assertThat(dependsOnMock)
			.as("MockCheckoutController, MockPaymentProviderImpl'e bağımlı kalmalı. Bu bağımlılık "
					+ "'kullanılmıyor' diye kaldırılırsa, gerçek sağlayıcı entegrasyonunda mock sınıf "
					+ "silindiğinde bu doğrulamasız ödeme ucu derlenmeye devam eder ve üretime sızar.")
			.isTrue();
	}

	@Test
	void financeController_exposesNoPaymentEndpointThatBypassesTheGateway() {
		String prefix = FinanceController.class.getAnnotation(RequestMapping.class).value()[0];

		boolean hasCheckoutMapping = Arrays.stream(FinanceController.class.getDeclaredMethods())
			.map(method -> method.getAnnotation(PostMapping.class))
			.filter(mapping -> mapping != null)
			.flatMap(mapping -> Arrays.stream(mapping.value()))
			.anyMatch(path -> path.contains("checkout"));

		assertThat(hasCheckoutMapping)
			.as("%s altındaki ödeme ucu üretim denetleyicisine geri taşınmış. Sağlayıcıya sormadan "
					+ "abonelik açan bir uç, mock ile birlikte silinebilecek bir sınıfta durmalıdır.", prefix)
			.isFalse();
	}

	@Test
	void mockCheckoutController_stillServesTheOriginalPathSoTheClientKeepsWorking() {
		String prefix = MockCheckoutController.class.getAnnotation(RequestMapping.class).value()[0];
		Method endpoint = Arrays.stream(MockCheckoutController.class.getDeclaredMethods())
			.filter(method -> method.getAnnotation(PostMapping.class) != null)
			.findFirst()
			.orElseThrow();

		String fullPath = prefix + endpoint.getAnnotation(PostMapping.class).value()[0];

		assertThat(fullPath).as("uç taşındı ama URL değişmemeli; istemci bu adresi çağırıyor")
			.isEqualTo("/api/v1/finance/checkout/{transactionId}");
	}

}
