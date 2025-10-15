package be.delomid.oneapp.mschat.mschat.repository;

 import be.delomid.oneapp.mschat.mschat.model.AccountStatus;
 import be.delomid.oneapp.mschat.mschat.model.Resident;
 import be.delomid.oneapp.mschat.mschat.model.UserRole;
 import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
 import java.util.UUID;

@Repository
public interface ResidentRepository extends JpaRepository<Resident, String> {

    Optional<Resident> findByEmail(String email);

    @Query("SELECT DISTINCT r FROM Resident r JOIN r.residentBuildings rb WHERE rb.building.buildingId = :buildingId AND rb.isActive = true")
    List<Resident> findByBuildingId(@Param("buildingId") String buildingId);

    @Query("SELECT DISTINCT r FROM Resident r JOIN r.residentBuildings rb WHERE rb.building.buildingId = :buildingId AND rb.isActive = true")
    Page<Resident> findByBuildingId(@Param("buildingId") String buildingId, Pageable pageable);

    @Query("SELECT r FROM Resident r WHERE r.fname LIKE %:name% OR r.lname LIKE %:name%")
    Page<Resident> findByNameContaining(@Param("name") String name, Pageable pageable);

    @Query("SELECT DISTINCT r FROM Resident r JOIN r.residentBuildings rb WHERE rb.apartment.apartmentFloor = :floor AND rb.building.buildingId = :buildingId AND rb.isActive = true")
    List<Resident> findByFloorAndBuildingId(@Param("floor") Integer floor, @Param("buildingId") String buildingId);
    
    @Query("SELECT r FROM Resident r WHERE r.role = :role AND r.managedBuildingId = :buildingId")
    List<Resident> findBuildingAdmins(@Param("role") UserRole role, @Param("buildingId") String buildingId);
    
    @Query("SELECT r FROM Resident r WHERE r.role = :role AND r.managedBuildingGroupId = :buildingGroupId")
    List<Resident> findBuildingGroupAdmins(@Param("role") UserRole  role, @Param("buildingGroupId") String buildingGroupId);
    
    @Query("SELECT r FROM Resident r WHERE r.accountStatus = :status")
    Page<Resident> findByAccountStatus(@Param("status") AccountStatus status, Pageable pageable);
}