package be.delomid.oneapp.mschat.mschat.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UpdateApartmentDetailsRequest {
    private GeneralInfoRequest generalInfo;
    private InteriorRequest interior;
    private ExteriorRequest exterior;
    private InstallationsRequest installations;
    private EnergieRequest energie;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class GeneralInfoRequest {
        private Integer nbChambres;
        private Integer nbSalleBain;
        private BigDecimal surface;
        private Integer etage;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class InteriorRequest {
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
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ExteriorRequest {
        private BigDecimal surfaceTerrasse;
        private String orientationTerrasse;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class InstallationsRequest {
        private Boolean ascenseur;
        private Boolean accesHandicap;
        private Boolean parlophone;
        private Boolean interphoneVideo;
        private Boolean porteBlindee;
        private Boolean piscine;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class EnergieRequest {
        private String classeEnergetique;
        private BigDecimal consommationEnergiePrimaire;
        private BigDecimal consommationTheoriqueTotale;
        private BigDecimal emissionCo2;
        private String numeroRapportPeb;
        private String typeChauffage;
        private Boolean doubleVitrage;
    }
}
