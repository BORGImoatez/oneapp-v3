package be.delomid.oneapp.mschat.mschat.dto;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
public class BuildingDto {
    private String buildingId;
    private String buildingLabel;
    private String buildingNumber;
    private String buildingPicture;
    private Integer yearOfConstruction;
    private AddressDto address;
    private List<ApartmentDto> apartments;
    private Long totalApartments;
    private Long occupiedApartments;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}