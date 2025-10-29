package be.delomid.oneapp.mschat.mschat.dto;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
public class ApartmentDto {
    private String id;
    private String idApartment;
    private String apartmentLabel;
    private String apartmentNumber;
    private Integer apartmentFloor;
    private Integer floor;
    private BigDecimal livingAreaSurface;
    private Integer numberOfRooms;
    private Integer numberOfBedrooms;
    private Boolean haveBalconyOrTerrace;
    private Boolean isFurnished;
    private String buildingId;
    private ResidentDto resident;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}