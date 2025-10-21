package be.delomid.oneapp.mschat.mschat.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "apartment_general_info")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ApartmentGeneralInfo {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "apartment_id", nullable = false, unique = true)
    private Long apartmentId;

    @Column(name = "nb_chambres")
    private Integer nbChambres;

    @Column(name = "nb_salle_bain")
    private Integer nbSalleBain;

    @Column(precision = 10, scale = 2)
    private BigDecimal surface;

    private Integer etage;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt = LocalDateTime.now();

    @Column(name = "updated_by")
    private Long updatedBy;
}
