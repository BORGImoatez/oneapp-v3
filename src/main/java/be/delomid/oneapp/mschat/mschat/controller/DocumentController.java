package be.delomid.oneapp.mschat.mschat.controller;

import be.delomid.oneapp.mschat.mschat.dto.*;
import be.delomid.oneapp.mschat.mschat.dto.BuildingMembersDto;
import be.delomid.oneapp.mschat.mschat.service.DocumentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.List;

@RestController
@RequestMapping("/documents")
@RequiredArgsConstructor
@Slf4j
public class DocumentController {

    private final DocumentService documentService;

    private String getUserEmail(Authentication authentication) {
        if (authentication == null || authentication.getName() == null) {
            throw new RuntimeException("Authentication requise");
        }
        return authentication.getName();
    }

    @PostMapping("/folders")
    public ResponseEntity<FolderDto> createFolder(
            @Valid @RequestBody CreateFolderRequest request,
            Authentication authentication) {
        try {
            String email = getUserEmail(authentication);
            log.info("Création d'un dossier: {} par utilisateur: {}", request.getName(), email);
            FolderDto folder = documentService.createFolder(request, email);
            return ResponseEntity.ok(folder);
        } catch (RuntimeException e) {
            log.error("Échec de la création du dossier: {}", e.getMessage());
            throw e;
        }
    }

    @PutMapping("/folders/{folderId}/permissions")
    public ResponseEntity<FolderDto> updateFolderPermissions(
            @PathVariable Long folderId,
            @Valid @RequestBody be.delomid.oneapp.mschat.mschat.dto.UpdateFolderPermissionsRequest request,
            Authentication authentication) {
        try {
            String email = getUserEmail(authentication);
            log.info("Mise à jour des permissions du dossier {} par utilisateur: {}", folderId, email);
            FolderDto folder = documentService.updateFolderPermissions(folderId, request, email);
            return ResponseEntity.ok(folder);
        } catch (RuntimeException e) {
            log.error("Échec de la mise à jour des permissions: {}", e.getMessage());
            throw e;
        }
    }

    @GetMapping("/folders")
    public ResponseEntity<List<FolderDto>> getRootFolders(Authentication authentication) {
        try {
            String email = getUserEmail(authentication);
            log.debug("Récupération des dossiers racine pour utilisateur: {}", email);
            List<FolderDto> folders = documentService.getRootFolders(email);
            return ResponseEntity.ok(folders);
        } catch (RuntimeException e) {
            log.error("Échec de la récupération des dossiers racine: {}", e.getMessage());
            throw e;
        }
    }

    @GetMapping("/building-members")
    public ResponseEntity<BuildingMembersDto> getBuildingMembers(Authentication authentication) {
        try {
            String email = getUserEmail(authentication);
            log.debug("Récupération des membres de l'immeuble pour utilisateur: {}", email);
            BuildingMembersDto members = documentService.getBuildingMembers(email);
            return ResponseEntity.ok(members);
        } catch (RuntimeException e) {
            log.error("Échec de la récupération des membres: {}", e.getMessage());
            throw e;
        }
    }

    @GetMapping("/folders/{folderId}/subfolders")
    public ResponseEntity<List<FolderDto>> getSubFolders(
            @PathVariable Long folderId,
            Authentication authentication) {
        try {
            String email = getUserEmail(authentication);
            log.debug("Récupération des sous-dossiers du dossier {} pour utilisateur: {}", folderId, email);
            List<FolderDto> folders = documentService.getSubFolders(folderId, email);
            return ResponseEntity.ok(folders);
        } catch (RuntimeException e) {
            log.error("Échec de la récupération des sous-dossiers: {}", e.getMessage());
            throw e;
        }
    }

    @GetMapping("/folders/{folderId}/documents")
    public ResponseEntity<List<DocumentDto>> getFolderDocuments(
            @PathVariable Long folderId,
            Authentication authentication) {
        try {
            String email = getUserEmail(authentication);
            log.debug("Récupération des documents du dossier {} pour utilisateur: {}", folderId, email);
            List<DocumentDto> documents = documentService.getFolderDocuments(folderId, email);
            return ResponseEntity.ok(documents);
        } catch (RuntimeException e) {
            log.error("Échec de la récupération des documents: {}", e.getMessage());
            throw e;
        }
    }

