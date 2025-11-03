package be.delomid.oneapp.mschat.mschat.dto;

import be.delomid.oneapp.mschat.mschat.model.ChannelType;
 import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
public class ChannelDto {
    private Long id;
    private String name;
    private String description;
    private ChannelType type;
    private String buildingId;
    private String buildingGroupId;
    private String createdBy;
    private Boolean isActive;
    private Boolean isPrivate;
    private Boolean isClosed;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private Long memberCount;
    private List<ChannelMemberDto> members;
    private MessageDto lastMessage;
}