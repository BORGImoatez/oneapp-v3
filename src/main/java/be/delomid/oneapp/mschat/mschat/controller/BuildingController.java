package be.delomid.oneapp.mschat.mschat.controller;

import be.delomid.oneapp.mschat.mschat.dto.BuildingDto;
import be.delomid.oneapp.mschat.mschat.dto.CreateBuildingRequest;
import be.delomid.oneapp.mschat.mschat.service.BuildingService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/buildings")
@RequiredArgsConstructor
public class BuildingController {

    private final BuildingService buildingService;

    @PostMapping
    public ResponseEntity<BuildingDto> createBuilding(
            @Valid @RequestBody CreateBuildingRequest request,
            Authentication authentication) {
        
        BuildingDto building = buildingService.createBuilding(request);
        return ResponseEntity.ok(building);
    }

    @GetMapping
    public ResponseEntity<Page<BuildingDto>> getAllBuildings(Pageable pageable) {
        Page<BuildingDto> buildings = buildingService.getAllBuildings(pageable);
        return ResponseEntity.ok(buildings);
    }

    @GetMapping("/{buildingId}")
    public ResponseEntity<BuildingDto> getBuildingById(@PathVariable String buildingId) {
        BuildingDto building = buildingService.getBuildingById(buildingId);
        return ResponseEntity.ok(building);
    }

    @GetMapping("/city/{ville}")
    public ResponseEntity<List<BuildingDto>> getBuildingsByCity(@PathVariable String ville) {
        List<BuildingDto> buildings = buildingService.getBuildingsByCity(ville);
        return ResponseEntity.ok(buildings);
    }

    @GetMapping("/postal-code/{codePostal}")
    public ResponseEntity<List<BuildingDto>> getBuildingsByPostalCode(@PathVariable String codePostal) {
        List<BuildingDto> buildings = buildingService.getBuildingsByPostalCode(codePostal);
        return ResponseEntity.ok(buildings);
    }

    @PutMapping("/{buildingId}")
    public ResponseEntity<BuildingDto> updateBuilding(
            @PathVariable String buildingId,
            @Valid @RequestBody CreateBuildingRequest request,
            Authentication authentication) {
        
        BuildingDto building = buildingService.updateBuilding(buildingId, request);
        return ResponseEntity.ok(building);
    }

    @DeleteMapping("/{buildingId}")
    public ResponseEntity<Void> deleteBuilding(
            @PathVariable String buildingId,
            Authentication authentication) {
        
        buildingService.deleteBuilding(buildingId);
        return ResponseEntity.ok().build();
    }

    private String getUserId(Authentication authentication) {
        UserDetails userDetails = (UserDetails) authentication.getPrincipal();
        return userDetails.getUsername(); // Email, mais on devrait récupérer l'ID
    }
}