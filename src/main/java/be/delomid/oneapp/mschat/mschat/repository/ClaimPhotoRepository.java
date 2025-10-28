package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.ClaimPhoto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ClaimPhotoRepository extends JpaRepository<ClaimPhoto, Long> {

    List<ClaimPhoto> findByClaimIdOrderByPhotoOrderAsc(Long claimId);

    void deleteByClaimId(Long claimId);
}
