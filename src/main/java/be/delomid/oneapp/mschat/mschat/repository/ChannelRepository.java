package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.Channel;
import be.delomid.oneapp.mschat.mschat.model.ChannelType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ChannelRepository extends JpaRepository<Channel, Long> {

    @Query("SELECT c FROM Channel c JOIN c.members m WHERE m.userId = :userId AND m.isActive = true AND c.isActive = true")
    Page<Channel> findChannelsByUserId(@Param("userId") String userId, Pageable pageable);
  @Query("SELECT c FROM Channel c JOIN c.members m WHERE m.userId = :userId AND m.isActive = true AND c.isActive = true " +
           "AND (c.buildingId = :buildingId OR (c.buildingId IS NULL AND c.type = 'PUBLIC'))")
    Page<Channel> findChannelsByUserIdAndBuilding(@Param("userId") String userId, @Param("buildingId") String buildingId, Pageable pageable);

    @Query("SELECT c FROM Channel c JOIN c.members m WHERE m.userId = :userId AND m.isActive = true AND c.isActive = true " +
            "AND c.type = 'ONE_TO_ONE' AND c.buildingId = :buildingId")
    Page<Channel> findDirectChannelsByUserIdAndBuilding(@Param("userId") String userId, @Param("buildingId") String buildingId, Pageable pageable);

    @Query("SELECT c FROM Channel c WHERE c.type = :type AND c.buildingId = :buildingId AND c.isActive = true")
    List<Channel> findByTypeAndBuildingId(@Param("type") ChannelType type, @Param("buildingId") String buildingId);

    @Query("SELECT c FROM Channel c WHERE c.type = :type AND c.buildingId = :buildingId AND c.isActive = true")
    Optional<Channel> findSingleByTypeAndBuildingId(@Param("type") ChannelType type, @Param("buildingId") String buildingId);

    @Query("SELECT c FROM Channel c WHERE c.type = :type AND c.buildingGroupId = :buildingGroupId AND c.isActive = true")
    Optional<Channel> findByTypeAndBuildingGroupId(@Param("type") ChannelType type, @Param("buildingGroupId") String buildingGroupId);

    @Query("SELECT c FROM Channel c JOIN c.members m1 JOIN c.members m2 " +
            "WHERE c.type = 'ONE_TO_ONE' AND m1.userId = :userId1 AND m2.userId = :userId2 " +
            "AND m1.isActive = true AND m2.isActive = true AND c.isActive = true " +
            "AND c.buildingId = :buildingId")
    Optional<Channel> findOneToOneChannel(@Param("userId1") String userId1, @Param("userId2") String userId2, @Param("buildingId") String buildingId);

    List<Channel> findByTypeAndIsActiveTrue(ChannelType type);

    @Query("SELECT c FROM Channel c WHERE c.type = 'PUBLIC' AND c.isActive = true")
    Page<Channel> findPublicChannels(Pageable pageable);
}