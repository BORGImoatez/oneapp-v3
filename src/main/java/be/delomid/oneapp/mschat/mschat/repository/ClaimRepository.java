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

    List<Claim> findByBuilding_BuildingIdOrderByCreatedAtDesc(String buildingId);


    @Query("SELECT c FROM Claim c WHERE c.building.buildingId = :buildingId " +
           "AND (c.reporter.idUsers = :residentId OR c.apartment.idApartment IN " +
           "(SELECT rb.apartment.idApartment FROM ResidentBuilding rb WHERE rb.resident.idUsers = :residentId) " +
           "OR c.id IN (SELECT caa.claim.id FROM ClaimAffectedApartment caa " +
           "WHERE caa.apartment.idApartment IN (SELECT rb.apartment.idApartment FROM ResidentBuilding rb WHERE rb.resident.idUsers = :residentId))) " +
           "ORDER BY c.createdAt DESC")
    List<Claim> findClaimsByBuildingAndResident(@Param("buildingId") String buildingId, @Param("residentId") String residentId);
}
