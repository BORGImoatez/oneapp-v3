package be.delomid.oneapp.mschat.mschat.model;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "buildings")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(exclude = {"address", "apartments", "photos"})
@ToString(exclude = {"address", "apartments", "photos"})
public class Building {

    @Id
    @Column(name = "building_id")
    private String buildingId;

    @Column(name = "building_label", nullable = false)
    private String buildingLabel;

    @Column(name = "building_number")
    private String buildingNumber;

    @Column(name = "building_picture")
    private String buildingPicture;

    @Column(name = "year_of_construction")
    private Integer yearOfConstruction;

    @Column(name = "number_of_floors")
    private Integer numberOfFloors;

    @Column(name = "building_state", length = 100)
    private String buildingState;

    @Column(name = "facade_width", precision = 10, scale = 2)
    private BigDecimal facadeWidth;

    @Column(name = "land_area", precision = 10, scale = 2)
    private BigDecimal  landArea;

    @Column(name = "land_width", precision = 10, scale = 2)
    private BigDecimal  landWidth;

    @Column(name = "built_area", precision = 10, scale = 2)
    private BigDecimal  builtArea;

    @Column(name = "has_elevator")
    private Boolean hasElevator;

    @Column(name = "has_handicap_access")
    private Boolean hasHandicapAccess;

    @Column(name = "has_pool")
    private Boolean hasPool;

    @Column(name = "has_cable_tv")
    private Boolean hasCableTv;

    @OneToOne(cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    @JoinColumn(name = "address_id")
    private Address address;

    @OneToMany(mappedBy = "building", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    @Builder.Default
    private Set<Apartment> apartments = new HashSet<>();

    @OneToMany(mappedBy = "building", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    @Builder.Default
    private Set<BuildingPhoto> photos = new HashSet<>();

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}