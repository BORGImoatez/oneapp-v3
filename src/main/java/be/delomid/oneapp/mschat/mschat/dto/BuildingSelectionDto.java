package be.delomid.oneapp.mschat.mschat.dto;

import be.delomid.oneapp.mschat.mschat.model.UserRole;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class BuildingSelectionDto {
    private String buildingId;
    private String buildingLabel;
    private String buildingNumber;
    private String buildingPicture;
    private AddressDto address;
    private UserRole roleInBuilding;
    private String apartmentId;
    private String apartmentLabel;
    private String apartmentNumber;
    private Integer apartmentFloor;
}