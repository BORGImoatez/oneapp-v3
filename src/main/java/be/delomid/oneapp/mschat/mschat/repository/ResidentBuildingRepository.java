package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.MemberRole;
import be.delomid.oneapp.mschat.mschat.model.ResidentBuilding;
import be.delomid.oneapp.mschat.mschat.model.UserRole;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ResidentBuildingRepository extends JpaRepository<ResidentBuilding, Long> {

    @Query("SELECT rb FROM ResidentBuilding rb WHERE rb.resident.idUsers = :residentId AND rb.isActive = true")
    List<ResidentBuilding> findActiveByResidentId(@Param("residentId") String residentId);

    @Query("SELECT rb FROM ResidentBuilding rb WHERE rb.resident.email = :email AND rb.isActive = true")
    List<ResidentBuilding> findActiveByResidentEmail(@Param("email") String email);

    @Query("SELECT rb FROM ResidentBuilding rb WHERE rb.resident.id = :residentId AND rb.building.id = :buildingId AND rb.isActive = true")
    List<ResidentBuilding> findByResidentIdAndBuildingId(@Param("residentId") Long residentId, @Param("buildingId") Long buildingId);

    @Query("SELECT rb FROM ResidentBuilding rb WHERE rb.resident.email = :email AND rb.building.buildingId = :buildingId AND rb.isActive = true")
    Optional<ResidentBuilding> findByResidentEmailAndBuildingId(@Param("email") String email, @Param("buildingId") String buildingId);

    @Query("SELECT rb FROM ResidentBuilding rb WHERE rb.building.buildingId = :buildingId AND rb.isActive = true")
    List<ResidentBuilding> findActiveByBuildingId(@Param("buildingId") String buildingId);

    @Query("SELECT rb FROM ResidentBuilding rb WHERE rb.building.id = :buildingId AND rb.role = :role AND rb.isActive = true")
    List<ResidentBuilding> findByBuildingIdAndRole(@Param("buildingId") Long buildingId, @Param("role") MemberRole role);

    @Query("SELECT rb FROM ResidentBuilding rb WHERE rb.building.id = :buildingId AND rb.apartment.id = :apartmentId AND rb.isActive = true")
    List<ResidentBuilding> findByBuildingIdAndApartmentId(@Param("buildingId") Long buildingId, @Param("apartmentId") Long apartmentId);

    @Query("SELECT rb FROM ResidentBuilding rb WHERE rb.building.buildingId = :buildingId AND rb.isActive = true")
    List<ResidentBuilding> findByBuildingId(@Param("buildingId") String buildingId);
}