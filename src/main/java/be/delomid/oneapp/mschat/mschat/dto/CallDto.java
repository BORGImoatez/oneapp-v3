package be.delomid.oneapp.mschat.mschat.dto;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class CallDto {
    private Long id;
    private Long channelId;
    private String callerId;
    private String callerName;
    private String callerAvatar;
    private String receiverId;
    private String receiverName;
    private String receiverAvatar;
    private LocalDateTime startedAt;
    private LocalDateTime endedAt;
    private Integer durationSeconds;
    private String status;
    private LocalDateTime createdAt;
}
