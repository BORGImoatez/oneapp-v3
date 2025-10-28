package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.Claim;
import be.delomid.oneapp.mschat.mschat.model.ClaimStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ClaimRepository extends JpaRepository<Claim, Long> {

    List<Claim> findByBuildingIdOrderByCreatedAtDesc(Long buildingId);

    List<Claim> findByApartmentIdOrderByCreatedAtDesc(Long apartmentId);

    List<Claim> findByReporterIdOrderByCreatedAtDesc(Long reporterId);

    List<Claim> findByBuildingIdAndStatusOrderByCreatedAtDesc(Long buildingId, ClaimStatus status);

    @Query("SELECT c FROM Claim c WHERE c.building.id = :buildingId " +
           "AND (c.reporter.id = :residentId OR c.apartment.id IN " +
           "(SELECT rb.apartment.id FROM ResidentBuilding rb WHERE rb.resident.id = :residentId) " +
           "OR c.id IN (SELECT caa.claim.id FROM ClaimAffectedApartment caa " +
           "WHERE caa.apartment.id IN (SELECT rb.apartment.id FROM ResidentBuilding rb WHERE rb.resident.id = :residentId))) " +
           "ORDER BY c.createdAt DESC")
    List<Claim> findClaimsByBuildingAndResident(@Param("buildingId") Long buildingId, @Param("residentId") Long residentId);
}
