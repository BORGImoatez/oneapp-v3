package be.delomid.oneapp.mschat.mschat.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.math.BigDecimal;

@Data
public class CreateApartmentRequest {
    
    @NotBlank(message = "Apartment label is required")
    private String apartmentLabel;
    
    private String apartmentNumber;
    private Integer apartmentFloor;
    private BigDecimal livingAreaSurface;
    private Integer numberOfRooms;
    private Integer numberOfBedrooms;
    private Boolean haveBalconyOrTerrace = false;
    private Boolean isFurnished = false;
    
    @NotBlank(message = "Building ID is required")
    private String buildingId;
}