package be.delomid.oneapp.mschat.mschat.dto;

import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
public class CreateClaimRequest {
    // Getters and Setters

    private String apartmentId;
    private List<String> claimTypes;
    private String cause;
    private String description;
    private String insuranceCompany;
    private String insurancePolicyNumber;
    private List<String> affectedApartmentIds;

}
