package be.delomid.oneapp.mschat.mschat.service;

import be.delomid.oneapp.mschat.mschat.dto.*;
import be.delomid.oneapp.mschat.mschat.model.*;
import be.delomid.oneapp.mschat.mschat.repository.*;
import be.delomid.oneapp.mschat.mschat.util.PictureUrlUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ClaimService {

     private final ClaimRepository claimRepository;

     private final ClaimAffectedApartmentRepository claimAffectedApartmentRepository;

     private final ClaimPhotoRepository claimPhotoRepository;

     private final ApartmentRepository apartmentRepository;

     private final BuildingRepository buildingRepository;

     private final ResidentRepository residentRepository;

     private final ResidentBuildingRepository residentBuildingRepository;

     private final FileService fileService;

     private final NotificationService notificationService;

     private final ChannelRepository channelRepository;

     private final ChannelMemberRepository channelMemberRepository;

     private final FolderRepository folderRepository;

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

        // Create emergency channel
        Channel emergencyChannel = createEmergencyChannel(claim, reporter);
        claim.setEmergencyChannel(emergencyChannel);

        // Create emergency folder
        Folder emergencyFolder = createEmergencyFolder(claim, reporter, building);
        claim.setEmergencyFolder(emergencyFolder);

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
                    Map<String, Object> uploadResult = fileService.uploadFile(photos.get(i), "IMAGE", residentId);
                    String photoUrl = uploadResult.get("url").toString();

                    ClaimPhoto photo = new ClaimPhoto();
                    photo.setClaim(claim);
                    photo.setPhotoUrl(photoUrl);
                    photo.setPhotoOrder(i);
                    claimPhotoRepository.save(photo);
                } catch (Exception e) {
                    throw new RuntimeException("Failed to upload photo " + (i + 1) + ": " + e.getMessage(), e);
                }
            }
        }

        // Add channel members: admin, reporter, affected apartment residents
        addEmergencyChannelMembers(emergencyChannel, claim, request.getAffectedApartmentIds());

        // Send notifications to building admins
        sendClaimNotifications(claim);

        return convertToDto(claim);
    }

    private Channel createEmergencyChannel(Claim claim, Resident reporter) {
        String channelName = "Sinistre - Apt " + claim.getApartment().getApartmentNumber();
        String description = "Canal d'urgence pour le sinistre déclaré le " +
                             claim.getCreatedAt().toLocalDate().toString();

        Channel channel = Channel.builder()
                .name(channelName)
                .description(description)
                .type(ChannelType.GROUP)
                .buildingId(claim.getBuilding().getBuildingId())
                .createdBy(reporter.getIdUsers())
                .isPrivate(true)
                .isClosed(false)
                .build();

        return channelRepository.save(channel);
    }

    private Folder createEmergencyFolder(Claim claim, Resident reporter, Building building) {
        String folderName = "Sinistre_Apt" + claim.getApartment().getApartmentNumber() + "_" +
                            claim.getCreatedAt().toLocalDate().toString();
        String folderPath = "building_" + building.getBuildingId() + "/claims/" + folderName;

        Folder folder = Folder.builder()
                .name(folderName)
                .folderPath(folderPath)
                .apartment(claim.getApartment())
                .building(building)
                .createdBy(reporter.getIdUsers())
                .isShared(true)
                .shareType(ShareType.SPECIFIC_APARTMENTS)
                .claim(claim)
                .build();

        return folderRepository.save(folder);
    }

    private void addEmergencyChannelMembers(Channel channel, Claim claim, List<String> affectedApartmentIds) {
        // Add reporter as owner
        ChannelMember reporterMember = ChannelMember.builder()
                .channel(channel)
                .userId(claim.getReporter().getIdUsers())
                .role(MemberRole.MEMBER)
                .canWrite(true)
                .build();
        channelMemberRepository.save(reporterMember);

        // Add building admins
        List<ResidentBuilding> admins = residentBuildingRepository
                .findByBuildingIdAndRole(claim.getBuilding().getBuildingId(), UserRole.BUILDING_ADMIN);
        for (ResidentBuilding admin : admins) {
            ChannelMember adminMember = ChannelMember.builder()
                    .channel(channel)
                    .userId(admin.getResident().getIdUsers())
                    .role(MemberRole.ADMIN)
                    .canWrite(true)
                    .build();
            channelMemberRepository.save(adminMember);
        }

        // Add affected apartment residents
        if (affectedApartmentIds != null && !affectedApartmentIds.isEmpty()) {
            for (String affectedApartmentId : affectedApartmentIds) {
                List<ResidentBuilding> residents = residentBuildingRepository
                        .findByBuildingIdAndApartmentId(claim.getBuilding().getBuildingId(), affectedApartmentId);
                for (ResidentBuilding resident : residents) {
                    if (!resident.getResident().getIdUsers().equals(claim.getReporter().getIdUsers())) {
                        ChannelMember member = ChannelMember.builder()
                                .channel(channel)
                                .userId(resident.getResident().getIdUsers())
                                .role(MemberRole.MEMBER)
                                .canWrite(true)
                                .build();
                        channelMemberRepository.save(member);
                    }
                }
            }
        }
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
            notification.setBuildingId(claim.getBuilding().getBuildingId());
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
                    notification.setBuildingId(claim.getBuilding().getBuildingId());
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

        ClaimStatus newStatus = ClaimStatus.valueOf(status);
        claim.setStatus(newStatus);

        // If claim is closed, close the emergency channel
        if (newStatus == ClaimStatus.CLOSED && claim.getEmergencyChannel() != null) {
            Channel channel = claim.getEmergencyChannel();
            channel.setIsClosed(true);
            channelRepository.save(channel);
        }

        claim = claimRepository.save(claim);

        // Send notification to reporter
        NotificationDto notification = new NotificationDto();
        notification.setResidentId(claim.getReporter().getIdUsers());
        notification.setTitle("Mise à jour du statut de votre sinistre");
        notification.setBody(String.format("Le statut de votre sinistre a été mis à jour: %s", status));
        notification.setType("CLAIM_STATUS_UPDATE");
        notification.setRelatedId(claim.getId());
        notification.setBuildingId(claim.getBuilding().getBuildingId());

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
        dto.setEmergencyChannelId(claim.getEmergencyChannel() != null ? claim.getEmergencyChannel().getId() : null);
        dto.setEmergencyFolderId(claim.getEmergencyFolder() != null ? claim.getEmergencyFolder().getId() : null)

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
