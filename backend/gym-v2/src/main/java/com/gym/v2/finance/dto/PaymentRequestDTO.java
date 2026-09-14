package com.gym.v2.finance.dto;

public record PaymentRequestDTO(Long packageId, String cardNumber, String cardHolderName, String expiryDate,
		String cvv) {

}
