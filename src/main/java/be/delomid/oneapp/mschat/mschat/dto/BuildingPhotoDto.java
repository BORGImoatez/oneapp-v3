package be.delomid.oneapp.mschat.mschat.dto;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class BuildingPhotoDto {
    private Long id;
    private String buildingId;
    private String photoUrl;
    private Integer photoOrder;
    private String description;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
