package be.delomid.oneapp.mschat.mschat.controller;

 import be.delomid.oneapp.mschat.mschat.dto.CreateResidentRequest;
 import be.delomid.oneapp.mschat.mschat.dto.ResidentDto;
 import be.delomid.oneapp.mschat.mschat.service.ResidentService;
 import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/residents")
@RequiredArgsConstructor
public class ResidentController {

    private final ResidentService residentService;

    @PostMapping
    public ResponseEntity<ResidentDto> createResident(
            @Valid @RequestBody CreateResidentRequest request,
            Authentication authentication) {
        
        ResidentDto resident = residentService.createResident(request);
        return ResponseEntity.ok(resident);
    }

    @GetMapping
    public ResponseEntity<Page<ResidentDto>> getAllResidents(Pageable pageable) {
        Page<ResidentDto> residents = residentService.getAllResidents(pageable);
        return ResponseEntity.ok(residents);
    }

    @GetMapping("/{userId}")
    public ResponseEntity<ResidentDto> getResidentById(@PathVariable String userId) {
        ResidentDto resident = residentService.getResidentById(userId);
        return ResponseEntity.ok(resident);
    }

    @GetMapping("/email/{email}")
    public ResponseEntity<ResidentDto> getResidentByEmail(@PathVariable String email) {
        Optional<ResidentDto> resident = residentService.getResidentByEmail(email);
        return resident.map(ResponseEntity::ok)
                      .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/building/{buildingId}")
    public ResponseEntity<List<ResidentDto>> getResidentsByBuilding(@PathVariable String buildingId) {
        List<ResidentDto> residents = residentService.getResidentsByBuilding(buildingId);
        return ResponseEntity.ok(residents);
    }

    @GetMapping("/search")
    public ResponseEntity<Page<ResidentDto>> searchResidentsByName(
            @RequestParam String name,
            Pageable pageable) {
        
        Page<ResidentDto> residents = residentService.searchResidentsByName(name, pageable);
        return ResponseEntity.ok(residents);
    }

    @GetMapping("/{userId}/apartment")
    public ResponseEntity<ResidentDto> getResidentApartmentInfo(@PathVariable String userId) {
        Optional<ResidentDto> resident = residentService.getResidentApartmentInfo(userId);
        return resident.map(ResponseEntity::ok)
                      .orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/{userId}")
    public ResponseEntity<ResidentDto> updateResident(
            @PathVariable String userId,
            @Valid @RequestBody CreateResidentRequest request,
            Authentication authentication) {
        
        ResidentDto resident = residentService.updateResident(userId, request);
        return ResponseEntity.ok(resident);
    }

    @DeleteMapping("/{userId}")
    public ResponseEntity<Void> deleteResident(
            @PathVariable String userId,
            Authentication authentication) {
        
        residentService.deleteResident(userId);
        return ResponseEntity.ok().build();
    }

    private String getUserId(Authentication authentication) {
        UserDetails userDetails = (UserDetails) authentication.getPrincipal();
        return userDetails.getUsername(); // Email, mais on devrait récupérer l'ID
    }
}