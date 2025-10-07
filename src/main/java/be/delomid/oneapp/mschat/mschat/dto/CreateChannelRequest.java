package be.delomid.oneapp.mschat.mschat.dto;

import be.delomid.oneapp.mschat.mschat.model.ChannelType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.List;

@Data
public class CreateChannelRequest {

    @NotBlank(message = "Channel name is required")
    private String name;

    @NotBlank(message = "Channel subject/description is required")
    private String description;

    @NotNull(message = "Channel type is required")
    private ChannelType type = ChannelType.GROUP;

    private String buildingId;
    private String buildingGroupId;
    private Boolean isPrivate = true;

    // Pour les canaux de type GROUP ou ONE_TO_ONE
    private List<String> memberIds;
}