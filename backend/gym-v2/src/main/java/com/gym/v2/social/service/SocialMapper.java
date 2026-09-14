package com.gym.v2.social.service;

import com.gym.v2.core.config.CentralMapperConfig;
import com.gym.v2.social.dto.*;
import com.gym.v2.social.entity.*;
import org.mapstruct.*;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;

/**
 * Sosyal modül veri dönüşüm (Mapper) soyut sınıfı. MapStruct abstract class desteği
 * sayesinde constructor injection kullanılmaktadır.
 */
@Mapper(config = CentralMapperConfig.class)
public abstract class SocialMapper {

	@Autowired
	protected SocialMappingHelper socialMappingHelper;

	@Mapping(target = "clientId", source = "client.userId")
	@Mapping(target = "clientName", source = "client.fullName")
	@Mapping(target = "coachId", source = "coach.userId")
	@Mapping(target = "coachName", source = "coach.fullName")
	@Mapping(target = "message", source = "message")
	public abstract PairingRequestDTO toPairingDTO(PairingRequest request);

	public abstract List<PairingRequestDTO> toPairingDTOList(List<PairingRequest> requests);

	@Mapping(target = "clientId", source = "client.id")
	@Mapping(target = "coachId", source = "coach.id")
	@Mapping(target = "clientFullName",
			expression = "java(socialMappingHelper.resolveClientName(conversation.getClient().getId()))")
	@Mapping(target = "coachFullName",
			expression = "java(socialMappingHelper.resolveCoachName(conversation.getCoach().getId()))")
	@Mapping(target = "lastMessagePreview", ignore = true)
	@Mapping(target = "unreadCount", ignore = true)
	public abstract ConversationDTO toConversationDTO(Conversation conversation);

	public abstract List<ConversationDTO> toConversationDTOList(List<Conversation> conversations);

	@Mapping(target = "conversationId", source = "conversation.id")
	@Mapping(target = "senderId", source = "sender.id")
	@Mapping(target = "senderFullName",
			expression = "java(socialMappingHelper.resolveSenderFullName(message.getSender()))")
	@Mapping(target = "content", source = "content")
	@Mapping(target = "attachmentUrl", source = "attachmentUrl")
	public abstract MessageDTO toMessageDTO(Message message);

	public abstract List<MessageDTO> toMessageDTOList(List<Message> messages);

	// --- COACH PROFILE & REVIEWS ---

	@Mapping(target = "clientId", source = "client.userId")
	@Mapping(target = "clientName", source = "client.fullName")
	@Mapping(target = "comment", source = "comment")
	public abstract CoachReviewDto toReviewDto(CoachReview review);

	public abstract List<CoachReviewDto> toReviewDtoList(List<CoachReview> reviews);

	@Mapping(target = "imageUrl", source = "imageUrl")
	public abstract CoachGalleryDto toGalleryDto(CoachGallery gallery);

	public abstract List<CoachGalleryDto> toGalleryDtoList(List<CoachGallery> galleries);

	@Mapping(target = "imageUrl", source = "imageUrl")
	public abstract ClientGalleryDto toClientGalleryDto(ClientGallery gallery);

	public abstract List<ClientGalleryDto> toClientGalleryDtoList(List<ClientGallery> galleries);

	@Mapping(target = "coachId", source = "coach.userId")
	@Mapping(target = "clientId", source = "client.userId")
	@Mapping(target = "studentNickname", source = "studentNickname")
	@Mapping(target = "beforeImageUrl", source = "beforeImageUrl")
	@Mapping(target = "afterImageUrl", source = "afterImageUrl")
	@Mapping(target = "description", source = "description")
	@Mapping(target = "status", source = "status")
	public abstract CoachStudentProgressDto toProgressDto(CoachStudentProgress progress);

	public abstract List<CoachStudentProgressDto> toProgressDtoList(List<CoachStudentProgress> progressList);

}
