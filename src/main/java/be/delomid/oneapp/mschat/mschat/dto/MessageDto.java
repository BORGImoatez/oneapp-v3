package be.delomid.oneapp.mschat.mschat.dto;

import be.delomid.oneapp.mschat.mschat.model.MessageType;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

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
    private Boolean isEdited;
    private Boolean isDeleted;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}