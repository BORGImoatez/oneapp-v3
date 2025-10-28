package be.delomid.oneapp.mschat.mschat.dto;

import java.time.LocalDateTime;
import java.util.List;

public class ClaimDto {
    private Long id;
    private Long apartmentId;
    private String apartmentNumber;
    private Long buildingId;
    private String buildingName;
    private Long reporterId;
    private String reporterName;
    private String reporterAvatar;
    private List<String> claimTypes;
    private String cause;
    private String description;
    private String insuranceCompany;
    private String insurancePolicyNumber;
    private String status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private List<Long> affectedApartmentIds;
    private List<ClaimPhotoDto> photos;

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getApartmentId() {
        return apartmentId;
    }

    public void setApartmentId(Long apartmentId) {
        this.apartmentId = apartmentId;
    }

    public String getApartmentNumber() {
        return apartmentNumber;
    }

    public void setApartmentNumber(String apartmentNumber) {
        this.apartmentNumber = apartmentNumber;
    }

    public Long getBuildingId() {
        return buildingId;
    }

    public void setBuildingId(Long buildingId) {
        this.buildingId = buildingId;
    }

    public String getBuildingName() {
        return buildingName;
    }

    public void setBuildingName(String buildingName) {
        this.buildingName = buildingName;
    }

    public Long getReporterId() {
        return reporterId;
    }

    public void setReporterId(Long reporterId) {
        this.reporterId = reporterId;
    }

    public String getReporterName() {
        return reporterName;
    }

    public void setReporterName(String reporterName) {
        this.reporterName = reporterName;
    }

    public String getReporterAvatar() {
        return reporterAvatar;
    }

    public void setReporterAvatar(String reporterAvatar) {
        this.reporterAvatar = reporterAvatar;
    }

    public List<String> getClaimTypes() {
        return claimTypes;
    }

    public void setClaimTypes(List<String> claimTypes) {
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

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
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

    public List<Long> getAffectedApartmentIds() {
        return affectedApartmentIds;
    }

    public void setAffectedApartmentIds(List<Long> affectedApartmentIds) {
        this.affectedApartmentIds = affectedApartmentIds;
    }

    public List<ClaimPhotoDto> getPhotos() {
        return photos;
    }

    public void setPhotos(List<ClaimPhotoDto> photos) {
        this.photos = photos;
    }
}
