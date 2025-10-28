package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.ClaimAffectedApartment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ClaimAffectedApartmentRepository extends JpaRepository<ClaimAffectedApartment, Long> {

    List<ClaimAffectedApartment> findByClaimId(Long claimId);

    void deleteByClaimId(Long claimId);
}
