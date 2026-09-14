package com.gym.v2.core.response;

import java.util.List;
import org.springframework.data.domain.Page;

/**
 * Spring Data Page nesnesini API katmanından izole etmek için kullanılan generic zarf
 * yapısı.
 *
 * @param <T> İçerik tipi
 */
public record PageResponse<T>(List<T> content, int pageNumber, int pageSize, long totalElements, int totalPages,
		boolean isLast) {
	public static <T> PageResponse<T> from(Page<T> page) {
		return new PageResponse<>(page.getContent(), page.getNumber(), page.getSize(), page.getTotalElements(),
				page.getTotalPages(), page.isLast());
	}
}
