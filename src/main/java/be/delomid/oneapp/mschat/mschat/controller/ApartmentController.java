package be.delomid.oneapp.mschat.mschat.controller;

import be.delomid.oneapp.mschat.mschat.dto.ApartmentDto;
import be.delomid.oneapp.mschat.mschat.dto.CreateApartmentRequest;
import be.delomid.oneapp.mschat.mschat.interceptor.JwtWebSocketInterceptor;
import be.delomid.oneapp.mschat.mschat.service.ApartmentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/apartments")
@RequiredArgsConstructor
public class ApartmentController {

    private final ApartmentService apartmentService;

    @PostMapping
    public ResponseEntity<ApartmentDto> createApartment(
            @Valid @RequestBody CreateApartmentRequest request,
            Authentication authentication) {
        
        ApartmentDto apartment = apartmentService.createApartment(request);
        return ResponseEntity.ok(apartment);
    }

    @GetMapping("/building/{buildingId}")
    public ResponseEntity<Page<ApartmentDto>> getApartmentsByBuilding(
            @PathVariable String buildingId,
            Pageable pageable) {
        
        Page<ApartmentDto> apartments = apartmentService.getApartmentsByBuilding(buildingId, pageable);
        return ResponseEntity.ok(apartments);
    }

    @GetMapping("/{apartmentId}")
    public ResponseEntity<ApartmentDto> getApartmentById(@PathVariable String apartmentId) {
        ApartmentDto apartment = apartmentService.getApartmentById(apartmentId);
        return ResponseEntity.ok(apartment);
    }

    @GetMapping("/building/{buildingId}/available")
    public ResponseEntity<List<ApartmentDto>> getAvailableApartments(@PathVariable String buildingId) {
        List<ApartmentDto> apartments = apartmentService.getAvailableApartments(buildingId);
        return ResponseEntity.ok(apartments);
    }

    @GetMapping("/building/{buildingId}/occupied")
    public ResponseEntity<List<ApartmentDto>> getOccupiedApartments(@PathVariable String buildingId) {
        List<ApartmentDto> apartments = apartmentService.getOccupiedApartments(buildingId);
        return ResponseEntity.ok(apartments);
    }

    @GetMapping("/current")
    public ResponseEntity<ApartmentDto> getCurrentUserApartment(
            @RequestParam String buildingId,
            Authentication authentication) {
        String userId = getUserId(authentication);
        ApartmentDto apartment = apartmentService.getCurrentUserApartment(buildingId, userId);
        return ResponseEntity.ok(apartment);
    }

    @PostMapping("/{apartmentId}/assign/{userId}")
    public ResponseEntity<ApartmentDto> assignResidentToApartment(
            @PathVariable String apartmentId,
            @PathVariable String userId,
            Authentication authentication) {
        
        ApartmentDto apartment = apartmentService.assignResidentToApartment(apartmentId, userId);
        return ResponseEntity.ok(apartment);
    }

    @PostMapping("/{apartmentId}/remove-resident")
    public ResponseEntity<ApartmentDto> removeResidentFromApartment(
            @PathVariable String apartmentId,
            Authentication authentication) {
        
        ApartmentDto apartment = apartmentService.removeResidentFromApartment(apartmentId);
        return ResponseEntity.ok(apartment);
    }

    @PutMapping("/{apartmentId}")
    public ResponseEntity<ApartmentDto> updateApartment(
            @PathVariable String apartmentId,
            @Valid @RequestBody CreateApartmentRequest request,
            Authentication authentication) {
        
        ApartmentDto apartment = apartmentService.updateApartment(apartmentId, request);
        return ResponseEntity.ok(apartment);
    }

    @DeleteMapping("/{apartmentId}")
    public ResponseEntity<Void> deleteApartment(
            @PathVariable String apartmentId,
            Authentication authentication) {
        
        apartmentService.deleteApartment(apartmentId);
        return ResponseEntity.ok().build();
    }

    private String getUserId(Authentication authentication) {
        if (authentication.getPrincipal() instanceof JwtWebSocketInterceptor.JwtPrincipal principal) {
            return principal.getName();
        } else if (authentication.getPrincipal() instanceof UserDetails userDetails) {
            return userDetails.getUsername();
        }
        return authentication.getName();
    }
}