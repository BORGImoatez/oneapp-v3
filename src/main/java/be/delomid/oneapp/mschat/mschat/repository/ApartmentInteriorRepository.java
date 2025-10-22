package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.ApartmentInterior;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ApartmentInteriorRepository extends JpaRepository<ApartmentInterior, Long> {
    Optional<ApartmentInterior> findByApartmentId(String apartmentId);
    void deleteByApartmentId(String apartmentId);
}
