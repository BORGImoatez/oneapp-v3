package be.delomid.oneapp.mschat.mschat.service;


import be.delomid.oneapp.mschat.mschat.dto.MessageDto;
import be.delomid.oneapp.mschat.mschat.dto.SendMessageRequest;
import be.delomid.oneapp.mschat.mschat.dto.FileAttachmentDto;
import be.delomid.oneapp.mschat.mschat.dto.SharedMediaDto;
import be.delomid.oneapp.mschat.mschat.interceptor.JwtWebSocketInterceptor;
import be.delomid.oneapp.mschat.mschat.exception.ChannelNotFoundException;
import be.delomid.oneapp.mschat.mschat.exception.UnauthorizedAccessException;
import be.delomid.oneapp.mschat.mschat.model.*;
import be.delomid.oneapp.mschat.mschat.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
public class MessageService {

    private final MessageRepository messageRepository;
    private final ChannelRepository channelRepository;
    private final ChannelMemberRepository channelMemberRepository;
    private final ResidentRepository residentRepository;
    private final FileAttachmentRepository fileAttachmentRepository;
    private final ResidentBuildingRepository residentBuildingRepository;
    private final BuildingRepository buildingRepository;
    private final CallRepository callRepository;
    private final NotificationService notificationService;

    @Transactional
    public MessageDto sendMessage(SendMessageRequest request, String senderId) {
        log.debug("Sending message to channel {} from user {}", request.getChannelId(), senderId);

        // Vérifier que le canal existe
        Channel channel = channelRepository.findById(request.getChannelId())
                .orElseThrow(() -> new ChannelNotFoundException("Channel not found: " + request.getChannelId()));

        // Vérifier que l'utilisateur est membre du canal et peut écrire
        validateWriteAccess(request.getChannelId(), senderId);

        // Récupérer le fichier attaché si présent
        FileAttachment fileAttachment = null;
        if (request.getFileAttachmentId() != null) {
            fileAttachment = fileAttachmentRepository.findById(request.getFileAttachmentId())
                    .orElseThrow(() -> new IllegalArgumentException("File attachment not found: " + request.getFileAttachmentId()));

            // Vérifier que l'utilisateur est le propriétaire du fichier
            if (!fileAttachment.getUploadedBy().equals(senderId)) {
                throw new IllegalArgumentException("User does not own this file attachment");
            }
        }

        // Pour les messages avec fichiers, le contenu peut être vide
        String content = request.getContent();
        if (content == null || content.trim().isEmpty()) {
            if (fileAttachment != null) {
                // Pour les images, utiliser l'URL complète
                if (fileAttachment.getFileType() == FileType.IMAGE) {
                    content = "http://109.136.4.153:9090/api/v1/files/" + fileAttachment.getStoredFilename();
                } else {
                    content = fileAttachment.getOriginalFilename();
                }
            } else {
                throw new IllegalArgumentException("Message content or file attachment is required");
            }
        }

        Message message = Message.builder()
                .channel(channel)
                .senderId(senderId)
                .content(content)
                .type(request.getType())
                .replyToId(request.getReplyToId())
                .fileAttachment(fileAttachment)
                .build();

        message = messageRepository.save(message);
        log.debug("Message saved with ID: {}", message.getId());

        // Créer des notifications pour tous les membres du canal sauf l'émetteur
        createNotificationsForMessage(message, senderId, channel);

        return convertToDto(message);
    }

    public Page<MessageDto> getChannelMessages(Long channelId, String userId, Pageable pageable) {
        log.debug("Getting messages for channel {} for user {}", channelId, userId);

        // Vérifier l'accès au canal et que le canal appartient au bâtiment actuel
        validateChannelAccess(channelId, userId);
        validateChannelBuildingAccess(channelId, userId);

        Page<Message> messages = messageRepository.findByChannelIdOrderByCreatedAtDesc(channelId, pageable);
        return messages.map(this::convertToDto);
    }

    @Transactional
    public MessageDto editMessage(Long messageId, String content, String userId) {
        Message message = messageRepository.findById(messageId)
                .orElseThrow(() -> new IllegalArgumentException("Message not found: " + messageId));

        // Vérifier que l'utilisateur est l'auteur du message
        if (!message.getSenderId().equals(userId)) {
            throw new UnauthorizedAccessException("User can only edit their own messages");
        }

        message.setContent(content);
        message.setIsEdited(true);
        message = messageRepository.save(message);

        return convertToDto(message);
    }

