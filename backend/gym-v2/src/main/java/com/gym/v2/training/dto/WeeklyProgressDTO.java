package com.gym.v2.training.dto;

/**
 * GYMAPP-V2 Haftalık İlerleme DTO: Sporcunun haftalık idman hedefini ve durumunu taşır.
 * "Pure Java" politikası gereği record olarak tanımlanmıştır.
 */
public record WeeklyProgressDTO(int targetDays, int completedDays, double successPercentage) {
}
