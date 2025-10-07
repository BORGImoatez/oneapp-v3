package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.Apartment;
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
public interface ApartmentRepository extends JpaRepository<Apartment, String> {

    List<Apartment> findByBuildingBuildingId(String buildingId);

    Page<Apartment> findByBuildingBuildingId(String buildingId, Pageable pageable);

    @Query("SELECT a FROM Apartment a WHERE a.building.buildingId = :buildingId AND a.resident IS NULL")
    List<Apartment> findAvailableApartmentsByBuildingId(@Param("buildingId") String buildingId);

    @Query("SELECT a FROM Apartment a WHERE a.building.buildingId = :buildingId AND a.resident IS NOT NULL")
    List<Apartment> findOccupiedApartmentsByBuildingId(@Param("buildingId") String buildingId);

    Optional<Apartment> findByResidentIdUsers(String userId);

    @Query("SELECT a FROM Apartment a WHERE a.resident.email = :email")
    Optional<Apartment> findByResidentEmail(@Param("email") String email);

    @Query("SELECT a FROM Apartment a WHERE a.apartmentFloor = :floor AND a.building.buildingId = :buildingId")
    List<Apartment> findByFloorAndBuildingId(@Param("floor") Integer floor, @Param("buildingId") String buildingId);
}