package be.delomid.oneapp.mschat.mschat.dto;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UpdateFolderPermissionsRequest {
    @NotNull(message = "Share type is required")
    private String shareType;

    private List<String> sharedApartmentIds;

    private List<String> sharedResidentIds;

    private Boolean allowUpload;
}
