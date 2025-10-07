package be.delomid.oneapp.mschat.mschat.dto;

 import be.delomid.oneapp.mschat.mschat.model.MemberRole;
 import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class ChannelMemberDto {
    private Long id;
    private String userId;
    private MemberRole role;
    private Boolean canWrite;
    private Boolean isActive;
    private LocalDateTime joinedAt;
    private LocalDateTime leftAt;
}