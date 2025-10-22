package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.ApartmentPhoto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ApartmentPhotoRepository extends JpaRepository<ApartmentPhoto, Long> {
    List<ApartmentPhoto> findByApartmentIdOrderByDisplayOrderAsc(String apartmentId);
    void deleteByApartmentId(String apartmentId);
}
