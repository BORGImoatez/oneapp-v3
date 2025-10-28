package be.delomid.oneapp.mschat.mschat.controller;

import be.delomid.oneapp.mschat.mschat.dto.ClaimDto;
import be.delomid.oneapp.mschat.mschat.dto.CreateClaimRequest;
import be.delomid.oneapp.mschat.mschat.dto.UpdateClaimStatusRequest;
import be.delomid.oneapp.mschat.mschat.model.MemberRole;
import be.delomid.oneapp.mschat.mschat.model.ResidentBuilding;
import be.delomid.oneapp.mschat.mschat.repository.ResidentBuildingRepository;
import be.delomid.oneapp.mschat.mschat.service.ClaimService;
import be.delomid.oneapp.mschat.mschat.util.SecurityContextUtil;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/api/claims")
public class ClaimController {

    @Autowired
    private ClaimService claimService;

    @Autowired
    private ResidentBuildingRepository residentBuildingRepository;

    @PostMapping
    public ResponseEntity<ClaimDto> createClaim(
            @RequestParam("claimData") String claimDataJson,
            @RequestParam(value = "photos", required = false) List<MultipartFile> photos
    ) {
        try {
            Long residentId = SecurityContextUtil.getCurrentUserId();
            ObjectMapper mapper = new ObjectMapper();
            CreateClaimRequest request = mapper.readValue(claimDataJson, CreateClaimRequest.class);

            ClaimDto claim = claimService.createClaim(residentId, request, photos);
            return ResponseEntity.ok(claim);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GetMapping("/building/{buildingId}")
    public ResponseEntity<List<ClaimDto>> getClaimsByBuilding(@PathVariable Long buildingId) {
        try {
            Long residentId = SecurityContextUtil.getCurrentUserId();

            // Check if user is admin
            List<ResidentBuilding> residentBuildings = residentBuildingRepository
                    .findByResidentIdAndBuildingId(residentId, buildingId);

            boolean isAdmin = residentBuildings.stream()
                    .anyMatch(rb -> rb.getRole() == MemberRole.ADMIN);

            List<ClaimDto> claims = claimService.getClaimsByBuilding(buildingId, residentId, isAdmin);
            return ResponseEntity.ok(claims);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GetMapping("/{claimId}")
    public ResponseEntity<ClaimDto> getClaimById(@PathVariable Long claimId) {
        try {
            ClaimDto claim = claimService.getClaimById(claimId);
            return ResponseEntity.ok(claim);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
    }

    @PatchMapping("/{claimId}/status")
    public ResponseEntity<ClaimDto> updateClaimStatus(
            @PathVariable Long claimId,
            @RequestBody UpdateClaimStatusRequest request
    ) {
        try {
            ClaimDto claim = claimService.updateClaimStatus(claimId, request.getStatus());
            return ResponseEntity.ok(claim);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @DeleteMapping("/{claimId}")
    public ResponseEntity<Void> deleteClaim(@PathVariable Long claimId) {
        try {
            claimService.deleteClaim(claimId);
            return ResponseEntity.noContent().build();
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
}
