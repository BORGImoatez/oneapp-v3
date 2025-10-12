package be.delomid.oneapp.mschat.mschat.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class FileService {

    @Value("${app.file.upload-dir:uploads}")
    private String uploadDir;

    @Value("${app.file.max-size:10485760}") // 10MB
    private long maxFileSize;

    public Map<String, Object> uploadFile(MultipartFile file, String type, String userId) {
        validateFile(file, type);

        try {
            // Créer le répertoire s'il n'existe pas
            Path uploadPath = Paths.get(uploadDir);
            if (!Files.exists(uploadPath)) {
                Files.createDirectories(uploadPath);
            }

            // Générer un nom de fichier unique
            String originalFilename = file.getOriginalFilename();
            String extension = getFileExtension(originalFilename);
            String filename = UUID.randomUUID().toString() + extension;

            // Sauvegarder le fichier
            Path filePath = uploadPath.resolve(filename);
            Files.copy(file.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);

            // Construire l'URL complète pour l'accès au fichier
            String baseUrl = "http://192.168.129.223:9090/api/v1/files/";
            String fileUrl = baseUrl + filename;
            String downloadUrl = baseUrl + "download/" + filename;

            // Construire la réponse
            Map<String, Object> response = new HashMap<>();
            response.put("fileId", filename);
            response.put("originalName", originalFilename);
            response.put("size", file.getSize());
            response.put("type", type);
            response.put("mimeType", file.getContentType());
            response.put("url", fileUrl);
            response.put("downloadUrl", downloadUrl);
            response.put("uploadedBy", userId);

            log.info("File uploaded successfully: {} by user: {}", filename, userId);
            return response;

        } catch (IOException e) {
            log.error("Error uploading file", e);
            throw new RuntimeException("Failed to upload file", e);
        }
    }

    public ResponseEntity<byte[]> getFile(String fileId) {
        try {
            Path filePath = Paths.get(uploadDir).resolve(fileId);

            if (!Files.exists(filePath)) {
                return ResponseEntity.notFound().build();
            }

            byte[] fileContent = Files.readAllBytes(filePath);
            String contentType = Files.probeContentType(filePath);

            if (contentType == null) {
                contentType = "application/octet-stream";
            }

            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + fileId + "\"")
                    .contentType(MediaType.parseMediaType(contentType))
                    .body(fileContent);

        } catch (IOException e) {
            log.error("Error retrieving file: {}", fileId, e);
            return ResponseEntity.internalServerError().build();
        }
    }

    public ResponseEntity<byte[]> downloadFile(String fileId) {
        try {
            Path filePath = Paths.get(uploadDir).resolve(fileId);

            if (!Files.exists(filePath)) {
                return ResponseEntity.notFound().build();
            }

            byte[] fileContent = Files.readAllBytes(filePath);
            String contentType = Files.probeContentType(filePath);

            if (contentType == null) {
                contentType = "application/octet-stream";
            }

            // Récupérer le nom original du fichier si possible
            String originalFilename = fileId;

            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + originalFilename + "\"")
                    .contentType(MediaType.parseMediaType(contentType))
                    .body(fileContent);

        } catch (IOException e) {
            log.error("Error downloading file: {}", fileId, e);
            return ResponseEntity.internalServerError().build();
        }
    }

    public void deleteFile(String fileId, String userId) {
        try {
            Path filePath = Paths.get(uploadDir).resolve(fileId);

            if (Files.exists(filePath)) {
                Files.delete(filePath);
                log.info("File deleted: {} by user: {}", fileId, userId);
            }

        } catch (IOException e) {
            log.error("Error deleting file: {}", fileId, e);
            throw new RuntimeException("Failed to delete file", e);
        }
    }

    private void validateFile(MultipartFile file, String type) {
        if (file.isEmpty()) {
            throw new IllegalArgumentException("File is empty");
        }

        if (file.getSize() > maxFileSize) {
            throw new IllegalArgumentException("File size exceeds maximum allowed size");
        }

        String contentType = file.getContentType();
        if (contentType == null) {
            throw new IllegalArgumentException("Invalid file type");
        }

        // Validation selon le type
        switch (type.toUpperCase()) {
            case "IMAGE":
                if (!contentType.startsWith("image/")) {
                    throw new IllegalArgumentException("Invalid image file");
                }
                break;
            case "AUDIO":
                if (!contentType.startsWith("audio/")) {
                    throw new IllegalArgumentException("Invalid audio file");
                }
                break;
            case "FILE":
                // Accepter tous les types de fichiers pour FILE
                break;
            default:
                throw new IllegalArgumentException("Unsupported file type: " + type);
        }
    }

    private String getFileExtension(String filename) {
        if (filename == null || filename.lastIndexOf('.') == -1) {
            return "";
        }
        return filename.substring(filename.lastIndexOf('.'));
    }
}