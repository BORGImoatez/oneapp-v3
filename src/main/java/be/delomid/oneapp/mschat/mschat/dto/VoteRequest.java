package be.delomid.oneapp.mschat.mschat.dto;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.List;

@Data
public class VoteRequest {

    @NotNull(message = "Vote ID is required")
    private Long voteId;

    @NotEmpty(message = "Selected options are required")
    private List<Long> selectedOptionIds;
}