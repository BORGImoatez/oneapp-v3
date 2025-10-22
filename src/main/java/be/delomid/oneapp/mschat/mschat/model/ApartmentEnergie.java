package be.delomid.oneapp.mschat.mschat.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "apartment_energie")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ApartmentEnergie {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "apartment_id", nullable = false, unique = true)
    private String apartmentId;

    @Column(name = "classe_energetique", length = 10)
    private String classeEnergetique;

    @Column(name = "consommation_energie_primaire", precision = 10, scale = 2)
    private BigDecimal consommationEnergiePrimaire;

    @Column(name = "consommation_theorique_totale", precision = 10, scale = 2)
    private BigDecimal consommationTheoriqueTotale;

    @Column(name = "emission_co2", precision = 10, scale = 2)
    private BigDecimal emissionCo2;

    @Column(name = "numero_rapport_peb", length = 100)
    private String numeroRapportPeb;

    @Column(name = "type_chauffage", length = 100)
    private String typeChauffage;

    @Column(name = "double_vitrage")
    private Boolean doubleVitrage = false;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt = LocalDateTime.now();

    @Column(name = "updated_by")
    private String updatedBy;
}
