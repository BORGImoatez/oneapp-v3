package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.Document;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface DocumentRepository extends JpaRepository<Document, Long> {

    List<Document> findByFolderId(Long folderId);

    @Query("SELECT d FROM Document d WHERE d.building.buildingId = :buildingId")
    List<Document> findByBuildingId(@Param("buildingId") String buildingId);

    @Query("SELECT d FROM Document d WHERE d.building.buildingId = :buildingId")
    Page<Document> findByBuildingId(@Param("buildingId") String buildingId, Pageable pageable);

    @Query("SELECT d FROM Document d WHERE d.id = :id AND d.building.buildingId = :buildingId")
    Optional<Document> findByIdAndBuildingId(@Param("id") Long id, @Param("buildingId") String buildingId);

    @Query("SELECT d FROM Document d WHERE d.building.buildingId = :buildingId " +
           "AND (d.folder.isShared = true OR d.apartment.idApartment = :apartmentId) " +
           "AND (LOWER(d.originalFilename) LIKE LOWER(CONCAT('%', :search, '%')) " +
           "OR LOWER(d.description) LIKE LOWER(CONCAT('%', :search, '%')))")
    List<Document> searchDocumentsByBuildingAndApartment(@Param("buildingId") String buildingId,
                                                          @Param("apartmentId") String apartmentId,
                                                          @Param("search") String search);

    @Query("SELECT d FROM Document d WHERE d.building.buildingId = :buildingId " +
           "AND (LOWER(d.originalFilename) LIKE LOWER(CONCAT('%', :search, '%')) " +
           "OR LOWER(d.description) LIKE LOWER(CONCAT('%', :search, '%')))")
    List<Document> searchDocuments(@Param("buildingId") String buildingId,
                                   @Param("search") String search);

    @Query("SELECT d FROM Document d WHERE d.building.buildingId = :buildingId " +
           "AND LOWER(d.originalFilename) LIKE LOWER(CONCAT('%', :search, '%'))")
    List<Document> searchByBuildingIdAndOriginalFilenameContaining(@Param("buildingId") String buildingId,
                                                                    @Param("search") String search);

    @Query("SELECT d FROM Document d WHERE d.apartment.idApartment = :apartmentId")
    List<Document> findByApartmentId(@Param("apartmentId") String apartmentId);

    @Query("SELECT d FROM Document d WHERE d.apartment.idApartment = :apartmentId")
    Page<Document> findByApartmentId(@Param("apartmentId") String apartmentId, Pageable pageable);

    @Query("SELECT d FROM Document d WHERE d.id = :id AND d.apartment.idApartment = :apartmentId")
    Optional<Document> findByIdAndApartmentId(@Param("id") Long id, @Param("apartmentId") String apartmentId);

    List<Document> findByFolderIdOrderByCreatedAtDesc(Long folderId);

    boolean existsByOriginalFilenameAndFolderId(String originalFilename, Long folderId);
}
