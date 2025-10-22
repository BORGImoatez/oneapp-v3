package be.delomid.oneapp.mschat.mschat.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ApartmentDetailsDto {
    private String apartmentId;
    private String apartmentNumber;

    private List<ApartmentPhotoDto> photos;

    private GeneralInfoDto generalInfo;
    private InteriorDto interior;
    private ExteriorDto exterior;
    private InstallationsDto installations;
    private EnergieDto energie;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class GeneralInfoDto {
        private Long id;
        private Integer nbChambres;
        private Integer nbSalleBain;
        private BigDecimal surface;
        private Integer etage;
        private LocalDateTime updatedAt;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class InteriorDto {
        private Long id;
        private String quartierLieu;
        private BigDecimal surfaceHabitable;
        private BigDecimal surfaceSalon;
        private String typeCuisine;
        private BigDecimal surfaceCuisine;
        private List<BigDecimal> surfaceChambres;
        private Integer nbSalleDouche;
        private Integer nbToilette;
        private Boolean cave;
        private Boolean grenier;
        private LocalDateTime updatedAt;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ExteriorDto {
        private Long id;
        private BigDecimal surfaceTerrasse;
        private String orientationTerrasse;
        private LocalDateTime updatedAt;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class InstallationsDto {
        private Long id;
        private Boolean ascenseur;
        private Boolean accesHandicap;
        private Boolean parlophone;
        private Boolean interphoneVideo;
        private Boolean porteBlindee;
        private Boolean piscine;
        private LocalDateTime updatedAt;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class EnergieDto {
        private Long id;
        private String classeEnergetique;
        private BigDecimal consommationEnergiePrimaire;
        private BigDecimal consommationTheoriqueTotale;
        private BigDecimal emissionCo2;
        private String numeroRapportPeb;
        private String typeChauffage;
        private Boolean doubleVitrage;
        private LocalDateTime updatedAt;
    }
}