    @Transactional
    public void deleteMessage(Long messageId, String userId) {
        Message message = messageRepository.findById(messageId)
                .orElseThrow(() -> new IllegalArgumentException("Message not found: " + messageId));

        // Vérifier que l'utilisateur est l'auteur du message ou admin du canal
        if (!message.getSenderId().equals(userId) && !isChannelAdmin(message.getChannel().getId(), userId)) {
            throw new UnauthorizedAccessException("User can only delete their own messages");
        }

        message.setIsDeleted(true);
        message.setContent("[Message deleted]");
        messageRepository.save(message);

        log.debug("Message {} deleted by user {}", messageId, userId);
    }

    private void validateChannelBuildingAccess(Long channelId, String userId) {
        Channel channel = channelRepository.findById(channelId)
                .orElseThrow(() -> new ChannelNotFoundException("Channel not found: " + channelId));

        // Si le canal n'a pas de bâtiment spécifique (PUBLIC), autoriser l'accès
        if (channel.getBuildingId() == null || channel.getType() == ChannelType.PUBLIC) {
            log.debug("Channel {} is PUBLIC or has no building, access granted", channelId);
            return;
        }

        // Récupérer l'utilisateur et son bâtiment actuel
        Resident user = residentRepository.findByEmail(userId)
                .or(() -> residentRepository.findById(userId))
                .orElseThrow(() -> new UnauthorizedAccessException("User not found"));

        String currentBuildingId = getCurrentUserBuildingId(user);

        log.debug("Validating channel access - Channel ID: {}, Channel Building: {}, User: {}, User Building: {}",
                  channelId, channel.getBuildingId(), userId, currentBuildingId);

        // Vérifier que le canal appartient au bâtiment actuel de l'utilisateur
        if (currentBuildingId == null || !currentBuildingId.equals(channel.getBuildingId())) {
            log.warn("Access denied - Channel building {} does not match user building {}",
                     channel.getBuildingId(), currentBuildingId);
            throw new UnauthorizedAccessException("Channel does not belong to user's current building");
        }

        log.debug("Channel access validated successfully for user {} in building {}", userId, currentBuildingId);
    }

