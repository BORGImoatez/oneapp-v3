package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.FolderPermission;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface FolderPermissionRepository extends JpaRepository<FolderPermission, Long> {

    @Query("SELECT fp FROM FolderPermission fp WHERE fp.folder.id = :folderId")
    List<FolderPermission> findByFolderId(@Param("folderId") Long folderId);

    @Query("SELECT fp FROM FolderPermission fp WHERE fp.folder.id = :folderId AND fp.apartment.idApartment = :apartmentId")
    List<FolderPermission> findByFolderIdAndApartmentId(@Param("folderId") Long folderId, @Param("apartmentId") String apartmentId);

    @Query("SELECT fp FROM FolderPermission fp WHERE fp.folder.id = :folderId AND fp.resident.idUsers = :residentId")
    List<FolderPermission> findByFolderIdAndResidentId(@Param("folderId") Long folderId, @Param("residentId") String residentId);

    void deleteByFolderId(Long folderId);
}
