package be.delomid.oneapp.mschat.mschat.service;

import be.delomid.oneapp.mschat.mschat.dto.ResidentDto;
import be.delomid.oneapp.mschat.mschat.model.*;
import be.delomid.oneapp.mschat.mschat.repository.ApartmentRepository;
import be.delomid.oneapp.mschat.mschat.repository.ResidentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class AdminService {
    
    private final ResidentRepository residentRepository;
    private final ApartmentRepository apartmentRepository;
    private final EmailService emailService;
    
    @PreAuthorize("hasRole('BUILDING_ADMIN') or hasRole('GROUP_ADMIN') or hasRole('SUPER_ADMIN')")
    public Page<ResidentDto> getPendingRegistrations(String adminId, Pageable pageable) {
        Resident admin = residentRepository.findById(adminId)
                .orElseThrow(() -> new IllegalArgumentException("Admin not found"));
        
        // Pour les admins d'immeuble, ne montrer que les demandes pour leur immeuble
        if (admin.getRole() == UserRole.BUILDING_ADMIN) {
            // Logique pour filtrer par immeuble géré
            Page<Resident> residents = residentRepository.findByAccountStatus(AccountStatus.PENDING, pageable);
            return residents.map(this::convertToDto);
        }
        
        // Pour les autres admins, montrer toutes les demandes
        Page<Resident> residents = residentRepository.findByAccountStatus(AccountStatus.PENDING, pageable);
        return residents.map(this::convertToDto);
    }
    
    @PreAuthorize("hasRole('BUILDING_ADMIN') or hasRole('GROUP_ADMIN') or hasRole('SUPER_ADMIN')")
    @Transactional
    public ResidentDto approveRegistration(String adminId, String residentId, String apartmentId) {
        validateAdminAccess(adminId, residentId);
        
        Resident resident = residentRepository.findById(residentId)
                .orElseThrow(() -> new IllegalArgumentException("Resident not found"));
        
        if (resident.getAccountStatus() != AccountStatus.PENDING) {
            throw new IllegalStateException("Account is not pending approval");
        }
        
        // Assigner l'appartement si fourni
        if (apartmentId != null) {
            Apartment apartment = apartmentRepository.findById(apartmentId)
                    .orElseThrow(() -> new IllegalArgumentException("Apartment not found"));
            
            if (apartment.getResident() != null) {
                throw new IllegalStateException("Apartment is already occupied");
            }
            
            apartment.setResident(resident);
            apartmentRepository.save(apartment);
        }
        
        resident.setAccountStatus(AccountStatus.ACTIVE);
        resident = residentRepository.save(resident);
        
        // Envoyer email de confirmation
        emailService.sendAccountStatusEmail(
                resident.getEmail(), 
                "ACTIVE", 
                "Votre compte a été approuvé et activé."
        );
        
        log.debug("Registration approved for resident: {} by admin: {}", residentId, adminId);
        return convertToDto(resident);
    }
    
    @PreAuthorize("hasRole('BUILDING_ADMIN') or hasRole('GROUP_ADMIN') or hasRole('SUPER_ADMIN')")
    @Transactional
    public void rejectRegistration(String adminId, String residentId, String reason) {
        validateAdminAccess(adminId, residentId);
        
        Resident resident = residentRepository.findById(residentId)
                .orElseThrow(() -> new IllegalArgumentException("Resident not found"));
        
        resident.setAccountStatus(AccountStatus.REJECTED);
        residentRepository.save(resident);
        
        // Envoyer email de rejet
        emailService.sendAccountStatusEmail(
                resident.getEmail(), 
                "REJECTED", 
                reason != null ? reason : "Votre demande d'inscription a été rejetée."
        );
        
        log.debug("Registration rejected for resident: {} by admin: {}", residentId, adminId);
    }
    
    @PreAuthorize("hasRole('BUILDING_ADMIN') or hasRole('GROUP_ADMIN') or hasRole('SUPER_ADMIN')")
    @Transactional
    public ResidentDto blockAccount(String adminId, String residentId, String reason) {
        validateAdminAccess(adminId, residentId);
        
        Resident resident = residentRepository.findById(residentId)
                .orElseThrow(() -> new IllegalArgumentException("Resident not found"));
        
        resident.setAccountStatus(AccountStatus.BLOCKED);
        resident.setIsAccountNonLocked(false);
        resident = residentRepository.save(resident);
        
        // Envoyer email de blocage
        emailService.sendAccountStatusEmail(
                resident.getEmail(), 
                "BLOCKED", 
                reason != null ? reason : "Votre compte a été bloqué."
        );
        
        log.debug("Account blocked for resident: {} by admin: {}", residentId, adminId);
        return convertToDto(resident);
    }
    
    @PreAuthorize("hasRole('BUILDING_ADMIN') or hasRole('GROUP_ADMIN') or hasRole('SUPER_ADMIN')")
    @Transactional
    public ResidentDto unblockAccount(String adminId, String residentId) {
        validateAdminAccess(adminId, residentId);
        
        Resident resident = residentRepository.findById(residentId)
                .orElseThrow(() -> new IllegalArgumentException("Resident not found"));
        
        resident.setAccountStatus(AccountStatus.ACTIVE);
        resident.setIsAccountNonLocked(true);
        resident = residentRepository.save(resident);
        
        // Envoyer email de déblocage
        emailService.sendAccountStatusEmail(
                resident.getEmail(), 
                "ACTIVE", 
                "Votre compte a été débloqué et réactivé."
        );
        
        log.debug("Account unblocked for resident: {} by admin: {}", residentId, adminId);
        return convertToDto(resident);
    }
    
    @PreAuthorize("hasRole('BUILDING_ADMIN') or hasRole('GROUP_ADMIN') or hasRole('SUPER_ADMIN')")
    public List<ResidentDto> getBuildingResidents(String adminId, String buildingId) {
        validateBuildingAdminAccess(adminId, buildingId);
        
        List<Resident> residents = residentRepository.findByBuildingId(buildingId);
        return residents.stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }
    
    private void validateAdminAccess(String adminId, String residentId) {
        Resident admin = residentRepository.findById(adminId)
                .orElseThrow(() -> new IllegalArgumentException("Admin not found"));
        
        if (admin.getRole() == UserRole.RESIDENT) {
            throw new IllegalArgumentException("Insufficient privileges");
        }
        
        // Logique de validation selon le type d'admin
        if (admin.getRole() == UserRole.BUILDING_ADMIN) {
            // Vérifier que le résident est dans l'immeuble géré par cet admin
            // Maintenant on doit vérifier via ResidentBuilding
            Resident resident = residentRepository.findById(residentId)
                    .orElseThrow(() -> new IllegalArgumentException("Resident not found"));

            // TODO: Implémenter la vérification via ResidentBuilding
            // Cette logique doit être revue pour utiliser residentBuildingRepository
        }
    }
    
    private void validateBuildingAdminAccess(String adminId, String buildingId) {
        Resident admin = residentRepository.findById(adminId)
                .orElseThrow(() -> new IllegalArgumentException("Admin not found"));
        
        if (admin.getRole() == UserRole.BUILDING_ADMIN && 
            !buildingId.equals(admin.getManagedBuildingId())) {
            throw new IllegalArgumentException("Admin can only access their managed building");
        }
    }
    
    private ResidentDto convertToDto(Resident resident) {
        // Les informations d'appartement/building sont maintenant gérées via ResidentBuilding
        String apartmentId = null;
        String buildingId = null;
        
        return ResidentDto.builder()
                .idUsers(resident.getIdUsers())
                .fname(resident.getFname())
                .lname(resident.getLname())
                .email(resident.getEmail())
                .phoneNumber(resident.getPhoneNumber())
                .picture(resident.getPicture())
                .role(resident.getRole())
                .accountStatus(resident.getAccountStatus())
                .managedBuildingId(resident.getManagedBuildingId())
                .managedBuildingGroupId(resident.getManagedBuildingGroupId())
                .apartmentId(apartmentId)
                .buildingId(buildingId)
                .createdAt(resident.getCreatedAt())
                .updatedAt(resident.getUpdatedAt())
                .build();
    }
}