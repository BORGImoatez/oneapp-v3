package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.ApartmentGeneralInfo;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ApartmentGeneralInfoRepository extends JpaRepository<ApartmentGeneralInfo, Long> {
    Optional<ApartmentGeneralInfo> findByApartmentId(String apartmentId);
    void deleteByApartmentId(String apartmentId);
}
