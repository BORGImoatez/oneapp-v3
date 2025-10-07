package be.delomid.oneapp.mschat.mschat.dto;

import be.delomid.oneapp.mschat.mschat.model.VoteType;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
public class VoteDto {
    private Long id;
    private String title;
    private String description;
    private Long channelId;
    private String createdBy;
    private VoteType voteType;
    private Boolean isActive;
    private Boolean isAnonymous;
    private LocalDateTime endDate;
    private List<VoteOptionDto> options;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private Boolean hasVoted;
    private Long totalVotes;
}