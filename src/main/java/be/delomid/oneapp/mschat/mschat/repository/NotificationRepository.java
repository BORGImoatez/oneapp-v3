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

    List<Notification> findByResidentIdUsersOrderByCreatedAtDesc(String residentId);

    List<Notification> findByResidentIdUsersAndBuildingBuildingIdOrderByCreatedAtDesc(String residentId, String buildingId);

    @Query("SELECT COUNT(n) FROM Notification n WHERE n.resident.idUsers = :residentId AND n.isRead = false")
    Long countUnreadByResidentId(@Param("residentId") String residentId);

    @Query("SELECT COUNT(n) FROM Notification n WHERE n.resident.idUsers = :residentId AND n.building.buildingId = :buildingId AND n.isRead = false")
    Long countUnreadByResidentIdAndBuildingId(@Param("residentId") String residentId, @Param("buildingId") String buildingId);

    @Modifying
    @Query("UPDATE Notification n SET n.isRead = true, n.readAt = CURRENT_TIMESTAMP WHERE n.id = :notificationId")
    void markAsRead(@Param("notificationId") Long notificationId);

    @Modifying
    @Query("UPDATE Notification n SET n.isRead = true, n.readAt = CURRENT_TIMESTAMP WHERE n.resident.idUsers = :residentId AND n.isRead = false")
    void markAllAsReadForResident(@Param("residentId") String residentId);
}
