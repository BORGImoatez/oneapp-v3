package be.delomid.oneapp.mschat.mschat.controller;

import be.delomid.oneapp.mschat.mschat.dto.AuthResponse;
import be.delomid.oneapp.mschat.mschat.dto.BuildingSelectionDto;
import be.delomid.oneapp.mschat.mschat.dto.SelectBuildingRequest;
import be.delomid.oneapp.mschat.mschat.service.BuildingSelectionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class BuildingSelectionController {

    private final BuildingSelectionService buildingSelectionService;

    @GetMapping("/user-buildings")
    public ResponseEntity<List<BuildingSelectionDto>> getUserBuildings(Authentication authentication) {
        String userId = getUserId(authentication);
        List<BuildingSelectionDto> buildings = buildingSelectionService.getUserBuildings(userId);
        return ResponseEntity.ok(buildings);
    }

    @PostMapping("/select-building")
    public ResponseEntity<AuthResponse> selectBuilding(
            @Valid @RequestBody SelectBuildingRequest request,
            Authentication authentication) {

        String userId = getUserId(authentication);
        AuthResponse response = buildingSelectionService.selectBuilding(userId, request.getBuildingId());
        return ResponseEntity.ok(response);
    }

    private String getUserId(Authentication authentication) {
        if (authentication == null) {
            throw new IllegalArgumentException("Authentication required");
        }
        return authentication.getName();
    }
}