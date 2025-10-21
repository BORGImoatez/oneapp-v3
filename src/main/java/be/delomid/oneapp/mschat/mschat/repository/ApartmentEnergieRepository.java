package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.ApartmentEnergie;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ApartmentEnergieRepository extends JpaRepository<ApartmentEnergie, Long> {
    Optional<ApartmentEnergie> findByApartmentId(Long apartmentId);
    void deleteByApartmentId(Long apartmentId);
}
