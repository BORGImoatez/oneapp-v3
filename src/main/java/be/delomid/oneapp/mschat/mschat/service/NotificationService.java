package be.delomid.oneapp.mschat.mschat.service;

import be.delomid.oneapp.mschat.mschat.dto.NotificationDto;
import be.delomid.oneapp.mschat.mschat.model.*;
import be.delomid.oneapp.mschat.mschat.repository.NotificationRepository;
import be.delomid.oneapp.mschat.mschat.repository.ResidentRepository;
import be.delomid.oneapp.mschat.mschat.repository.BuildingRepository;
import be.delomid.oneapp.mschat.mschat.repository.ChannelRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final ResidentRepository residentRepository;
    private final BuildingRepository buildingRepository;
    private final ChannelRepository channelRepository;
    private final FCMService fcmService;

    @Transactional
    public Notification createNotification(String residentId, String buildingId, String title, String body,
                                          String type, Long channelId, Long voteId, Long documentId) {
        Resident resident = residentRepository.findById(residentId)
                .orElseThrow(() -> new RuntimeException("Resident not found"));

        Building building = buildingRepository.findById(buildingId)
                .orElseThrow(() -> new RuntimeException("Building not found"));

        Channel channel = null;
        if (channelId != null) {
            channel = channelRepository.findById(channelId).orElse(null);
        }

        Notification notification = Notification.builder()
                .resident(resident)
                .building(building)
                .title(title)
                .body(body)
                .type(type)
                .channel(channel)
                .voteId(voteId)
                .documentId(documentId)
                .isRead(false)
                .createdAt(LocalDateTime.now())
                .build();

        Notification savedNotification = notificationRepository.save(notification);

        if (resident.getFcmToken() != null && !resident.getFcmToken().isEmpty()) {
            try {
                fcmService.sendPushNotification(
                    resident.getFcmToken(),
                    title,
                    body,
                    type,
                    channelId != null ? channelId.toString() : null
                );
                log.info("Push notification sent to resident: {}", residentId);
            } catch (Exception e) {
                log.error("Error sending push notification to resident {}: {}", residentId, e.getMessage());
            }
        }

        return savedNotification;
    }

    public List<NotificationDto> getNotificationsForResident(String residentId) {
        List<Notification> notifications = notificationRepository.findByResidentIdUsersOrderByCreatedAtDesc(residentId);
        return notifications.stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    public List<NotificationDto> getNotificationsForResidentAndBuilding(String residentId, String buildingId) {
        List<Notification> notifications = notificationRepository
                .findByResidentIdUsersAndBuildingBuildingIdOrderByCreatedAtDesc(residentId, buildingId);
        return notifications.stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    public Long getUnreadCount(String residentId) {
        return notificationRepository.countUnreadByResidentId(residentId);
    }

    public Long getUnreadCountForBuilding(String residentId, String buildingId) {
        return notificationRepository.countUnreadByResidentIdAndBuildingId(residentId, buildingId);
    }

    @Transactional
    public void markAsRead(Long notificationId) {
        notificationRepository.markAsRead(notificationId);
    }

    @Transactional
    public void markAllAsRead(String residentId) {
        notificationRepository.markAllAsReadForResident(residentId);
    }

    @Transactional
    public void sendNotification(NotificationDto notificationDto) {
        Resident resident = residentRepository.findById(notificationDto.getResidentId())
                .orElseThrow(() -> new RuntimeException("Resident not found"));

        Building building = null;
        if (notificationDto.getBuildingId() != null) {
            building = buildingRepository.findById(notificationDto.getBuildingId())
                    .orElse(null);
        }

        Channel channel = null;
        if (notificationDto.getChannelId() != null) {
            channel = channelRepository.findById(notificationDto.getChannelId()).orElse(null);
        }

        Notification notification = Notification.builder()
                .resident(resident)
                .building(building)
                .title(notificationDto.getTitle())
                .body(notificationDto.getBody())
                .type(notificationDto.getType())
                .channel(channel)
                .voteId(notificationDto.getVoteId())
                .documentId(notificationDto.getDocumentId())
                .isRead(false)
                .createdAt(LocalDateTime.now())
                .build();

        notificationRepository.save(notification);

        if (resident.getFcmToken() != null && !resident.getFcmToken().isEmpty()) {
            try {
                fcmService.sendPushNotification(
                    resident.getFcmToken(),
                    notificationDto.getTitle(),
                    notificationDto.getBody(),
                    notificationDto.getType(),
                    notificationDto.getRelatedId() != null ? notificationDto.getRelatedId().toString() : null
                );
                log.info("Push notification sent to resident: {}", notificationDto.getResidentId());
            } catch (Exception e) {
                log.error("Error sending push notification to resident {}: {}", notificationDto.getResidentId(), e.getMessage());
            }
        }
    }

    private NotificationDto toDto(Notification notification) {
        return NotificationDto.builder()
                .id(notification.getId())
                .residentId(notification.getResident().getId())
                .buildingId(notification.getBuilding() != null ? notification.getBuilding().getBuildingId() : null)
                .title(notification.getTitle())
                .body(notification.getBody())
                .type(notification.getType())
                .channelId(notification.getChannel() != null ? notification.getChannel().getId() : null)
                .voteId(notification.getVoteId())
                .documentId(notification.getDocumentId())
                .isRead(notification.getIsRead())
                .createdAt(notification.getCreatedAt())
                .readAt(notification.getReadAt())
                .build();
    }
}
