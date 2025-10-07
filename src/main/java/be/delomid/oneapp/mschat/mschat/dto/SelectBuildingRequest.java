package be.delomid.oneapp.mschat.mschat.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class SelectBuildingRequest {

    @NotBlank(message = "Building ID is required")
    private String buildingId;
}