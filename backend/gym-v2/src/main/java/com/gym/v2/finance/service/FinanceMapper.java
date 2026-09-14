package com.gym.v2.finance.service;

import com.gym.v2.core.config.CentralMapperConfig;
import com.gym.v2.finance.dto.ClientSubscriptionDTO;
import com.gym.v2.finance.dto.SubscriptionPackageDTO;
import com.gym.v2.finance.dto.PaymentTransactionDTO;
import com.gym.v2.finance.entity.ClientSubscription;
import com.gym.v2.finance.entity.SubscriptionPackage;
import com.gym.v2.finance.entity.PaymentTransaction;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import java.util.List;

@Mapper(config = CentralMapperConfig.class)
public interface FinanceMapper {

	@Mapping(target = "activeSubscriberCount", ignore = true)
	SubscriptionPackageDTO toDTO(SubscriptionPackage pkg);

	@Mapping(target = "activeSubscriberCount", source = "activeSubscriberCount")
	SubscriptionPackageDTO toDTO(SubscriptionPackage pkg, Integer activeSubscriberCount);

	@Mapping(target = "clientName", ignore = true)
	@Mapping(target = "coachName", ignore = true)
	@Mapping(target = "packageName", source = "pkg.name")
	@Mapping(target = "price", source = "pkg.price")
	@Mapping(target = "daysRemaining", ignore = true)
	ClientSubscriptionDTO toDTO(ClientSubscription subscription);

	@Mapping(target = "packageId", source = "pkg.id")
	@Mapping(target = "packageName", source = "pkg.name")
	@Mapping(target = "durationDays", source = "pkg.durationDays")
	PaymentTransactionDTO toDTO(PaymentTransaction transaction);

	List<PaymentTransactionDTO> toTxDTOList(List<PaymentTransaction> transactions);

}
