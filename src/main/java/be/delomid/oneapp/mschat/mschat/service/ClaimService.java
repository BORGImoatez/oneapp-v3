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
    public ClaimDto createClaim(String residentId, CreateClaimRequest request, List<MultipartFile> photos) {
        Resident reporter = residentRepository.findById(residentId)
                .orElseThrow(() -> new RuntimeException("Reporter not found"));

        Apartment apartment = apartmentRepository.findById(request.getApartmentId())
                .orElseThrow(() -> new RuntimeException("Apartment not found"));

        Building building = apartment.getBuilding();

        // Verify that the reporter is a resident of this apartment
        boolean isResident = residentBuildingRepository
                .findByResidentIdAndBuildingId(residentId, building.getBuildingId())
                .stream()
                .anyMatch(rb -> rb.getApartment().getIdApartment().equals(apartment.getIdApartment()));

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
            for (String affectedApartmentId : request.getAffectedApartmentIds()) {
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
                    String photoUrl = fileService.uploadFile(photos.get(i), "claims/" + claim.getId(),claim.getReporter().getIdUsers()).toString();
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
                .findByBuildingIdAndRole(claim.getBuilding().getBuildingId(), UserRole.BUILDING_ADMIN);

        for (ResidentBuilding admin : admins) {
            NotificationDto notification = new NotificationDto();
            notification.setResidentId(admin.getResident().getIdUsers());
            notification.setTitle("Nouveau sinistre déclaré");
            notification.setBody(String.format("Un sinistre a été déclaré pour l'appartement %s",
                    claim.getApartment().getApartmentNumber()));
            notification.setType("CLAIM_NEW");
            notification.setRelatedId(claim.getId());
            notificationService.sendNotification(notification);
        }

        // Send notifications to residents of affected apartments
        List<ClaimAffectedApartment> affectedApartments = claimAffectedApartmentRepository.findByClaimId(claim.getId());
        for (ClaimAffectedApartment affectedApt : affectedApartments) {
            List<ResidentBuilding> residents = residentBuildingRepository
                    .findByBuildingIdAndApartmentId(claim.getBuilding().getBuildingId(), affectedApt.getApartment().getIdApartment());

            for (ResidentBuilding resident : residents) {
                if (!resident.getResident().getIdUsers().equals(claim.getReporter().getIdUsers())) {
                    NotificationDto notification = new NotificationDto();
                    notification.setResidentId(resident.getResident().getIdUsers());
                    notification.setTitle("Votre appartement est concerné par un sinistre");
                    notification.setBody(String.format("Un sinistre déclaré par l'appartement %s concerne votre logement",
                            claim.getApartment().getApartmentNumber()));
                    notification.setType("CLAIM_AFFECTED");
                    notification.setRelatedId(claim.getId());
                    notificationService.sendNotification(notification);
                }
            }
        }
    }

    public List<ClaimDto> getClaimsByBuilding(String buildingId, String residentId, boolean isAdmin) {
        List<Claim> claims;

        if (isAdmin) {
            claims = claimRepository.findByBuilding_BuildingIdOrderByCreatedAtDesc(buildingId);
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
        NotificationDto notification = new NotificationDto();
        notification.setResidentId(claim.getReporter().getIdUsers());
        notification.setTitle("Mise à jour du statut de votre sinistre");
        notification.setBody(String.format("Le statut de votre sinistre a été mis à jour: %s", status));
        notification.setType("CLAIM_STATUS_UPDATE");
        notification.setRelatedId(claim.getId());
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
        dto.setApartmentId(claim.getApartment().getIdApartment());
        dto.setApartmentNumber(claim.getApartment().getApartmentNumber());
        dto.setBuildingId(claim.getBuilding().getBuildingId());
        dto.setBuildingName(claim.getBuilding().getBuildingLabel());
        dto.setReporterId(claim.getReporter().getIdUsers());
        dto.setReporterName(claim.getReporter().getFname() + " " + claim.getReporter().getLname());
        dto.setReporterAvatar(PictureUrlUtil.normalizePictureUrl(claim.getReporter().getPicture()));
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
                .map(aa -> aa.getApartment().getIdApartment())
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
        dto.setPhotoUrl(PictureUrlUtil.normalizePictureUrl(photo.getPhotoUrl()));
        dto.setPhotoOrder(photo.getPhotoOrder());
        dto.setCreatedAt(photo.getCreatedAt());
        return dto;
    }
}
