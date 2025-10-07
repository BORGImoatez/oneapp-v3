package be.delomid.oneapp.mschat.mschat.dto;

import be.delomid.oneapp.mschat.mschat.model.FileType;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class FileAttachmentDto {
    private Long id;
    private String originalFilename;
    private String storedFilename;
    private String filePath;
    private String downloadUrl;
    private Long fileSize;
    private String mimeType;
    private FileType fileType;
    private String uploadedBy;
    private Integer duration;
    private String thumbnailPath;
    private String thumbnailUrl;
    private LocalDateTime createdAt;
}