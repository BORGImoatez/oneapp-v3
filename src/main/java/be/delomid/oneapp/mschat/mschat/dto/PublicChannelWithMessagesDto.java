package be.delomid.oneapp.mschat.mschat.dto;

import be.delomid.oneapp.mschat.mschat.model.ChannelType;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
public class PublicChannelWithMessagesDto {
    private Long id;
    private String name;
    private String description;
    private ChannelType type;
    private String buildingId;
    private Boolean isPrivate;
    private LocalDateTime createdAt;
    private List<MessageDto> messages;
}
