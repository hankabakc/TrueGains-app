package com.gym.v2.nutrition.event;

/**
 * Diyet şablonu güncellendiğinde fırlatılan event kaydı. "Pure Java" politikası gereği
 * record tipindedir.
 */
public record DietTemplateUpdatedEvent(Long templateId) {
}
