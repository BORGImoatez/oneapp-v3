package be.delomid.oneapp.mschat.mschat.controller;

import be.delomid.oneapp.mschat.mschat.dto.ResidentDto;
import be.delomid.oneapp.mschat.mschat.service.AdminService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/admin")
@RequiredArgsConstructor
public class AdminController {
    
    private final AdminService adminService;
    
    @GetMapping("/pending-registrations")
    public ResponseEntity<Page<ResidentDto>> getPendingRegistrations(
            Authentication authentication,
            Pageable pageable) {
        
        String adminId = getUserId(authentication);
        Page<ResidentDto> residents = adminService.getPendingRegistrations(adminId, pageable);
        return ResponseEntity.ok(residents);
    }
    
    @PostMapping("/approve-registration/{residentId}")
    public ResponseEntity<ResidentDto> approveRegistration(
            @PathVariable String residentId,
            @RequestParam(required = false) String apartmentId,
            Authentication authentication) {
        
        String adminId = getUserId(authentication);
        ResidentDto resident = adminService.approveRegistration(adminId, residentId, apartmentId);
        return ResponseEntity.ok(resident);
    }
    
    @PostMapping("/reject-registration/{residentId}")
    public ResponseEntity<Void> rejectRegistration(
            @PathVariable String residentId,
            @RequestParam(required = false) String reason,
            Authentication authentication) {
        
        String adminId = getUserId(authentication);
        adminService.rejectRegistration(adminId, residentId, reason);
        return ResponseEntity.ok().build();
    }
    
    @PostMapping("/block-account/{residentId}")
    public ResponseEntity<ResidentDto> blockAccount(
            @PathVariable String residentId,
            @RequestParam(required = false) String reason,
            Authentication authentication) {
        
        String adminId = getUserId(authentication);
        ResidentDto resident = adminService.blockAccount(adminId, residentId, reason);
        return ResponseEntity.ok(resident);
    }
    
    @PostMapping("/unblock-account/{residentId}")
    public ResponseEntity<ResidentDto> unblockAccount(
            @PathVariable String residentId,
            Authentication authentication) {
        
        String adminId = getUserId(authentication);
        ResidentDto resident = adminService.unblockAccount(adminId, residentId);
        return ResponseEntity.ok(resident);
    }
    
    @GetMapping("/building/{buildingId}/residents")
    public ResponseEntity<List<ResidentDto>> getBuildingResidents(
            @PathVariable String buildingId,
            Authentication authentication) {
        
        String adminId = getUserId(authentication);
        List<ResidentDto> residents = adminService.getBuildingResidents(adminId, buildingId);
        return ResponseEntity.ok(residents);
    }
    
    private String getUserId(Authentication authentication) {
        return authentication.getName(); // Sera l'ID utilisateur après configuration JWT
    }
}