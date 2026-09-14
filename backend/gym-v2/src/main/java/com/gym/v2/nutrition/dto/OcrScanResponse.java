package com.gym.v2.nutrition.dto;

/**
 * Gemini OCR işlemi sonrasında istemciye dönülen yanıt nesnesi.
 */
public record OcrScanResponse(FoodResponse foodData, String assistantMessage, Integer remainingScans,
		Boolean limitReached) {
}
