package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.Vote;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface VoteRepository extends JpaRepository<Vote, Long> {

    List<Vote> findByChannelIdOrderByCreatedAtDesc(Long channelId);

    @Query("SELECT v FROM Vote v WHERE v.channel.id = :channelId AND v.isActive = true")
    List<Vote> findActiveVotesByChannelId(@Param("channelId") Long channelId);

    @Query("SELECT v FROM Vote v WHERE v.endDate < :now AND v.isActive = true")
    List<Vote> findExpiredActiveVotes(@Param("now") LocalDateTime now);
}