package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.Call;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CallRepository extends JpaRepository<Call, Long> {
    List<Call> findByChannelIdOrderByCreatedAtDesc(Long channelId);

    @Query("SELECT c FROM Call c WHERE c.channel.id = :channelId AND (c.caller.idUsers = :userId OR c.receiver.idUsers = :userId) ORDER BY c.createdAt DESC")
    List<Call> findCallsByChannelAndUser(Long channelId, String userId);
}
