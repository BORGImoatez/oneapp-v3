package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.UserVote;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface UserVoteRepository extends JpaRepository<UserVote, Long> {

    @Query("SELECT uv FROM UserVote uv WHERE uv.vote.id = :voteId AND uv.userId = :userId")
    List<UserVote> findByVoteIdAndUserId(@Param("voteId") Long voteId, @Param("userId") String userId);

    @Query("SELECT COUNT(uv) FROM UserVote uv WHERE uv.vote.id = :voteId")
    Long countByVoteId(@Param("voteId") Long voteId);

    boolean existsByVoteIdAndUserId(Long voteId, String userId);
}