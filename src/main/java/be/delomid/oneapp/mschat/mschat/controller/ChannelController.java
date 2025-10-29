package be.delomid.oneapp.mschat.mschat.controller;


import be.delomid.oneapp.mschat.mschat.dto.ChannelDto;
import be.delomid.oneapp.mschat.mschat.dto.CreateChannelRequest;
import be.delomid.oneapp.mschat.mschat.dto.PublicChannelDetailsDto;
import be.delomid.oneapp.mschat.mschat.dto.PublicChannelWithMessagesDto;
import be.delomid.oneapp.mschat.mschat.dto.ResidentDto;
import be.delomid.oneapp.mschat.mschat.interceptor.JwtWebSocketInterceptor;
import be.delomid.oneapp.mschat.mschat.service.ChannelService;
import be.delomid.oneapp.mschat.mschat.repository.ResidentRepository;
import be.delomid.oneapp.mschat.mschat.model.Resident;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/channels")
@RequiredArgsConstructor
public class ChannelController {

    private final ChannelService channelService;
    private final ResidentRepository residentRepository;

    @PostMapping
    public ResponseEntity<ChannelDto> createChannel(
            @Valid @RequestBody CreateChannelRequest request,
            Authentication authentication) {

        String userId = getUserId(authentication);
        ChannelDto channel = channelService.createChannel(request, userId);
        return ResponseEntity.ok(channel);
    }

    @GetMapping
    public ResponseEntity<Page<ChannelDto>> getUserChannels(
            Authentication authentication,
            Pageable pageable) {

        String userId = getUserId(authentication);
        Page<ChannelDto> channels = channelService.getUserChannels(userId, pageable);
        return ResponseEntity.ok(channels);
    }

    @GetMapping("/{channelId}")
    public ResponseEntity<ChannelDto> getChannel(
            @PathVariable Long channelId,
            Authentication authentication) {

        String userId = getUserId(authentication);
        ChannelDto channel = channelService.getChannelById(channelId, userId);
        return ResponseEntity.ok(channel);
    }

    @PostMapping("/{channelId}/join")
    public ResponseEntity<ChannelDto> joinChannel(
            @PathVariable Long channelId,
            Authentication authentication) {

        String userId = getUserId(authentication);
        ChannelDto channel = channelService.joinChannel(channelId, userId);
        return ResponseEntity.ok(channel);
    }

    @PostMapping("/{channelId}/leave")
    public ResponseEntity<Void> leaveChannel(
            @PathVariable Long channelId,
            Authentication authentication) {

        String userId = getUserId(authentication);
        channelService.leaveChannel(channelId, userId);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/{channelId}/members/{memberId}")
    public ResponseEntity<ChannelDto> addMemberToChannel(
            @PathVariable Long channelId,
            @PathVariable String memberId,
            Authentication authentication) {

        String adminId = getUserId(authentication);
        ChannelDto channel = channelService.addMemberToChannel(channelId, memberId, adminId);
        return ResponseEntity.ok(channel);
    }

    @DeleteMapping("/{channelId}/members/{memberId}")
    public ResponseEntity<Void> removeMemberFromChannel(
            @PathVariable Long channelId,
            @PathVariable String memberId,
            Authentication authentication) {

        String adminId = getUserId(authentication);
        channelService.removeMemberFromChannel(channelId, memberId, adminId);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/direct/{otherUserId}")
    public ResponseEntity<ChannelDto> getOrCreateDirectChannel(
            @PathVariable String otherUserId,
            Authentication authentication) {

        String userId = getUserId(authentication);
        Optional<ChannelDto> channel = channelService.getOrCreateOneToOneChannel(userId, otherUserId);

        return channel.map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/building/{buildingId}")
    public ResponseEntity<List<ChannelDto>> getBuildingChannels(
            @PathVariable String buildingId,
            Authentication authentication) {

        String userId = getUserId(authentication);
        List<ChannelDto> channels = channelService.getBuildingChannels(buildingId, userId);
        return ResponseEntity.ok(channels);
    }

    @GetMapping("/building/{buildingId}/residents")
    public ResponseEntity<List<ResidentDto>> getBuildingResidents(
            @PathVariable String buildingId,
            Authentication authentication) {

        String userId = getUserId(authentication);
        List<ResidentDto> residents = channelService.getBuildingResidents(buildingId, userId);
        return ResponseEntity.ok(residents);
    }

    @GetMapping("/current-building/residents")
    public ResponseEntity<List<ResidentDto>> getCurrentBuildingResidents(Authentication authentication) {
        String userId = getUserId(authentication);
        // Utiliser un buildingId factice car la méthode utilise le bâtiment actuel du JWT
        List<ResidentDto> residents = channelService.getBuildingResidents("current", userId);
        return ResponseEntity.ok(residents);
    }

    @PostMapping("/building/{buildingId}/create")
    public ResponseEntity<ChannelDto> createBuildingChannel(
            @PathVariable String buildingId,
            Authentication authentication) {

        String userId = getUserId(authentication);
        ChannelDto channel = channelService.createBuildingChannel(buildingId, userId);
        return ResponseEntity.ok(channel);
    }

    @GetMapping("/public/building/{buildingId}/with-messages")
    public ResponseEntity<List<PublicChannelWithMessagesDto>> getPublicBuildingChannelsWithMessages(
            @PathVariable String buildingId) {

        List<PublicChannelWithMessagesDto> channels = channelService.getPublicBuildingChannelsWithMessages(buildingId);
        return ResponseEntity.ok(channels);
    }

    @GetMapping("/public/{channelId}/details")
    public ResponseEntity<PublicChannelDetailsDto> getPublicChannelDetails(
            @PathVariable Long channelId) {

        PublicChannelDetailsDto channelDetails = channelService.getPublicChannelDetails(channelId);
        return ResponseEntity.ok(channelDetails);
    }

    @GetMapping("/{channelId}/members")
    public ResponseEntity<List<be.delomid.oneapp.mschat.mschat.dto.ChannelMemberDto>> getChannelMembers(
            @PathVariable Long channelId,
            Authentication authentication) {

        String userId = getUserId(authentication);
        List<be.delomid.oneapp.mschat.mschat.dto.ChannelMemberDto> members = channelService.getChannelMembers(channelId, userId);
        return ResponseEntity.ok(members);
    }

    private String getUserId(Authentication authentication) {
        if (authentication.getPrincipal() instanceof JwtWebSocketInterceptor.JwtPrincipal) {
            JwtWebSocketInterceptor.JwtPrincipal principal = (JwtWebSocketInterceptor.JwtPrincipal) authentication.getPrincipal();
            return principal.getName();
        } else if (authentication.getPrincipal() instanceof UserDetails) {
            UserDetails userDetails = (UserDetails) authentication.getPrincipal();
            return userDetails.getUsername();
        }
        return authentication.getName();
    }
}