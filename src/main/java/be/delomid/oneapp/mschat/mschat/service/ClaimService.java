package be.delomid.oneapp.mschat.mschat.service;

import be.delomid.oneapp.mschat.mschat.dto.*;
import be.delomid.oneapp.mschat.mschat.model.*;
import be.delomid.oneapp.mschat.mschat.repository.*;
import be.delomid.oneapp.mschat.mschat.util.PictureUrlUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class ClaimService {

    @Autowired
    private ClaimRepository claimRepository;

    @Autowired
    private ClaimAffectedApartmentRepository claimAffectedApartmentRepository;

    @Autowired
    private ClaimPhotoRepository claimPhotoRepository;

    @Autowired
    private ApartmentRepository apartmentRepository;

    @Autowired
    private BuildingRepository buildingRepository;

    @Autowired
    private ResidentRepository residentRepository;

    @Autowired
    private ResidentBuildingRepository residentBuildingRepository;

    @Autowired
    private FileService fileService;

    @Autowired
    private NotificationService notificationService;

    @Transactional
    public ClaimDto createClaim(Long residentId, CreateClaimRequest request, List<MultipartFile> photos) {
        Resident reporter = residentRepository.findById(residentId)
                .orElseThrow(() -> new RuntimeException("Reporter not found"));

        Apartment apartment = apartmentRepository.findById(request.getApartmentId())
                .orElseThrow(() -> new RuntimeException("Apartment not found"));

        Building building = apartment.getBuilding();

        // Verify that the reporter is a resident of this apartment
        boolean isResident = residentBuildingRepository
                .findByResidentIdAndBuildingId(residentId, building.getId())
                .stream()
                .anyMatch(rb -> rb.getApartment().getId().equals(apartment.getId()));

        if (!isResident) {
            throw new RuntimeException("You can only create claims for your own apartment");
        }

        Claim claim = new Claim();
        claim.setApartment(apartment);
        claim.setBuilding(building);
        claim.setReporter(reporter);
        claim.setClaimTypes(request.getClaimTypes().toArray(new String[0]));
        claim.setCause(request.getCause());
        claim.setDescription(request.getDescription());
        claim.setInsuranceCompany(request.getInsuranceCompany());
        claim.setInsurancePolicyNumber(request.getInsurancePolicyNumber());
        claim.setStatus(ClaimStatus.PENDING);

        claim = claimRepository.save(claim);

        // Add affected apartments
        if (request.getAffectedApartmentIds() != null && !request.getAffectedApartmentIds().isEmpty()) {
            for (Long affectedApartmentId : request.getAffectedApartmentIds()) {
                Apartment affectedApartment = apartmentRepository.findById(affectedApartmentId)
                        .orElseThrow(() -> new RuntimeException("Affected apartment not found"));

                ClaimAffectedApartment affectedApt = new ClaimAffectedApartment();
                affectedApt.setClaim(claim);
                affectedApt.setApartment(affectedApartment);
                claimAffectedApartmentRepository.save(affectedApt);
            }
        }

        // Upload photos
        if (photos != null && !photos.isEmpty()) {
            for (int i = 0; i < photos.size(); i++) {
                try {
                    String photoUrl = fileService.uploadFile(photos.get(i), "claims/" + claim.getId());
                    ClaimPhoto photo = new ClaimPhoto();
                    photo.setClaim(claim);
                    photo.setPhotoUrl(photoUrl);
                    photo.setPhotoOrder(i);
                    claimPhotoRepository.save(photo);
                } catch (Exception e) {
                    throw new RuntimeException("Failed to upload photo: " + e.getMessage());
                }
            }
        }

        // Send notifications to building admins
        sendClaimNotifications(claim);

        return convertToDto(claim);
    }

    private void sendClaimNotifications(Claim claim) {
        // Get all admins of the building
        List<ResidentBuilding> admins = residentBuildingRepository
                .findByBuildingIdAndRole(claim.getBuilding().getId(), UserRole.ADMIN);

        for (ResidentBuilding admin : admins) {
            NotificationDto notification = NotificationDto.builder()
                    .residentId(admin.getResident().getId())
                    .buildingId(claim.getBuilding().getBuildingId())
                    .title("Nouveau sinistre déclaré")
                    .body(String.format("Un sinistre a été déclaré pour l'appartement %s",
                            claim.getApartment().getApartmentNumber()))
                    .type("CLAIM_NEW")
                    .relatedId(claim.getId())
                    .build();
            notificationService.sendNotification(notification);
        }

        // Send notifications to residents of affected apartments
        List<ClaimAffectedApartment> affectedApartments = claimAffectedApartmentRepository.findByClaimId(claim.getId());
        for (ClaimAffectedApartment affectedApt : affectedApartments) {
            List<ResidentBuilding> residents = residentBuildingRepository
                    .findByBuildingIdAndApartmentId(claim.getBuilding().getId(), affectedApt.getApartment().getId());

            for (ResidentBuilding resident : residents) {
                if (!resident.getResident().getId().equals(claim.getReporter().getId())) {
                    NotificationDto notification = NotificationDto.builder()
                            .residentId(resident.getResident().getId())
                            .buildingId(claim.getBuilding().getBuildingId())
                            .title("Votre appartement est concerné par un sinistre")
                            .body(String.format("Un sinistre déclaré par l'appartement %s concerne votre logement",
                                    claim.getApartment().getApartmentNumber()))
                            .type("CLAIM_AFFECTED")
                            .relatedId(claim.getId())
                            .build();
                    notificationService.sendNotification(notification);
                }
            }
        }
    }

    public List<ClaimDto> getClaimsByBuilding(Long buildingId, Long residentId, boolean isAdmin) {
        List<Claim> claims;

        if (isAdmin) {
            claims = claimRepository.findByBuildingIdOrderByCreatedAtDesc(buildingId);
        } else {
            claims = claimRepository.findClaimsByBuildingAndResident(buildingId, residentId);
        }

        return claims.stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public ClaimDto getClaimById(Long claimId) {
        Claim claim = claimRepository.findById(claimId)
                .orElseThrow(() -> new RuntimeException("Claim not found"));
        return convertToDto(claim);
    }

    @Transactional
    public ClaimDto updateClaimStatus(Long claimId, String status) {
        Claim claim = claimRepository.findById(claimId)
                .orElseThrow(() -> new RuntimeException("Claim not found"));

        claim.setStatus(ClaimStatus.valueOf(status));
        claim = claimRepository.save(claim);

        // Send notification to reporter
        NotificationDto notification = NotificationDto.builder()
                .residentId(claim.getReporter().getId())
                .buildingId(claim.getBuilding().getBuildingId())
                .title("Mise à jour du statut de votre sinistre")
                .body(String.format("Le statut de votre sinistre a été mis à jour: %s", status))
                .type("CLAIM_STATUS_UPDATE")
                .relatedId(claim.getId())
                .build();
        notificationService.sendNotification(notification);

        return convertToDto(claim);
    }

    @Transactional
    public void deleteClaim(Long claimId) {
        Claim claim = claimRepository.findById(claimId)
                .orElseThrow(() -> new RuntimeException("Claim not found"));
        claimRepository.delete(claim);
    }

    private ClaimDto convertToDto(Claim claim) {
        ClaimDto dto = new ClaimDto();
        dto.setId(claim.getId());
        dto.setApartmentId(claim.getApartment().getId());
        dto.setApartmentNumber(claim.getApartment().getApartmentNumber());
        dto.setBuildingId(claim.getBuilding().getId());
        dto.setBuildingName(claim.getBuilding().getName());
        dto.setReporterId(claim.getReporter().getId());
        dto.setReporterName(claim.getReporter().getFirstName() + " " + claim.getReporter().getLastName());
        dto.setReporterAvatar(PictureUrlUtil.getFullPictureUrl(claim.getReporter().getPictureUrl()));
        dto.setClaimTypes(Arrays.asList(claim.getClaimTypes()));
        dto.setCause(claim.getCause());
        dto.setDescription(claim.getDescription());
        dto.setInsuranceCompany(claim.getInsuranceCompany());
        dto.setInsurancePolicyNumber(claim.getInsurancePolicyNumber());
        dto.setStatus(claim.getStatus().name());
        dto.setCreatedAt(claim.getCreatedAt());
        dto.setUpdatedAt(claim.getUpdatedAt());

        // Get affected apartments
        List<ClaimAffectedApartment> affectedApts = claimAffectedApartmentRepository.findByClaimId(claim.getId());
        dto.setAffectedApartmentIds(affectedApts.stream()
                .map(aa -> aa.getApartment().getId())
                .collect(Collectors.toList()));

        // Get photos
        List<ClaimPhoto> photos = claimPhotoRepository.findByClaimIdOrderByPhotoOrderAsc(claim.getId());
        dto.setPhotos(photos.stream()
                .map(this::convertPhotoToDto)
                .collect(Collectors.toList()));

        return dto;
    }

    private ClaimPhotoDto convertPhotoToDto(ClaimPhoto photo) {
        ClaimPhotoDto dto = new ClaimPhotoDto();
        dto.setId(photo.getId());
        dto.setPhotoUrl(PictureUrlUtil.getFullPictureUrl(photo.getPhotoUrl()));
        dto.setPhotoOrder(photo.getPhotoOrder());
        dto.setCreatedAt(photo.getCreatedAt());
        return dto;
    }
}
