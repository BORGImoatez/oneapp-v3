package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.ApartmentExterior;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ApartmentExteriorRepository extends JpaRepository<ApartmentExterior, Long> {
    Optional<ApartmentExterior> findByApartmentId(String apartmentId);
    void deleteByApartmentId(String apartmentId);
}
