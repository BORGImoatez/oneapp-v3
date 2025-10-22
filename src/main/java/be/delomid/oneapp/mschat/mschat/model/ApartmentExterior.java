package be.delomid.oneapp.mschat.mschat.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "apartment_exterior")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ApartmentExterior {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "apartment_id", nullable = false, unique = true)
    private String apartmentId;

    @Column(name = "surface_terrasse", precision = 10, scale = 2)
    private BigDecimal surfaceTerrasse;

    @Column(name = "orientation_terrasse", length = 50)
    private String orientationTerrasse;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt = LocalDateTime.now();

    @Column(name = "updated_by")
    private String updatedBy;
}
