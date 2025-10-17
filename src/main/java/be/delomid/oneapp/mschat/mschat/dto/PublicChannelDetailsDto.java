package be.delomid.oneapp.mschat.mschat.dto;

import be.delomid.oneapp.mschat.mschat.model.ChannelType;
import be.delomid.oneapp.mschat.mschat.model.MessageType;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
public class PublicChannelDetailsDto {
    private Long channelId;
    private String channelName;
    private String channelDescription;
    private ChannelType channelType;
    private LocalDateTime channelCreatedAt;
    private List<PublicMessageDto> messages;

    @Data
    @Builder
    public static class PublicMessageDto {
        private Long messageId;
        private String senderName;
        private String content;
        private MessageType type;
        private LocalDateTime sentAt;
    }
}
