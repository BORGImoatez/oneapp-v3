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

    @Transactional
    public Notification createNotification(Long residentId, Long buildingId, String title, String body,
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

        return notificationRepository.save(notification);
    }

    public List<NotificationDto> getNotificationsForResident(Long residentId) {
        List<Notification> notifications = notificationRepository.findByResidentIdOrderByCreatedAtDesc(residentId);
        return notifications.stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    public List<NotificationDto> getNotificationsForResidentAndBuilding(Long residentId, Long buildingId) {
        List<Notification> notifications = notificationRepository
                .findByResidentIdAndBuildingIdOrderByCreatedAtDesc(residentId, buildingId);
        return notifications.stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    public Long getUnreadCount(Long residentId) {
        return notificationRepository.countUnreadByResidentId(residentId);
    }

    public Long getUnreadCountForBuilding(Long residentId, Long buildingId) {
        return notificationRepository.countUnreadByResidentIdAndBuildingId(residentId, buildingId);
    }

    @Transactional
    public void markAsRead(Long notificationId) {
        notificationRepository.markAsRead(notificationId);
    }

    @Transactional
    public void markAllAsRead(Long residentId) {
        notificationRepository.markAllAsReadForResident(residentId);
    }

    private NotificationDto toDto(Notification notification) {
        return NotificationDto.builder()
                .id(notification.getId())
                .residentId(notification.getResident().getId())
                .buildingId(notification.getBuilding().getId())
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
