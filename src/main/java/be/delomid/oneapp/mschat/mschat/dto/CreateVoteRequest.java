package be.delomid.oneapp.mschat.mschat.dto;

import be.delomid.oneapp.mschat.mschat.model.VoteType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

@Data
public class CreateVoteRequest {

    @NotBlank(message = "Vote title is required")
    private String title;

    private String description;

    @NotNull(message = "Channel ID is required")
    private Long channelId;

    private VoteType voteType = VoteType.SINGLE_CHOICE;

    private Boolean isAnonymous = false;

    private LocalDateTime endDate;

    @NotEmpty(message = "Vote options are required")
    private List<String> options;
}