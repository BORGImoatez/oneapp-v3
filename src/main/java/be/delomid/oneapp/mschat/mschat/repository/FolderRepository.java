package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.Folder;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface FolderRepository extends JpaRepository<Folder, Long> {

    @Query("SELECT f FROM Folder f WHERE f.building.buildingId = :buildingId AND f.parentFolder IS NULL " +
           "AND (f.isShared = true OR f.apartment.idApartment = :apartmentId)")
    List<Folder> findRootFoldersByBuildingAndApartment(@Param("buildingId") String buildingId,
                                                        @Param("apartmentId") String apartmentId);

    @Query("SELECT f FROM Folder f WHERE f.building.buildingId = :buildingId AND f.parentFolder IS NULL")
    List<Folder> findByBuildingIdAndParentFolderIsNull(@Param("buildingId") String buildingId);

    @Query("SELECT f FROM Folder f WHERE f.apartment.idApartment = :apartmentId AND f.parentFolder IS NULL")
    List<Folder> findByApartmentIdAndParentFolderIsNull(@Param("apartmentId") String apartmentId);

    List<Folder> findByParentFolderId(Long parentFolderId);

    @Query("SELECT f FROM Folder f WHERE f.building.buildingId = :buildingId AND f.parentFolder.id = :parentId")
    List<Folder> findByBuildingIdAndParentFolderId(@Param("buildingId") String buildingId,
                                                     @Param("parentId") Long parentId);

    @Query("SELECT f FROM Folder f WHERE f.id = :id AND f.building.buildingId = :buildingId " +
           "AND (f.isShared = true OR f.apartment.idApartment = :apartmentId)")
    Optional<Folder> findByIdAndBuildingAndApartment(@Param("id") Long id,
                                                      @Param("buildingId") String buildingId,
                                                      @Param("apartmentId") String apartmentId);

    @Query("SELECT f FROM Folder f WHERE f.id = :id AND f.building.buildingId = :buildingId")
    Optional<Folder> findByIdAndBuildingId(@Param("id") Long id, @Param("buildingId") String buildingId);

    @Query("SELECT f FROM Folder f WHERE f.apartment.idApartment = :apartmentId AND f.parentFolder.id = :parentId")
    List<Folder> findByApartmentIdAndParentFolderId(@Param("apartmentId") String apartmentId,
                                                     @Param("parentId") Long parentId);

    @Query("SELECT f FROM Folder f WHERE f.id = :id AND f.apartment.idApartment = :apartmentId")
    Optional<Folder> findByIdAndApartmentId(@Param("id") Long id, @Param("apartmentId") String apartmentId);

    @Query("SELECT CASE WHEN COUNT(f) > 0 THEN true ELSE false END FROM Folder f WHERE f.name = :name AND f.parentFolder.id = :parentFolderId AND f.building.buildingId = :buildingId")
    boolean existsByNameAndParentFolderIdAndBuildingId(@Param("name") String name, @Param("parentFolderId") Long parentFolderId, @Param("buildingId") String buildingId);

    @Query("SELECT CASE WHEN COUNT(f) > 0 THEN true ELSE false END FROM Folder f WHERE f.name = :name AND f.parentFolder IS NULL AND f.building.buildingId = :buildingId")
    boolean existsByNameAndParentFolderIsNullAndBuildingId(@Param("name") String name, @Param("buildingId") String buildingId);

    @Query("SELECT CASE WHEN COUNT(f) > 0 THEN true ELSE false END FROM Folder f WHERE f.name = :name AND f.parentFolder.id = :parentFolderId AND f.apartment.idApartment = :apartmentId")
    boolean existsByNameAndParentFolderIdAndApartmentId(@Param("name") String name, @Param("parentFolderId") Long parentFolderId, @Param("apartmentId") String apartmentId);

    @Query("SELECT CASE WHEN COUNT(f) > 0 THEN true ELSE false END FROM Folder f WHERE f.name = :name AND f.parentFolder IS NULL AND f.apartment.idApartment = :apartmentId")
    boolean existsByNameAndParentFolderIsNullAndApartmentId(@Param("name") String name, @Param("apartmentId") String apartmentId);

    @Query("SELECT DISTINCT f FROM Folder f LEFT JOIN f.permissions p " +
           "WHERE f.building.buildingId = :buildingId AND f.parentFolder IS NULL " +
           "AND (f.shareType = 'ALL_APARTMENTS' " +
           "OR (f.shareType = 'PRIVATE' AND f.apartment.idApartment = :apartmentId) " +
           "OR (f.shareType = 'SPECIFIC_APARTMENTS' AND (p.apartment.idApartment = :apartmentId OR p.resident.idUsers = :residentId)) " +
           "OR f.createdBy = :residentId)")
    List<Folder> findAccessibleRootFolders(@Param("buildingId") String buildingId,
                                           @Param("apartmentId") String apartmentId,
                                           @Param("residentId") String residentId);

    @Query("SELECT DISTINCT f FROM Folder f LEFT JOIN f.permissions p " +
           "WHERE f.building.buildingId = :buildingId " +
           "AND (f.shareType = 'ALL_APARTMENTS' " +
           "OR f.createdBy = :residentId " +
           "OR (f.shareType = 'SPECIFIC_APARTMENTS' AND p.resident.idUsers = :residentId))")
    List<Folder> findAccessibleFoldersForAdminWithoutApartment(@Param("buildingId") String buildingId,
                                                                @Param("residentId") String residentId);
}
