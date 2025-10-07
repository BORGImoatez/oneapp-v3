package be.delomid.oneapp.mschat.mschat.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreateFolderRequest {
    @NotBlank(message = "Folder name is required")
    private String name;

    private Long parentFolderId;

    private String description;

    private Boolean isShared;

    private String shareType;

    private List<String> sharedApartmentIds;

    private List<String> sharedResidentIds;

    private Boolean allowUpload;
}
