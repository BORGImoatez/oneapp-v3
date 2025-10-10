package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.Notification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, Long> {

    List<Notification> findByResidentIdOrderByCreatedAtDesc(Long residentId);

    List<Notification> findByResidentIdAndBuildingIdOrderByCreatedAtDesc(Long residentId, Long buildingId);

    @Query("SELECT COUNT(n) FROM Notification n WHERE n.resident.id = :residentId AND n.isRead = false")
    Long countUnreadByResidentId(@Param("residentId") Long residentId);

    @Query("SELECT COUNT(n) FROM Notification n WHERE n.resident.id = :residentId AND n.building.id = :buildingId AND n.isRead = false")
    Long countUnreadByResidentIdAndBuildingId(@Param("residentId") Long residentId, @Param("buildingId") Long buildingId);

    @Modifying
    @Query("UPDATE Notification n SET n.isRead = true, n.readAt = CURRENT_TIMESTAMP WHERE n.id = :notificationId")
    void markAsRead(@Param("notificationId") Long notificationId);

    @Modifying
    @Query("UPDATE Notification n SET n.isRead = true, n.readAt = CURRENT_TIMESTAMP WHERE n.resident.id = :residentId AND n.isRead = false")
    void markAllAsReadForResident(@Param("residentId") Long residentId);
}
