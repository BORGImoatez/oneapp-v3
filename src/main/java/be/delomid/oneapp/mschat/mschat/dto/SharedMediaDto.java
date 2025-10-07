package be.delomid.oneapp.mschat.mschat.dto;

import be.delomid.oneapp.mschat.mschat.model.MessageType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SharedMediaDto {
    private Long messageId;
    private String mediaUrl;
    private MessageType messageType;
    private String senderId;
    private String senderName;
    private LocalDateTime createdAt;
    private String messageContent;
}
