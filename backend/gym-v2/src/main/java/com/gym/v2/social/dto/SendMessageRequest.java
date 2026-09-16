package com.gym.v2.social.dto;

import com.gym.v2.core.util.FileUrls;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record SendMessageRequest(@NotNull(message = "Konuşma ID zorunludur.") Long conversationId,

		@Size(max = 2000, message = "{validation.message.content.size}") String content,

		// Ek adresi yalnızca uygulamanın kendi dosya ucuna işaret edebilir.
		//
		// Kalıp mutlak biçimi hâlâ kabul ediyor çünkü mağazadan güncelleme almamış
		// kurulumlar yükleme ucunun döndürdüğü mutlak adresi gönderiyor. Ama kalıp
		// **sunucu adını kısıtlamaz** ve kısıtlayamaz (dağıtımın adını bilmez); bu yüzden
		// asıl koruma yazma anında: `ChatService` sunucu adını atıp yalnızca yolu saklar.
		// Kalıbın işi, yolun bizim dosya ucumuz olduğunu garanti etmek.
		@Size(max = 1024, message = "{validation.url.size}") @Pattern(regexp = FileUrls.PATTERN,
				message = "{validation.url.pattern}") String attachmentUrl,
		Long packageId,

		// Cihazın ürettiği kimlik; aynı gönderenden aynı kimlikle ikinci mesaj açılmaz
		// (G-79).
		@Size(max = 36, message = "Yerel kimlik en fazla 36 karakter olabilir.") String localId) {
}
