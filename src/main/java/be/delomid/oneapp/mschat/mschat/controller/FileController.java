package be.delomid.oneapp.mschat.mschat.controller;

import be.delomid.oneapp.mschat.mschat.service.FileService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

@RestController
@RequestMapping("/files")
@RequiredArgsConstructor
@Slf4j
public class FileController {

    private final FileService fileService;

    @PostMapping("/upload")
    public ResponseEntity<Map<String, Object>> uploadFile(
            @RequestParam("file") MultipartFile file,
            @RequestParam("type") String type,
            Authentication authentication) {

        String userId = getUserId(authentication);
        Map<String, Object> result = fileService.uploadFile(file, type, userId);
        return ResponseEntity.ok(result);
    }

    @GetMapping("/{fileId}")
    public ResponseEntity<byte[]> getFile(@PathVariable String fileId) {
        return fileService.getFile(fileId);
    }

    @GetMapping("/download/{fileId}")
    public ResponseEntity<byte[]> downloadFile(@PathVariable String fileId) {
        return fileService.downloadFile(fileId);
    }

    @GetMapping("/profiles/{filename}")
    public ResponseEntity<byte[]> getProfilePicture(@PathVariable String filename) {
        return fileService.getProfilePicture(filename);
    }

    @DeleteMapping("/{fileId}")
    public ResponseEntity<Void> deleteFile(
            @PathVariable String fileId,
            Authentication authentication) {

        String userId = getUserId(authentication);
        fileService.deleteFile(fileId, userId);
        return ResponseEntity.ok().build();
    }

    private String getUserId(Authentication authentication) {
        return authentication.getName();
    }
}