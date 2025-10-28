package be.delomid.oneapp.mschat.mschat.dto;

import java.util.List;

public class CreateClaimRequest {
    private Long apartmentId;
    private List<String> claimTypes;
    private String cause;
    private String description;
    private String insuranceCompany;
    private String insurancePolicyNumber;
    private List<Long> affectedApartmentIds;

    // Getters and Setters
    public Long getApartmentId() {
        return apartmentId;
    }

    public void setApartmentId(Long apartmentId) {
        this.apartmentId = apartmentId;
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

    public List<Long> getAffectedApartmentIds() {
        return affectedApartmentIds;
    }

    public void setAffectedApartmentIds(List<Long> affectedApartmentIds) {
        this.affectedApartmentIds = affectedApartmentIds;
    }
}
