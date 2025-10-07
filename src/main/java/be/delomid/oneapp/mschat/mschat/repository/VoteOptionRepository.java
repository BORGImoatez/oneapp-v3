package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.VoteOption;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface VoteOptionRepository extends JpaRepository<VoteOption, Long> {

    @Query("SELECT COUNT(uv) FROM UserVote uv WHERE uv.voteOption.id = :optionId")
    Long countVotesByOptionId(@Param("optionId") Long optionId);

    @Query("SELECT vo FROM VoteOption vo WHERE vo.vote.id = :voteId ORDER BY vo.id")
    List<VoteOption> findByVoteId(@Param("voteId") Long voteId);
}