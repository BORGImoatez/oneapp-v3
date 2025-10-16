package be.delomid.oneapp.mschat.mschat.controller;

import be.delomid.oneapp.mschat.mschat.dto.ChangePasswordRequest;
import be.delomid.oneapp.mschat.mschat.dto.ResidentDto;
import be.delomid.oneapp.mschat.mschat.dto.UpdateProfileRequest;
import be.delomid.oneapp.mschat.mschat.service.ProfileService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;

@RestController
@RequestMapping("/profile")
@RequiredArgsConstructor
@Slf4j
@Tag(name = "Profile Management", description = "APIs pour la gestion du profil utilisateur")
public class ProfileController {

    private final ProfileService profileService;

    @GetMapping
    @Operation(summary = "Obtenir le profil actuel", description = "Récupère les informations du profil de l'utilisateur connecté")
    public ResponseEntity<ResidentDto> getCurrentProfile() {
        log.debug("Getting current user profile");
        ResidentDto profile = profileService.getCurrentProfile();
        return ResponseEntity.ok(profile);
    }

    @PutMapping
    @Operation(summary = "Mettre à jour le profil", description = "Met à jour les informations du profil (nom, prénom, email, téléphone)")
    public ResponseEntity<ResidentDto> updateProfile(@RequestBody UpdateProfileRequest request) {
        log.debug("Updating profile: {}", request);
        ResidentDto updatedProfile = profileService.updateProfile(request);
        return ResponseEntity.ok(updatedProfile);
    }

    @PostMapping(value = "/picture", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Télécharger une photo de profil", description = "Upload une nouvelle photo de profil")
    public ResponseEntity<ResidentDto> uploadProfilePicture(@RequestParam("file") MultipartFile file) {
        log.debug("Uploading profile picture: {}", file.getOriginalFilename());
        try {
            ResidentDto updatedProfile = profileService.uploadProfilePicture(file);
            return ResponseEntity.ok(updatedProfile);
        } catch (IOException e) {
            log.error("Failed to upload profile picture", e);
            return ResponseEntity.internalServerError().build();
        }
    }

    @DeleteMapping("/picture")
    @Operation(summary = "Supprimer la photo de profil", description = "Supprime la photo de profil actuelle")
    public ResponseEntity<Void> deleteProfilePicture() {
        log.debug("Deleting profile picture");
        profileService.deleteProfilePicture();
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/change-password")
    @Operation(summary = "Changer le mot de passe", description = "Change le mot de passe de l'utilisateur")
    public ResponseEntity<Void> changePassword(@RequestBody ChangePasswordRequest request) {
        log.debug("Changing password");
        try {
            profileService.changePassword(request);
            return ResponseEntity.ok().build();
        } catch (IllegalArgumentException e) {
            log.error("Failed to change password: {}", e.getMessage());
            return ResponseEntity.badRequest().build();
        }
    }
}
