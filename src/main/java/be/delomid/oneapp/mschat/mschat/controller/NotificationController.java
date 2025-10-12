package be.delomid.oneapp.mschat.mschat.controller;

import be.delomid.oneapp.mschat.mschat.dto.NotificationDto;
import be.delomid.oneapp.mschat.mschat.service.NotificationService;
import be.delomid.oneapp.mschat.mschat.util.SecurityContextUtil;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/notifications")
@RequiredArgsConstructor
@Slf4j
@Tag(name = "Notifications", description = "API de gestion des notifications")
@SecurityRequirement(name = "Bearer Authentication")
public class NotificationController {

    private final NotificationService notificationService;

    @GetMapping
    @Operation(summary = "Récupérer toutes les notifications de l'utilisateur connecté")
    public ResponseEntity<List<NotificationDto>> getMyNotifications() {
        String userEmail = SecurityContextUtil.getCurrentUserId();
        String residentId = SecurityContextUtil.getCurrentUserId();
        log.debug("Getting notifications for user: {}", userEmail);

        List<NotificationDto> notifications = notificationService.getNotificationsForResident(residentId);
        return ResponseEntity.ok(notifications);
    }

    @GetMapping("/building/{buildingId}")
    @Operation(summary = "Récupérer les notifications d'un bâtiment spécifique")
    public ResponseEntity<List<NotificationDto>> getNotificationsByBuilding(@PathVariable String buildingId) {
        String userEmail = SecurityContextUtil.getCurrentUserId();
        String residentId = SecurityContextUtil.getCurrentUserId();
        log.debug("Getting notifications for user: {} and building: {}", userEmail, buildingId);

        List<NotificationDto> notifications = notificationService.getNotificationsForResidentAndBuilding(residentId, buildingId);
        return ResponseEntity.ok(notifications);
    }

    @GetMapping("/unread-count")
    @Operation(summary = "Récupérer le nombre de notifications non lues")
    public ResponseEntity<Map<String, Long>> getUnreadCount() {
        String residentId = SecurityContextUtil.getCurrentUserId();
        Long count = notificationService.getUnreadCount(residentId);
        return ResponseEntity.ok(Map.of("unreadCount", count));
    }

    @GetMapping("/unread-count/building/{buildingId}")
    @Operation(summary = "Récupérer le nombre de notifications non lues pour un bâtiment")
    public ResponseEntity<Map<String, Long>> getUnreadCountByBuilding(@PathVariable String buildingId) {
        String residentId = SecurityContextUtil.getCurrentUserId();
        Long count = notificationService.getUnreadCountForBuilding(residentId, buildingId);
        return ResponseEntity.ok(Map.of("unreadCount", count));
    }

    @PutMapping("/{notificationId}/mark-read")
    @Operation(summary = "Marquer une notification comme lue")
    public ResponseEntity<Void> markAsRead(@PathVariable Long notificationId) {
        log.debug("Marking notification as read: {}", notificationId);
        notificationService.markAsRead(notificationId);
        return ResponseEntity.ok().build();
    }

    @PutMapping("/mark-all-read")
    @Operation(summary = "Marquer toutes les notifications comme lues")
    public ResponseEntity<Void> markAllAsRead() {
        String residentId = SecurityContextUtil.getCurrentUserId();
        log.debug("Marking all notifications as read for resident: {}", residentId);
        notificationService.markAllAsRead(residentId);
        return ResponseEntity.ok().build();
    }
}
