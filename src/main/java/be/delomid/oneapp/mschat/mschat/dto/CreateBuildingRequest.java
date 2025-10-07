package be.delomid.oneapp.mschat.mschat.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CreateBuildingRequest {
    
     private String buildingId;
    
    @NotBlank(message = "Building label is required")
    private String buildingLabel;
    
    private String buildingNumber;
    private String buildingPicture;
    private Integer yearOfConstruction;
    
    @NotNull(message = "Address is required")
    private CreateAddressRequest address;
}

