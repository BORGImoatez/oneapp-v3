package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.BuildingPhoto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface BuildingPhotoRepository extends JpaRepository<BuildingPhoto, Long> {
    List<BuildingPhoto> findByBuildingBuildingIdOrderByPhotoOrderAsc(String buildingId);
    void deleteByBuildingBuildingId(String buildingId);
}
