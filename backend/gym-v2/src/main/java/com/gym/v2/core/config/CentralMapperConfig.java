package com.gym.v2.core.config;

import org.mapstruct.CollectionMappingStrategy;
import org.mapstruct.InjectionStrategy;
import org.mapstruct.MapperConfig;
import org.mapstruct.NullValuePropertyMappingStrategy;
import org.mapstruct.ReportingPolicy;

/**
 * GYMAPP-V2 Merkezi MapStruct Konfigürasyonu. Tüm Mapper interface'leri bu konfigürasyonu
 * miras alır.
 *
 * unmappedTargetPolicy = ERROR: Eşleşmeyen alan olduğunda derleme hatası verir (Sigorta).
 * componentModel = "spring": Mapper'ların Spring Bean olarak yönetilmesini sağlar.
 * injectionStrategy = InjectionStrategy.CONSTRUCTOR: Bağımlılıkların constructor
 * üzerinden enjekte edilmesini zorunlu kılar (Strict Anayasa Kuralı).
 */
@MapperConfig(componentModel = "spring", unmappedTargetPolicy = ReportingPolicy.ERROR,
		nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE,
		collectionMappingStrategy = CollectionMappingStrategy.ADDER_PREFERRED,
		injectionStrategy = InjectionStrategy.CONSTRUCTOR)
public interface CentralMapperConfig {

}
