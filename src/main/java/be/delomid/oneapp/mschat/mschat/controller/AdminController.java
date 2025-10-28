package be.delomid.oneapp.mschat.mschat.controller;

import be.delomid.oneapp.mschat.mschat.dto.AddResidentToApartmentRequest;
import be.delomid.oneapp.mschat.mschat.dto.ResidentDto;
import be.delomid.oneapp.mschat.mschat.interceptor.JwtWebSocketInterceptor;
import be.delomid.oneapp.mschat.mschat.service.AdminService;
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

    @PostMapping("/add-resident-to-apartment")
    public ResponseEntity<ResidentDto> addResidentToApartment(
            @Valid @RequestBody AddResidentToApartmentRequest request,
            Authentication authentication) {

        String adminId = getUserId(authentication);
        ResidentDto resident = adminService.addResidentToApartment(adminId, request);
        return ResponseEntity.ok(resident);
    }

    private String getUserId(Authentication authentication) {
        if (authentication.getPrincipal() instanceof JwtWebSocketInterceptor.JwtPrincipal) {
            JwtWebSocketInterceptor.JwtPrincipal principal = (JwtWebSocketInterceptor.JwtPrincipal) authentication.getPrincipal();
            return principal.getName();
        } else if (authentication.getPrincipal() instanceof UserDetails) {
            UserDetails userDetails = (UserDetails) authentication.getPrincipal();
            return userDetails.getUsername();
        }
        return authentication.getName();
    }
}