package com.gym.v2.admin.service;

import com.gym.v2.admin.dto.AdminUserRowDto;
import com.gym.v2.auth.entity.UserRole;
import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class AdminUserCsvTest {

	private static final AdminUserRowDto ROW = new AdminUserRowDto(1L, "antrenor@test.com", "Antrenör \"Koç\" Adı",
			UserRole.COACH, true, false, Instant.parse("2026-01-01T00:00:00Z"), null);

	@Test
	void toCsv_writesHeaderAndOneQuotedLinePerRow() {
		String expected = AdminUserCsv.HEADER + "\r\n"
				+ "\"antrenor@test.com\";\"Antrenör \"\"Koç\"\" Adı\";\"Antrenör\";aktif;hayır;2026-01-01T00:00:00Z;\r\n";
		assertThat(AdminUserCsv.toCsv(List.of(ROW))).isEqualTo(expected);
	}

	@Test
	void cell_neutralizesFormulaPrefixes() {
		assertThat(AdminUserCsv.cell("=HYPERLINK(\"x\")")).isEqualTo("\"'=HYPERLINK(\"\"x\"\")\"");
		assertThat(AdminUserCsv.cell("+1")).isEqualTo("\"'+1\"");
		assertThat(AdminUserCsv.cell("-1")).isEqualTo("\"'-1\"");
		assertThat(AdminUserCsv.cell("@SUM(A1)")).isEqualTo("\"'@SUM(A1)\"");
		assertThat(AdminUserCsv.cell("normal@test.com")).isEqualTo("\"normal@test.com\"");
	}

	@Test
	void cell_nullBecomesEmpty() {
		assertThat(AdminUserCsv.cell(null)).isEmpty();
	}

}
