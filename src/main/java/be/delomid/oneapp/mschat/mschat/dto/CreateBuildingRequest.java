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
    private Integer numberOfFloors;
    private String buildingState;
    private Double facadeWidth;
    private Double landArea;
    private Double landWidth;
    private Double builtArea;
    private Boolean hasElevator;
    private Boolean hasHandicapAccess;
    private Boolean hasPool;
    private Boolean hasCableTv;

    @NotNull(message = "Address is required")
    private CreateAddressRequest address;
}

