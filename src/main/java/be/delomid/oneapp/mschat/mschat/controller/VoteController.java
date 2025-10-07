package be.delomid.oneapp.mschat.mschat.controller;

import be.delomid.oneapp.mschat.mschat.dto.*;
import be.delomid.oneapp.mschat.mschat.service.VoteService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/votes")
@RequiredArgsConstructor
public class VoteController {

    private final VoteService voteService;

    @PostMapping
    public ResponseEntity<VoteDto> createVote(
            @Valid @RequestBody CreateVoteRequest request,
            Authentication authentication) {

        String userId = getUserId(authentication);
        VoteDto vote = voteService.createVote(request, userId);
        return ResponseEntity.ok(vote);
    }

    @PostMapping("/submit")
    public ResponseEntity<Void> submitVote(
            @Valid @RequestBody VoteRequest request,
            Authentication authentication) {

        String userId = getUserId(authentication);
        voteService.submitVote(request, userId);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/channel/{channelId}")
    public ResponseEntity<List<VoteDto>> getChannelVotes(
            @PathVariable Long channelId,
            Authentication authentication) {

        String userId = getUserId(authentication);
        List<VoteDto> votes = voteService.getChannelVotes(channelId, userId);
        return ResponseEntity.ok(votes);
    }

    @GetMapping("/{voteId}")
    public ResponseEntity<VoteDto> getVote(
            @PathVariable Long voteId,
            Authentication authentication) {

        String userId = getUserId(authentication);
        VoteDto vote = voteService.getVoteById(voteId, userId);
        return ResponseEntity.ok(vote);
    }

    @PostMapping("/{voteId}/close")
    public ResponseEntity<VoteDto> closeVote(
            @PathVariable Long voteId,
            Authentication authentication) {

        String userId = getUserId(authentication);
        VoteDto vote = voteService.closeVote(voteId, userId);
        return ResponseEntity.ok(vote);
    }

    private String getUserId(Authentication authentication) {
        return authentication.getName();
    }
}