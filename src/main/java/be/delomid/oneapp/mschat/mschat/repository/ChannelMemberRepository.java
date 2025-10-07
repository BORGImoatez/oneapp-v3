package be.delomid.oneapp.mschat.mschat.repository;

  import be.delomid.oneapp.mschat.mschat.model.ChannelMember;
  import be.delomid.oneapp.mschat.mschat.model.MemberRole;
  import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ChannelMemberRepository extends JpaRepository<ChannelMember, Long> {

    @Query("SELECT cm FROM ChannelMember cm WHERE cm.channel.id = :channelId AND cm.userId = :userId AND cm.isActive = true")
    Optional<ChannelMember> findByChannelIdAndUserId(@Param("channelId") Long channelId, @Param("userId") String userId);

    @Query("SELECT cm FROM ChannelMember cm WHERE cm.channel.id = :channelId AND cm.isActive = true")
    List<ChannelMember> findActiveByChannelId(@Param("channelId") Long channelId);

    @Query("SELECT cm FROM ChannelMember cm WHERE cm.channel.id = :channelId AND cm.role IN :roles AND cm.isActive = true")
    List<ChannelMember> findByChannelIdAndRoles(@Param("channelId") Long channelId, @Param("roles") List<MemberRole> roles);

    @Query("SELECT COUNT(cm) FROM ChannelMember cm WHERE cm.channel.id = :channelId AND cm.isActive = true")
    Long countActiveByChannelId(@Param("channelId") Long channelId);
}