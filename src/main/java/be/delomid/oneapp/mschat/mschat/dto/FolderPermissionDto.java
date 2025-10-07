package be.delomid.oneapp.mschat.mschat.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FolderPermissionDto {
    private Long id;
    private String apartmentId;
    private String residentId;
    private Boolean canRead;
    private Boolean canUpload;
}