    private String getCurrentUserBuildingId(Resident user) {
        // D'abord essayer de récupérer le building depuis le JWT
        String buildingIdFromJwt = getCurrentBuildingFromContext();
        if (buildingIdFromJwt != null) {
            log.debug("Building ID extracted from JWT: {}", buildingIdFromJwt);
            return buildingIdFromJwt;
        }

        // Fallback: Récupérer le building depuis ResidentBuilding
        List<ResidentBuilding> userBuildings = residentBuildingRepository.findActiveByResidentId(user.getIdUsers());
        if (!userBuildings.isEmpty()) {
            String buildingId = userBuildings.get(0).getBuilding().getBuildingId();
            log.debug("Building ID from ResidentBuilding fallback: {} (user has {} buildings)",
                      buildingId, userBuildings.size());
            return buildingId;
        }

        log.warn("No building found for user: {}", user.getIdUsers());
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

    private void validateChannelAccess(Long channelId, String userId) {
        Optional<Resident> resident=residentRepository.findByEmail(userId);

        Optional<ChannelMember> member = channelMemberRepository
                .findByChannelIdAndUserId(channelId, resident.get().getIdUsers());

        if (member.isEmpty() || !member.get().getIsActive()) {
            throw new UnauthorizedAccessException("User does not have access to this channel");
        }
    }

    private void validateReadAccess(Long channelId, String userId) {
        Optional<Resident> residentOpt = residentRepository.findByEmail(userId);

        Optional<ChannelMember> memberByResidentId = residentOpt
                .flatMap(resident -> channelMemberRepository.findByChannelIdAndUserId(channelId, resident.getIdUsers()));

        Optional<ChannelMember> memberByUserId = channelMemberRepository.findByChannelIdAndUserId(channelId, userId);

        ChannelMember member = memberByResidentId.or(() -> memberByUserId)
                .orElseThrow(() -> new UnauthorizedAccessException("User is not a member of this channel"));

        if (!member.getIsActive()) {
            throw new UnauthorizedAccessException("User does not have access to this channel");
        }
    }

    private void validateWriteAccess(Long channelId, String userId) {
        log.info("userid mn message service1: {}", userId);

        // Essayer de trouver par email → idUsers
        Optional<Resident> residentOpt = residentRepository.findByEmail(userId);

        Optional<ChannelMember> memberByResidentId = residentOpt
                .flatMap(resident -> channelMemberRepository.findByChannelIdAndUserId(channelId, resident.getIdUsers()));

        // Essayer directement avec userId (si déjà un id)
        Optional<ChannelMember> memberByUserId = channelMemberRepository.findByChannelIdAndUserId(channelId, userId);

        // Fusionner les deux
        ChannelMember member = memberByResidentId.or(() -> memberByUserId)
                .orElseThrow(() -> new UnauthorizedAccessException("User is not a member of this channel"));

        log.info("validateWriteAccess -> found member with id: {}", member.getId());

        // Vérifier les droits
        if (!member.getIsActive() || !member.getCanWrite()) {
            throw new UnauthorizedAccessException("User does not have write access to this channel");
        }
    }


    private boolean isChannelAdmin(Long channelId, String userId) {
        return channelMemberRepository.findByChannelIdAndUserId(channelId, userId)
                .map(member -> member.getRole().name().contains("ADMIN") || member.getRole().name().contains("OWNER"))
                .orElse(false);
    }

    private MessageDto convertToDto(Message message) {
        FileAttachmentDto fileAttachmentDto = null;
        if (message.getFileAttachment() != null) {
            FileAttachment file = message.getFileAttachment();
            String baseUrl = "http://109.136.4.153:9090/api/v1/files/";

            fileAttachmentDto = FileAttachmentDto.builder()
                    .id(file.getId())
                    .originalFilename(file.getOriginalFilename())
                    .storedFilename(file.getStoredFilename())
                    .filePath(file.getFilePath())
                    .downloadUrl(baseUrl + "download/" + file.getStoredFilename())
                    .fileSize(file.getFileSize())
                    .mimeType(file.getMimeType())
                    .fileType(file.getFileType())
                    .uploadedBy(file.getUploadedBy())
                    .duration(file.getDuration())
                    .thumbnailPath(file.getThumbnailPath())
                    .thumbnailUrl(file.getThumbnailPath() != null ?
                            baseUrl + file.getThumbnailPath() : null)
                    .createdAt(file.getCreatedAt())
                    .build();
        }

        Resident sender = residentRepository.findById(message.getSenderId()).orElse(null);

        Map<String, Object> callData = null;
        if (message.getType() == MessageType.CALL && message.getCallId() != null) {
            Call call = callRepository.findById(message.getCallId()).orElse(null);
            if (call != null) {
                callData = new HashMap<>();
                callData.put("callId", call.getId());
                callData.put("status", call.getStatus().name());
                callData.put("callerId", call.getCaller().getIdUsers());
                callData.put("callerName", call.getCaller().getFname() + " " + call.getCaller().getLname());
                callData.put("receiverId", call.getReceiver().getIdUsers());
                callData.put("receiverName", call.getReceiver().getFname() + " " + call.getReceiver().getLname());
                callData.put("durationSeconds", call.getDurationSeconds());
                callData.put("createdAt", call.getCreatedAt());
            }
        }

        return MessageDto.builder()
                .id(message.getId())
                .channelId(message.getChannel().getId())
                .senderId(message.getSenderId())
                .senderFname(sender != null ? sender.getFname() : "")
                .senderLname(sender != null ? sender.getLname() : "")
                .senderPicture(sender != null ? sender.getPicture() : null)
                .content(message.getContent())
                .type(message.getType())
                .replyToId(message.getReplyToId())
                .fileAttachment(fileAttachmentDto)
                .callData(callData)
                .isEdited(message.getIsEdited())
                .isDeleted(message.getIsDeleted())
                .createdAt(message.getCreatedAt())
                .updatedAt(message.getUpdatedAt())
                .build();
    }

    @Transactional(readOnly = true)
    public Page<SharedMediaDto> getSharedMedia(Long channelId, String userId, Pageable pageable) {
        validateReadAccess(channelId, userId);

        List<MessageType> mediaTypes = List.of(MessageType.IMAGE, MessageType.VIDEO, MessageType.FILE, MessageType.AUDIO);
        Page<Message> messages = messageRepository.findByChannelIdAndTypeIn(channelId, mediaTypes, pageable);

        return messages.map(this::mapMessageToSharedMediaDto);
    }

    @Transactional(readOnly = true)
    public Page<SharedMediaDto> getSharedMediaByType(Long channelId, MessageType messageType, String userId, Pageable pageable) {
        validateReadAccess(channelId, userId);

        Page<Message> messages = messageRepository.findByChannelIdAndType(channelId, messageType, pageable);

        return messages.map(this::mapMessageToSharedMediaDto);
    }

    @Transactional(readOnly = true)
    public Page<SharedMediaDto> getSharedMediaByTypes(Long channelId, List<MessageType> messageTypes, String userId, Pageable pageable) {
        validateReadAccess(channelId, userId);

        Page<Message> messages = messageRepository.findByChannelIdAndTypeIn(channelId, messageTypes, pageable);

        return messages.map(this::mapMessageToSharedMediaDto);
    }

    private SharedMediaDto mapMessageToSharedMediaDto(Message message) {
        String senderName = residentRepository.findById(message.getSenderId())
                .map(r -> r.getFname() + " " + r.getLname())
                .orElse("Unknown");

        return SharedMediaDto.builder()
                .messageId(message.getId())
                .mediaUrl(message.getContent())
                .messageType(message.getType())
                .senderId(message.getSenderId())
                .senderName(senderName)
                .createdAt(message.getCreatedAt())
                .messageContent(message.getContent())
                .build();
    }

    private void createNotificationsForMessage(Message message, String senderId, Channel channel) {
        try {
            // Récupérer tous les membres actifs du canal sauf l'émetteur
            List<ChannelMember> members = channelMemberRepository.findActiveByChannelId(channel.getId());

            // Récupérer les informations de l'émetteur
            Resident sender = residentRepository.findById(senderId)
                    .or(() -> residentRepository.findByEmail(senderId))
                    .orElse(null);

            if (sender == null) {
                log.warn("Sender not found for notification: {}", senderId);
                return;
            }

            String senderName = sender.getFname() + " " + sender.getLname();
            String notificationTitle;
            String notificationBody;

            // Construire le titre et le corps selon le type de canal
            if (channel.getType() == ChannelType.ONE_TO_ONE) {
                // Pour les discussions privées : Nom Prénom du résident + building label
                String buildingLabel = "";

                // Récupérer le building depuis le channel ou ResidentBuilding
                if (channel.getBuildingId() != null) {
                    buildingLabel = buildingRepository.findById(channel.getBuildingId())
                        .map(Building::getBuildingLabel)
                        .orElse("");
                }

                notificationTitle = senderName;
                if (!buildingLabel.isEmpty()) {
                    notificationTitle += " (" + buildingLabel + ")";
                }

                // Tronquer le message si trop long
                notificationBody = message.getContent().length() > 100
                    ? message.getContent().substring(0, 100) + "..."
                    : message.getContent();
            } else {
                // Pour les canaux : Nom du canal + nom du building
                String buildingLabel = "";
                if (channel.getBuildingId() != null) {
                    buildingLabel = buildingRepository.findById(channel.getBuildingId())
                        .map(Building::getBuildingLabel)
                        .orElse("");
                }

                notificationTitle = channel.getName();
                if (!buildingLabel.isEmpty()) {
                    notificationTitle += " - " + buildingLabel;
                }

                // Corps : Qui a envoyé + message
                notificationBody = senderName + ": " +
                    (message.getContent().length() > 100
                        ? message.getContent().substring(0, 100) + "..."
                        : message.getContent());
            }

            // Créer une notification pour chaque membre (sauf l'émetteur)
            for (ChannelMember member : members) {
                if (!member.getUserId().equals(senderId) && !member.getUserId().equals(sender.getIdUsers())) {
                    try {
                        Resident recipient = residentRepository.findById(member.getUserId()).orElse(null);
                        if (recipient == null) continue;

                        // Déterminer le buildingId pour la notification
                        String buildingId = channel.getBuildingId();
                        if (buildingId == null) {
                            // Essayer de récupérer depuis ResidentBuilding
                            List<ResidentBuilding> recipientBuildings = residentBuildingRepository.findActiveByResidentId(recipient.getIdUsers());
                            if (!recipientBuildings.isEmpty()) {
                                buildingId = recipientBuildings.get(0).getBuilding().getBuildingId();
                            }
                        }

                        if (buildingId != null) {
                            notificationService.createNotification(
                                member.getUserId(),
                                buildingId,
                                notificationTitle,
                                notificationBody,
                                "MESSAGE",
                                channel.getId(),
                                null,
                                null
                            );
                            log.debug("Notification created for user {} in channel {}", member.getUserId(), channel.getId());
                        }
                    } catch (Exception e) {
                        log.error("Error creating notification for member {}: {}", member.getUserId(), e.getMessage());
                    }
                }
            }
        } catch (Exception e) {
            log.error("Error creating notifications for message {}: {}", message.getId(), e.getMessage(), e);
        }
    }
}