package be.delomid.oneapp.mschat.mschat.dto;

import be.delomid.oneapp.mschat.mschat.model.MessageType;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.Map;

@Data
@Builder
public class MessageDto {
    private Long id;
    private Long channelId;
    private String senderId;
    private String senderFname;
    private String senderLname;
    private String senderPicture;
    private String content;
    private MessageType type;
    private Long replyToId;
    private FileAttachmentDto fileAttachment;
    private Map<String, Object> callData;
    private Boolean isEdited;
    private Boolean isDeleted;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}