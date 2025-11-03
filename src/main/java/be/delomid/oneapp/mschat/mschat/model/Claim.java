package be.delomid.oneapp.mschat.mschat.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "claims")
public class Claim {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "apartment_id", nullable = false)
    private Apartment apartment;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "building_id", nullable = false)
    private Building building;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "reporter_id", nullable = false)
    private Resident reporter;

    @Column(name = "claim_types", nullable = false)
    private String[] claimTypes;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String cause;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String description;

    @Column(name = "insurance_company")
    private String insuranceCompany;

    @Column(name = "insurance_policy_number")
    private String insurancePolicyNumber;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private ClaimStatus status = ClaimStatus.PENDING;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @OneToMany(mappedBy = "claim", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<ClaimAffectedApartment> affectedApartments = new ArrayList<>();

    @OneToMany(mappedBy = "claim", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<ClaimPhoto> photos = new ArrayList<>();

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "emergency_channel_id")
    private Channel emergencyChannel;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "emergency_folder_id")
    private Folder emergencyFolder;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Apartment getApartment() {
        return apartment;
    }

    public void setApartment(Apartment apartment) {
        this.apartment = apartment;
    }

    public Building getBuilding() {
        return building;
    }

    public void setBuilding(Building building) {
        this.building = building;
    }

    public Resident getReporter() {
        return reporter;
    }

    public void setReporter(Resident reporter) {
        this.reporter = reporter;
    }

    public String[] getClaimTypes() {
        return claimTypes;
    }

    public void setClaimTypes(String[] claimTypes) {
        this.claimTypes = claimTypes;
    }

    public String getCause() {
        return cause;
    }

    public void setCause(String cause) {
        this.cause = cause;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getInsuranceCompany() {
        return insuranceCompany;
    }

    public void setInsuranceCompany(String insuranceCompany) {
        this.insuranceCompany = insuranceCompany;
    }

    public String getInsurancePolicyNumber() {
        return insurancePolicyNumber;
    }

    public void setInsurancePolicyNumber(String insurancePolicyNumber) {
        this.insurancePolicyNumber = insurancePolicyNumber;
    }

    public ClaimStatus getStatus() {
        return status;
    }

    public void setStatus(ClaimStatus status) {
        this.status = status;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }

    public List<ClaimAffectedApartment> getAffectedApartments() {
        return affectedApartments;
    }

    public void setAffectedApartments(List<ClaimAffectedApartment> affectedApartments) {
        this.affectedApartments = affectedApartments;
    }

    public List<ClaimPhoto> getPhotos() {
        return photos;
    }

    public void setPhotos(List<ClaimPhoto> photos) {
        this.photos = photos;
    }

    public Channel getEmergencyChannel() {
        return emergencyChannel;
    }

    public void setEmergencyChannel(Channel emergencyChannel) {
        this.emergencyChannel = emergencyChannel;
    }

    public Folder getEmergencyFolder() {
        return emergencyFolder;
    }

    public void setEmergencyFolder(Folder emergencyFolder) {
        this.emergencyFolder = emergencyFolder;
    }
}
