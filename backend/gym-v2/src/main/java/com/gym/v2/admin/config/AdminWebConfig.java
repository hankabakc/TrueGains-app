package com.gym.v2.admin.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Denetim kaydini {@code /api/v1/admin/**} altindaki HER uca baglar.
 */
@Configuration
public class AdminWebConfig implements WebMvcConfigurer {

	private final AdminAuditInterceptor adminAuditInterceptor;

	public AdminWebConfig(AdminAuditInterceptor adminAuditInterceptor) {
		this.adminAuditInterceptor = adminAuditInterceptor;
	}

	@Override
	public void addInterceptors(InterceptorRegistry registry) {
		registry.addInterceptor(adminAuditInterceptor).addPathPatterns("/api/v1/admin/**");
	}

}
