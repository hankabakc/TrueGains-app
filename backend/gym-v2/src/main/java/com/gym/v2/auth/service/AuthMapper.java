package com.gym.v2.auth.service;

import com.gym.v2.auth.dto.AuthResponse;
import com.gym.v2.auth.dto.RegisterRequest;
import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.entity.CoachEntity;
import com.gym.v2.core.config.CentralMapperConfig;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

/**
 * Auth Modülü Haritalama Arayüzü. Kullanıcı, Profil ve Token bilgilerini merkezi olarak
 * yönetir.
 */
@Mapper(config = CentralMapperConfig.class)
public interface AuthMapper {

	@Mapping(target = "tokenType", constant = "Bearer")
	@Mapping(target = "user.id", source = "user.id")
	@Mapping(target = "user.externalId", source = "user.externalId")
	@Mapping(target = "user.email", source = "user.email")
	@Mapping(target = "user.role", source = "user.role")
	AuthResponse toAuthResponse(AppUser user, String accessToken, Long expiresIn);

	@Mapping(target = "user", source = "user")
	@Mapping(target = "userId", ignore = true)
	@Mapping(target = "showAge", source = "request.showAge", defaultValue = "true")
	@Mapping(target = "showHeight", source = "request.showHeight", defaultValue = "true")
	@Mapping(target = "showWeight", source = "request.showWeight", defaultValue = "true")
	@Mapping(target = "instagramUrl", source = "request.instagramUrl")
	@Mapping(target = "websiteUrl", source = "request.websiteUrl")
	@Mapping(target = "tiktokUrl", ignore = true)
	@Mapping(target = "profilePhotoUrl", source = "request.profilePhotoUrl")
	@Mapping(target = "coachId", ignore = true)
	@Mapping(target = "publicPhotos", ignore = true)
	ClientEntity toClientEntity(AppUser user, String fullName, RegisterRequest request);

	@Mapping(target = "user", source = "user")
	@Mapping(target = "userId", ignore = true)
	@Mapping(target = "showSubscriberCount", constant = "false")
	@Mapping(target = "currency", ignore = true)
	@Mapping(target = "maxClients", ignore = true)
	@Mapping(target = "tiktokUrl", ignore = true)
	@Mapping(target = "profilePhotoUrl", source = "request.profilePhotoUrl")
	@Mapping(target = "experienceYears", ignore = true)
	CoachEntity toCoachEntity(AppUser user, String fullName, RegisterRequest request);

}
