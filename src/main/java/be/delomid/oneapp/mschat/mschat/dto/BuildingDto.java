package be.delomid.oneapp.mschat.mschat.dto;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
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
    private Integer numberOfFloors;
    private String buildingState;
    private BigDecimal facadeWidth;
    private BigDecimal  landArea;
    private BigDecimal  landWidth;
    private BigDecimal  builtArea;
    private Boolean hasElevator;
    private Boolean hasHandicapAccess;
    private Boolean hasPool;
    private Boolean hasCableTv;
    private AddressDto address;
    private List<ApartmentDto> apartments;
    private Long totalApartments;
    private Long occupiedApartments;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}