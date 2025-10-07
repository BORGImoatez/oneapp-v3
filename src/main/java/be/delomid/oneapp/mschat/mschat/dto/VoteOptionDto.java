package be.delomid.oneapp.mschat.mschat.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class VoteOptionDto {
    private Long id;
    private String text;
    private Long voteCount;
    private Double percentage;
}