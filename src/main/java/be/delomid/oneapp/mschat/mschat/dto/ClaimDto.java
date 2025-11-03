package be.delomid.oneapp.mschat.mschat.dto;

import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.List;

@Getter
@Setter
public class ClaimDto {
    private Long id;
    private String apartmentId;
    private String apartmentNumber;
    private String buildingId;
    private String buildingName;
    private String reporterId;
    private String reporterName;
    private String reporterAvatar;
    private List<String> claimTypes;
    private String cause;
    private String description;
    private String insuranceCompany;
    private String insurancePolicyNumber;
    private String status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private List<String> affectedApartmentIds;
    private List<ClaimPhotoDto> photos;
    private Long emergencyChannelId;
    private Long emergencyFolderId;
}
