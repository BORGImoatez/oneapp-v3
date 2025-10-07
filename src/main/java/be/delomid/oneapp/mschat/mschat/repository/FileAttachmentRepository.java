package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.FileAttachment;
import be.delomid.oneapp.mschat.mschat.model.FileType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface FileAttachmentRepository extends JpaRepository<FileAttachment, Long> {

    List<FileAttachment> findByUploadedBy(String uploadedBy);

    Page<FileAttachment> findByUploadedBy(String uploadedBy, Pageable pageable);

    List<FileAttachment> findByFileType(FileType fileType);

    @Query("SELECT f FROM FileAttachment f WHERE f.uploadedBy = :userId AND f.fileType = :fileType")
    Page<FileAttachment> findByUploadedByAndFileType(@Param("userId") String userId,
                                                     @Param("fileType") FileType fileType,
                                                     Pageable pageable);

    @Query("SELECT f FROM FileAttachment f WHERE f.createdAt >= :startDate AND f.createdAt <= :endDate")
    List<FileAttachment> findByDateRange(@Param("startDate") LocalDateTime startDate,
                                         @Param("endDate") LocalDateTime endDate);

    @Query("SELECT SUM(f.fileSize) FROM FileAttachment f WHERE f.uploadedBy = :userId")
    Long getTotalFileSizeByUser(@Param("userId") String userId);

    @Query("SELECT f FROM FileAttachment f WHERE f.message.channel.id = :channelId ORDER BY f.createdAt DESC")
    Page<FileAttachment> findByChannelId(@Param("channelId") Long channelId, Pageable pageable);

    @Query("SELECT f FROM FileAttachment f WHERE f.message.channel.id = :channelId AND f.fileType = :fileType ORDER BY f.createdAt DESC")
    Page<FileAttachment> findByChannelIdAndFileType(@Param("channelId") Long channelId, @Param("fileType") FileType fileType, Pageable pageable);

    @Query("SELECT f FROM FileAttachment f WHERE f.message.channel.id = :channelId AND f.fileType IN :fileTypes ORDER BY f.createdAt DESC")
    Page<FileAttachment> findByChannelIdAndFileTypes(@Param("channelId") Long channelId, @Param("fileTypes") List<FileType> fileTypes, Pageable pageable);
}