package com.gym.v2.social.dto;

import java.util.List;

public record BulkReadEvent(Long conversationId, List<Long> messageIds, String status) {
}
