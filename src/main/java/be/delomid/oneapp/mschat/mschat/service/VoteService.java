package be.delomid.oneapp.mschat.mschat.service;

import be.delomid.oneapp.mschat.mschat.dto.*;
import be.delomid.oneapp.mschat.mschat.exception.UnauthorizedAccessException;
import be.delomid.oneapp.mschat.mschat.interceptor.JwtWebSocketInterceptor;
import be.delomid.oneapp.mschat.mschat.model.*;
import be.delomid.oneapp.mschat.mschat.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class VoteService {

    private final VoteRepository voteRepository;
    private final VoteOptionRepository voteOptionRepository;
    private final UserVoteRepository userVoteRepository;
    private final ChannelRepository channelRepository;
    private final ChannelMemberRepository channelMemberRepository;
    private final ResidentRepository residentRepository;
    private final ResidentBuildingRepository residentBuildingRepository;

    @Transactional
    public VoteDto createVote(CreateVoteRequest request, String createdBy) {
        log.debug("Creating vote: {} by user: {}", request.getTitle(), createdBy);

        // Vérifier que le canal existe
        Channel channel = channelRepository.findById(request.getChannelId())
                .orElseThrow(() -> new IllegalArgumentException("Channel not found: " + request.getChannelId()));

        // Vérifier le contexte immeuble
        validateChannelBuildingAccess(channel, createdBy);

        // Vérifier que l'utilisateur est admin pour créer des votes
        validateVoteCreationAccess(createdBy);

        // Créer le vote
        Vote vote = Vote.builder()
                .title(request.getTitle())
                .description(request.getDescription())
                .channel(channel)
                .createdBy(createdBy)
                .voteType(request.getVoteType())
                .isAnonymous(request.getIsAnonymous())
                .endDate(request.getEndDate())
                .build();

        vote = voteRepository.save(vote);

        // Créer les options
        for (String optionText : request.getOptions()) {
            VoteOption option = VoteOption.builder()
                    .text(optionText)
                    .vote(vote)
                    .build();
            voteOptionRepository.save(option);
        }

        return convertToDto(vote, createdBy);
    }

    @Transactional
    public void submitVote(VoteRequest request, String userId) {
        Vote vote = voteRepository.findById(request.getVoteId())
                .orElseThrow(() -> new IllegalArgumentException("Vote not found: " + request.getVoteId()));

        // Vérifier que le vote est actif
        if (!vote.getIsActive()) {
            throw new IllegalStateException("Vote is not active");
        }

        // Vérifier que le vote n'est pas expiré
        if (vote.getEndDate() != null && vote.getEndDate().isBefore(LocalDateTime.now())) {
            throw new IllegalStateException("Vote has expired");
        }

        // Vérifier que l'utilisateur est membre du canal
        validateChannelMemberAccess(vote.getChannel().getId(), userId);

        // Vérifier que le canal appartient au bâtiment actuel
        validateChannelBuildingAccess(vote.getChannel(), userId);

        // Vérifier que l'utilisateur n'a pas déjà voté
        if (userVoteRepository.existsByVoteIdAndUserId(request.getVoteId(), userId)) {
            throw new IllegalStateException("User has already voted");
        }

        // Vérifier le nombre d'options selon le type de vote
        if (vote.getVoteType() == VoteType.SINGLE_CHOICE && request.getSelectedOptionIds().size() > 1) {
            throw new IllegalArgumentException("Only one option can be selected for single choice vote");
        }

        // Enregistrer les votes
        for (Long optionId : request.getSelectedOptionIds()) {
            VoteOption option = voteOptionRepository.findById(optionId)
                    .orElseThrow(() -> new IllegalArgumentException("Vote option not found: " + optionId));

            if (!option.getVote().getId().equals(request.getVoteId())) {
                throw new IllegalArgumentException("Vote option does not belong to this vote");
            }

            UserVote userVote = UserVote.builder()
                    .vote(vote)
                    .voteOption(option)
                    .userId(userId)
                    .build();

            userVoteRepository.save(userVote);
        }

        log.debug("User {} voted on vote {}", userId, request.getVoteId());
    }

    public List<VoteDto> getChannelVotes(Long channelId, String userId) {
        // Vérifier l'accès au canal
        validateChannelMemberAccess(channelId, userId);

        // Vérifier que le canal appartient au bâtiment actuel
        Channel channel = channelRepository.findById(channelId)
                .orElseThrow(() -> new IllegalArgumentException("Channel not found: " + channelId));
        validateChannelBuildingAccess(channel, userId);

        List<Vote> votes = voteRepository.findByChannelIdOrderByCreatedAtDesc(channelId);
        return votes.stream()
                .map(vote -> convertToDto(vote, userId))
                .collect(Collectors.toList());
    }

    public VoteDto getVoteById(Long voteId, String userId) {
        Vote vote = voteRepository.findById(voteId)
                .orElseThrow(() -> new IllegalArgumentException("Vote not found: " + voteId));

        // Vérifier l'accès au canal
        validateChannelMemberAccess(vote.getChannel().getId(), userId);

        // Vérifier que le canal appartient au bâtiment actuel
        validateChannelBuildingAccess(vote.getChannel(), userId);

        return convertToDto(vote, userId);
    }

    @Transactional
    public VoteDto closeVote(Long voteId, String userId) {
        Vote vote = voteRepository.findById(voteId)
                .orElseThrow(() -> new IllegalArgumentException("Vote not found: " + voteId));

        // Vérifier que l'utilisateur est admin du canal ou créateur du vote
        if (!vote.getCreatedBy().equals(userId)) {
            validateChannelAdminAccess(vote.getChannel().getId(), userId);
        }

        vote.setIsActive(false);
        vote = voteRepository.save(vote);

        log.debug("Vote {} closed by user {}", voteId, userId);
        return convertToDto(vote, userId);
    }




    // Fermer automatiquement les votes expirés
    @Scheduled(fixedRate = 60000) // Toutes les minutes
    @Transactional
    public void closeExpiredVotes() {
        List<Vote> expiredVotes = voteRepository.findExpiredActiveVotes(LocalDateTime.now());
        for (Vote vote : expiredVotes) {
            vote.setIsActive(false);
            voteRepository.save(vote);
            log.debug("Vote {} automatically closed due to expiration", vote.getId());
        }
    }

    private void validateChannelAdminAccess(Long channelId, String userId) {
        // Récupérer l'utilisateur
        Resident user = residentRepository.findByEmail(userId)
                .or(() -> residentRepository.findById(userId))
                .orElseThrow(() -> new UnauthorizedAccessException("User not found"));

        // Vérifier si l'utilisateur est admin du bâtiment ou super admin
        if (user.getRole() == UserRole.BUILDING_ADMIN || user.getRole() == UserRole.SUPER_ADMIN) {
            return;
        }

        // Vérifier si l'utilisateur est admin/owner du canal
        ChannelMember member = channelMemberRepository
                .findByChannelIdAndUserId(channelId, user.getIdUsers())
                .orElseThrow(() -> new UnauthorizedAccessException("User is not a member of this channel"));

        if (member.getRole() != MemberRole.OWNER && member.getRole() != MemberRole.ADMIN) {
            throw new UnauthorizedAccessException("User does not have admin access to this channel");
        }
    }

    private void validateVoteCreationAccess(String userId) {
        Resident user = residentRepository.findByEmail(userId)
                .or(() -> residentRepository.findById(userId))
                .orElseThrow(() -> new UnauthorizedAccessException("User not found"));

        // Seuls les admins peuvent créer des votes
        if (user.getRole() != UserRole.BUILDING_ADMIN &&
                user.getRole() != UserRole.GROUP_ADMIN &&
                user.getRole() != UserRole.SUPER_ADMIN) {
            throw new UnauthorizedAccessException("Only building admins can create votes");
        }
    }

    private void validateChannelMemberAccess(Long channelId, String userId) {
        Resident user = residentRepository.findByEmail(userId)
                .or(() -> residentRepository.findById(userId))
                .orElseThrow(() -> new UnauthorizedAccessException("User not found"));

        ChannelMember member = channelMemberRepository
                .findByChannelIdAndUserId(channelId, user.getIdUsers())
                .orElseThrow(() -> new UnauthorizedAccessException("User is not a member of this channel"));

        if (!member.getIsActive()) {
            throw new UnauthorizedAccessException("User does not have access to this channel");
        }
    }

    private void validateChannelBuildingAccess(Channel channel, String userId) {
        // Si le canal n'a pas de bâtiment spécifique (PUBLIC), autoriser l'accès
        if (channel.getBuildingId() == null || channel.getType() == ChannelType.PUBLIC) {
            return;
        }

        // Récupérer l'utilisateur et son bâtiment actuel
        Resident user = residentRepository.findByEmail(userId)
                .or(() -> residentRepository.findById(userId))
                .orElseThrow(() -> new UnauthorizedAccessException("User not found"));

        String currentBuildingId = getCurrentUserBuildingId(user);

        // Vérifier que le canal appartient au bâtiment actuel de l'utilisateur
        if (currentBuildingId == null || !currentBuildingId.equals(channel.getBuildingId())) {
            throw new UnauthorizedAccessException("Channel does not belong to user's current building");
        }
    }

    private String getCurrentUserBuildingId(Resident user) {
        // Essayer d'extraire depuis le JWT en priorité
        String buildingIdFromJwt = getCurrentBuildingFromContext();
        if (buildingIdFromJwt != null) {
            return buildingIdFromJwt;
        }

        // Fallback: Chercher dans les relations ResidentBuilding
        List<ResidentBuilding> userBuildings = residentBuildingRepository.findActiveByResidentId(user.getIdUsers());
        if (!userBuildings.isEmpty()) {
            // Si l'utilisateur a plusieurs buildings, on prend le premier
            // Idéalement, le buildingId devrait toujours venir du JWT
            return userBuildings.get(0).getBuilding().getBuildingId();
        }

        return null;
    }

    private String getCurrentBuildingFromContext() {
        try {
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            if (authentication != null) {
                // Vérifier si c'est un JwtPrincipal (WebSocket)
                if (authentication.getPrincipal() instanceof JwtWebSocketInterceptor.JwtPrincipal) {
                    JwtWebSocketInterceptor.JwtPrincipal principal = (JwtWebSocketInterceptor.JwtPrincipal) authentication.getPrincipal();
                    return principal.getBuildingId();
                }
                // Sinon extraire depuis les details (HTTP)
                Object details = authentication.getDetails();
                if (details instanceof Map) {
                    @SuppressWarnings("unchecked")
                    Map<String, Object> detailsMap = (Map<String, Object>) details;
                    Object buildingId = detailsMap.get("buildingId");
                    if (buildingId != null) {
                        log.debug("Building ID extracted from authentication details: {}", buildingId);
                        return buildingId.toString();
                    }
                }
            }
        } catch (Exception e) {
            log.debug("Could not extract building from JWT context: {}", e.getMessage());
        }
        return null;
    }

    private VoteDto convertToDto(Vote vote, String userId) {
        // Calculer les statistiques des options en évitant les références circulaires
        List<VoteOption> options = voteOptionRepository.findByVoteId(vote.getId());
        Long totalVotes = userVoteRepository.countByVoteId(vote.getId());

        List<VoteOptionDto> optionDtos = options.stream()
                .map(option -> {
                    Long voteCount = voteOptionRepository.countVotesByOptionId(option.getId());
                    Double percentage = totalVotes > 0 ? (voteCount.doubleValue() / totalVotes.doubleValue()) * 100 : 0.0;

                    return VoteOptionDto.builder()
                            .id(option.getId())
                            .text(option.getText())
                            .voteCount(voteCount)
                            .percentage(percentage)
                            .build();
                })
                .collect(Collectors.toList());

        // Vérifier si l'utilisateur a voté
        Resident user = residentRepository.findByEmail(userId).orElse(null);
        Boolean hasVoted = user != null && userVoteRepository.existsByVoteIdAndUserId(vote.getId(), user.getIdUsers());

        return VoteDto.builder()
                .id(vote.getId())
                .title(vote.getTitle())
                .description(vote.getDescription())
                .channelId(vote.getChannel().getId())
                .createdBy(vote.getCreatedBy())
                .voteType(vote.getVoteType())
                .isActive(vote.getIsActive())
                .isAnonymous(vote.getIsAnonymous())
                .endDate(vote.getEndDate())
                .options(optionDtos)
                .createdAt(vote.getCreatedAt())
                .updatedAt(vote.getUpdatedAt())
                .hasVoted(hasVoted)
                .totalVotes(totalVotes)
                .build();
    }
}