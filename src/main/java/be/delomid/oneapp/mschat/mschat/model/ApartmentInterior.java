package be.delomid.oneapp.mschat.mschat.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "apartment_interior")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ApartmentInterior {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "apartment_id", nullable = false, unique = true)
    private String apartmentId;

    @Column(name = "quartier_lieu")
    private String quartierLieu;

    @Column(name = "surface_habitable", precision = 10, scale = 2)
    private BigDecimal surfaceHabitable;

    @Column(name = "surface_salon", precision = 10, scale = 2)
    private BigDecimal surfaceSalon;

    @Column(name = "type_cuisine", length = 100)
    private String typeCuisine;

    @Column(name = "surface_cuisine", precision = 10, scale = 2)
    private BigDecimal surfaceCuisine;

    @Column(name = "surface_chambres", columnDefinition = "TEXT")
    private String surfaceChambres;

    @Column(name = "nb_salle_douche")
    private Integer nbSalleDouche;

    @Column(name = "nb_toilette")
    private Integer nbToilette;

    private Boolean cave = false;

    private Boolean grenier = false;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt = LocalDateTime.now();

    @Column(name = "updated_by")
    private String updatedBy;
}
