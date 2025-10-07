package be.delomid.oneapp.mschat.mschat.repository;

 import be.delomid.oneapp.mschat.mschat.model.Building;
 import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface BuildingRepository extends JpaRepository<Building, String> {

    @Query("SELECT b FROM Building b WHERE b.address.ville = :ville")
    List<Building> findByCity(@Param("ville") String ville);

    @Query("SELECT b FROM Building b WHERE b.address.codePostal = :codePostal")
    List<Building> findByPostalCode(@Param("codePostal") String codePostal);

    @Query("SELECT b FROM Building b WHERE b.buildingLabel LIKE %:label%")
    Page<Building> findByBuildingLabelContaining(@Param("label") String label, Pageable pageable);

    @Query("SELECT COUNT(a) FROM Apartment a WHERE a.building.buildingId = :buildingId")
    Long countApartmentsByBuildingId(@Param("buildingId") String buildingId);

    @Query("SELECT COUNT(a) FROM Apartment a WHERE a.building.buildingId = :buildingId AND a.resident IS NOT NULL")
    Long countOccupiedApartmentsByBuildingId(@Param("buildingId") String buildingId);
}