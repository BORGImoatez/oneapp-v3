package be.delomid.oneapp.mschat.mschat.controller;

import be.delomid.oneapp.mschat.mschat.dto.ApartmentDetailsDto;
import be.delomid.oneapp.mschat.mschat.dto.ApartmentPhotoDto;
import be.delomid.oneapp.mschat.mschat.dto.UpdateApartmentDetailsRequest;
import be.delomid.oneapp.mschat.mschat.service.ApartmentDetailsService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/api/apartments/{apartmentId}/details")
@RequiredArgsConstructor
@Tag(name = "Apartment Details", description = "Endpoints for managing apartment details")
@SecurityRequirement(name = "bearerAuth")
public class ApartmentDetailsController {

    private final ApartmentDetailsService apartmentDetailsService;

    @GetMapping
    @Operation(summary = "Get apartment details", description = "Get all details for an apartment")
    public ResponseEntity<ApartmentDetailsDto> getApartmentDetails(@PathVariable Long apartmentId) {
        return ResponseEntity.ok(apartmentDetailsService.getApartmentDetails(apartmentId));
    }

    @PutMapping
    @Operation(summary = "Update apartment details", description = "Update apartment details sections")
    public ResponseEntity<ApartmentDetailsDto> updateApartmentDetails(
            @PathVariable Long apartmentId,
            @RequestBody UpdateApartmentDetailsRequest request) {
        return ResponseEntity.ok(apartmentDetailsService.updateApartmentDetails(apartmentId, request));
    }

    @PostMapping("/photos")
    @Operation(summary = "Upload apartment photo", description = "Upload a photo for the apartment")
    public ResponseEntity<ApartmentPhotoDto> uploadPhoto(
            @PathVariable Long apartmentId,
            @RequestParam("file") MultipartFile file) {
        return ResponseEntity.ok(apartmentDetailsService.uploadPhoto(apartmentId, file));
    }

    @DeleteMapping("/photos/{photoId}")
    @Operation(summary = "Delete apartment photo", description = "Delete an apartment photo")
    public ResponseEntity<Void> deletePhoto(@PathVariable Long photoId) {
        apartmentDetailsService.deletePhoto(photoId);
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/photos/reorder")
    @Operation(summary = "Reorder apartment photos", description = "Reorder the display order of apartment photos")
    public ResponseEntity<Void> reorderPhotos(
            @PathVariable Long apartmentId,
            @RequestBody List<Long> photoIds) {
        apartmentDetailsService.reorderPhotos(apartmentId, photoIds);
        return ResponseEntity.ok().build();
    }
}