    @PostMapping("/folders/{folderId}/upload")
    public ResponseEntity<DocumentDto> uploadDocument(
            @PathVariable Long folderId,
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "description", required = false) String description,
            Authentication authentication) {
        try {
            String email = getUserEmail(authentication);
            log.info("Upload de fichier dans le dossier {} par utilisateur: {}", folderId, email);
            DocumentDto document = documentService.uploadDocument(folderId, file, description, email);
            return ResponseEntity.ok(document);
        } catch (IllegalArgumentException e) {
            log.error("Argument invalide lors de l'upload: {}", e.getMessage());
            throw e;
        } catch (RuntimeException e) {
            log.error("Échec de l'upload du document: {}", e.getMessage());
            throw e;
        }
    }

    @DeleteMapping("/folders/{folderId}")
    public ResponseEntity<Void> deleteFolder(
            @PathVariable Long folderId,
            Authentication authentication) {
        try {
            String email = getUserEmail(authentication);
            log.info("Suppression du dossier {} par utilisateur: {}", folderId, email);
            documentService.deleteFolder(folderId, email);
            return ResponseEntity.ok().build();
        } catch (RuntimeException e) {
            log.error("Échec de la suppression du dossier: {}", e.getMessage());
            throw e;
        }
    }

    @DeleteMapping("/{documentId}")
    public ResponseEntity<Void> deleteDocument(
            @PathVariable Long documentId,
            Authentication authentication) {
        try {
            String email = getUserEmail(authentication);
            log.info("Suppression du document {} par utilisateur: {}", documentId, email);
            documentService.deleteDocument(documentId, email);
            return ResponseEntity.ok().build();
        } catch (RuntimeException e) {
            log.error("Échec de la suppression du document: {}", e.getMessage());
            throw e;
        }
    }

    @GetMapping("/{documentId}/download")
    public ResponseEntity<byte[]> downloadDocument(
            @PathVariable Long documentId,
            Authentication authentication) throws IOException {
        try {
            String email = getUserEmail(authentication);
            log.info("Téléchargement du document {} par utilisateur: {}", documentId, email);

            var document = documentService.getDocumentForDownload(documentId, email);
            byte[] fileContent = documentService.downloadDocument(documentId, email);

            String contentType = document.getMimeType();
            if (contentType == null || contentType.isEmpty()) {
                contentType = "application/octet-stream";
            }

            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + document.getOriginalFilename() + "\"")
                    .contentType(MediaType.parseMediaType(contentType))
                    .body(fileContent);
        } catch (IOException e) {
            log.error("Échec du téléchargement du document: {}", e.getMessage());
            throw e;
        } catch (RuntimeException e) {
            log.error("Échec du téléchargement du document: {}", e.getMessage());
            throw e;
        }
    }

    @GetMapping("/{documentId}/preview")
    public ResponseEntity<byte[]> previewDocument(
            @PathVariable Long documentId,
            Authentication authentication) throws IOException {
        try {
            String email = getUserEmail(authentication);
            log.info("Aperçu du document {} par utilisateur: {}", documentId, email);

            var document = documentService.getDocumentForDownload(documentId, email);
            byte[] fileContent = documentService.downloadDocument(documentId, email);

            String contentType = document.getMimeType();
            if (contentType == null || contentType.isEmpty()) {
                contentType = "application/octet-stream";
            }

            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + document.getOriginalFilename() + "\"")
                    .contentType(MediaType.parseMediaType(contentType))
                    .body(fileContent);
        } catch (IOException e) {
            log.error("Échec de l'aperçu du document: {}", e.getMessage());
            throw e;
        } catch (RuntimeException e) {
            log.error("Échec de l'aperçu du document: {}", e.getMessage());
            throw e;
        }
    }

    @GetMapping("/search")
    public ResponseEntity<List<DocumentDto>> searchDocuments(
            @RequestParam String query,
            Authentication authentication) {
        try {
            String email = getUserEmail(authentication);
            log.info("Recherche de documents avec la requête: '{}' par utilisateur: {}", query, email);
            List<DocumentDto> documents = documentService.searchDocuments(query, email);
            return ResponseEntity.ok(documents);
        } catch (RuntimeException e) {
            log.error("Échec de la recherche de documents: {}", e.getMessage());
            throw e;
        }
    }
}
