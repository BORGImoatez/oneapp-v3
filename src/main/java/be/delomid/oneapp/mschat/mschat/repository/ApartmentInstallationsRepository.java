package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.ApartmentInstallations;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ApartmentInstallationsRepository extends JpaRepository<ApartmentInstallations, Long> {
    Optional<ApartmentInstallations> findByApartmentId(String apartmentId);
    void deleteByApartmentId(String apartmentId);
}
