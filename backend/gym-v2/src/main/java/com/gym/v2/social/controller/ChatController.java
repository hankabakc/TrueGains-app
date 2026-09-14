package com.gym.v2.social.controller;

import com.gym.v2.core.response.ApiResponse;
import com.gym.v2.core.response.PageResponse;
import com.gym.v2.social.dto.BlockStatusDTO;
import com.gym.v2.social.dto.ConversationDTO;
import com.gym.v2.social.dto.MessageDTO;
import com.gym.v2.social.dto.SendMessageRequest;
import com.gym.v2.social.service.ChatService;
import jakarta.validation.Valid;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.security.access.prepost.PreAuthorize;
import java.time.Clock;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/social/chat")
@PreAuthorize("hasAnyRole('CLIENT', 'COACH')")
public class ChatController {

	private final ChatService chatService;

	private final Clock clock;

	public ChatController(ChatService chatService, Clock clock) {
		this.chatService = chatService;
		this.clock = clock;
	}

	@GetMapping("/conversations")
	public ApiResponse<PageResponse<ConversationDTO>> getMyConversations(
			@PageableDefault(size = 20) Pageable pageable) {
		PageResponse<ConversationDTO> response = PageResponse.from(chatService.getMyConversations(pageable));
		return ApiResponse.success(response, "Konuşmalar başarıyla listelendi.", clock.instant());
	}

	@GetMapping("/messages/{conversationId}")
	public ApiResponse<PageResponse<MessageDTO>> getMessages(@PathVariable Long conversationId,
			@PageableDefault(size = 50) Pageable pageable) {
		PageResponse<MessageDTO> response = PageResponse.from(chatService.getMessages(conversationId, pageable));
		return ApiResponse.success(response, "Mesajlar başarıyla listelendi.", clock.instant());
	}

	@PostMapping("/initiate/{targetUserId}")
	public ApiResponse<ConversationDTO> initiateConversation(@PathVariable Long targetUserId) {
		ConversationDTO response = chatService.initiateConversation(targetUserId);
		return ApiResponse.success(response, "Konuşma başlatıldı.", clock.instant());
	}

	@PostMapping("/send")
	public ApiResponse<MessageDTO> sendMessage(@RequestBody @Valid SendMessageRequest request) {
		MessageDTO response = chatService.sendMessage(request);
		return ApiResponse.success(response, "Mesaj başarıyla gönderildi.", clock.instant());
	}

	@PostMapping("/read/{conversationId}")
	public ApiResponse<Void> markAsRead(@PathVariable Long conversationId) {
		chatService.markAsRead(conversationId);
		return ApiResponse.success(null, "Mesajlar okundu olarak işaretlendi.", clock.instant());
	}

	@PostMapping("/block/{targetUserId}")
	public ApiResponse<Void> blockUser(@PathVariable Long targetUserId) {
		chatService.blockUser(targetUserId);
		return ApiResponse.success(null, "Kullanıcı engellendi.", clock.instant());
	}

	@DeleteMapping("/block/{targetUserId}")
	public ApiResponse<Void> unblockUser(@PathVariable Long targetUserId) {
		chatService.unblockUser(targetUserId);
		return ApiResponse.success(null, "Engel kaldırıldı.", clock.instant());
	}

	@GetMapping("/block-status/{otherUserId}")
	public ApiResponse<BlockStatusDTO> getBlockStatus(@PathVariable Long otherUserId) {
		BlockStatusDTO response = chatService.getBlockStatus(otherUserId);
		return ApiResponse.success(response, "Engelleme durumu.", clock.instant());
	}

}
