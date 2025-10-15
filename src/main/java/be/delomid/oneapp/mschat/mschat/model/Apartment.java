package be.delomid.oneapp.mschat.mschat.model;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "apartments")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(exclude = {"building", "resident"})
@ToString(exclude = {"building", "resident"})
public class Apartment {

    @Id
    @Column(name = "id_apartment")
    private String idApartment;

    @Column(name = "apartment_label", nullable = false)
    private String apartmentLabel;

    @Column(name = "apartment_number")
    private String apartmentNumber;

    @Column(name = "apartment_floor")
    private Integer apartmentFloor;

    @Column(name = "living_area_surface", precision = 10, scale = 2)
    private BigDecimal livingAreaSurface;

    @Column(name = "number_of_rooms")
    private Integer numberOfRooms;

    @Column(name = "number_of_bedrooms")
    private Integer numberOfBedrooms;

    @Builder.Default
    @Column(name = "have_balcony_or_terrace")
    private Boolean haveBalconyOrTerrace = false;

    @Builder.Default
    @Column(name = "is_furnished")
    private Boolean isFurnished = false;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "building_id", nullable = false)
    private Building building;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "resident_id")
    private Resident resident;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}