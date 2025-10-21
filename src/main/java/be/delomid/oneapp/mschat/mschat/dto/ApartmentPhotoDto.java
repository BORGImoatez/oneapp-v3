package be.delomid.oneapp.mschat.mschat.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ApartmentPhotoDto {
    private Long id;
    private Long apartmentId;
    private String photoUrl;
    private Integer displayOrder;
    private LocalDateTime uploadedAt;
    private Long uploadedBy;
}
