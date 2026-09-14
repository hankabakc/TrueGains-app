package com.gym.v2.training.entity;

/**
 * GYMAPP-V2 Antrenman Motoru: Egzersizlerin odaklandığı kas gruplarını temsil eden Enum.
 * Analiz modülünde (ANALYZEPANEL vizyonu) hacim dağılımı bu değerlere göre
 * hesaplanacaktır.
 */
public enum MuscleGroup {

	CHEST, // Göğüs
	BACK, // Sırt
	SHOULDERS, // Omuz
	BICEPS, // Ön Kol
	TRICEPS, // Arka Kol
	QUADRICEPS, // Ön Bacak (Baldır)
	HAMSTRINGS, // Arka Bacak
	CALVES, // Kalf
	ABS, // Karın
	FULL_BODY, // Tüm Vücut
	CARDIO // Kardiyo/Dayanıklılık

}
