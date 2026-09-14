package com.gym.v2.measurement.service;

import com.gym.v2.core.config.CentralMapperConfig;
import com.gym.v2.measurement.dto.MeasurementDTO;
import com.gym.v2.measurement.dto.SharedMeasurementRecord;
import com.gym.v2.measurement.entity.Measurement;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

import java.util.List;

@Mapper(config = CentralMapperConfig.class)
public interface MeasurementMapper {

	MeasurementDTO toDTO(Measurement measurement);

	List<MeasurementDTO> toDTOList(List<Measurement> measurements);

	@Mapping(target = "measurementDate", source = "createdAt")
	SharedMeasurementRecord toSharedRecord(Measurement measurement);

	@Mapping(target = "id", ignore = true)
	@Mapping(target = "user", ignore = true)
	@Mapping(target = "createdAt", ignore = true)
	@Mapping(target = "isSharedWithCoach", ignore = true)
	Measurement toEntity(MeasurementDTO dto);

}
