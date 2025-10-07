package be.delomid.oneapp.mschat.mschat.dto;

import be.delomid.oneapp.mschat.mschat.model.MessageType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class SendMessageRequest {

    @NotNull(message = "Channel ID is required")
    private Long channelId;

    // Content peut être vide pour les fichiers
    private String content;

    private MessageType type = MessageType.TEXT;
    private Long replyToId;
    private Long fileAttachmentId; // ID du fichier uploadé
}