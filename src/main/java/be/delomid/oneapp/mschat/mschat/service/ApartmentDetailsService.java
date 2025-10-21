package be.delomid.oneapp.mschat.mschat.service;

import be.delomid.oneapp.mschat.mschat.dto.ApartmentDetailsDto;
import be.delomid.oneapp.mschat.mschat.dto.ApartmentPhotoDto;
import be.delomid.oneapp.mschat.mschat.dto.UpdateApartmentDetailsRequest;
import be.delomid.oneapp.mschat.mschat.model.*;
import be.delomid.oneapp.mschat.mschat.repository.*;
import be.delomid.oneapp.mschat.mschat.util.SecurityContextUtil;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ApartmentDetailsService {

    private final ApartmentRepository apartmentRepository;
    private final ApartmentPhotoRepository photoRepository;
    private final ApartmentGeneralInfoRepository generalInfoRepository;
    private final ApartmentInteriorRepository interiorRepository;
    private final ApartmentExteriorRepository exteriorRepository;
    private final ApartmentInstallationsRepository installationsRepository;
    private final ApartmentEnergieRepository energieRepository;
    private final ResidentBuildingRepository residentBuildingRepository;
    private final FileService fileService;
    private final ObjectMapper objectMapper;

    public ApartmentDetailsDto getApartmentDetails(Long apartmentId) {
        Apartment apartment = apartmentRepository.findById(apartmentId)
                .orElseThrow(() -> new RuntimeException("Apartment not found"));

        Long residentId = SecurityContextUtil.getCurrentUserId();
        verifyResidentHasAccess(residentId, apartment.getBuildingId(), apartmentId);

        ApartmentDetailsDto dto = new ApartmentDetailsDto();
        dto.setApartmentId(apartmentId);
        dto.setApartmentNumber(apartment.getApartmentNumber());

        List<ApartmentPhoto> photos = photoRepository.findByApartmentIdOrderByDisplayOrderAsc(apartmentId);
        dto.setPhotos(photos.stream().map(this::convertToPhotoDto).collect(Collectors.toList()));

        generalInfoRepository.findByApartmentId(apartmentId)
                .ifPresent(info -> dto.setGeneralInfo(convertToGeneralInfoDto(info)));

        interiorRepository.findByApartmentId(apartmentId)
                .ifPresent(interior -> dto.setInterior(convertToInteriorDto(interior)));

        exteriorRepository.findByApartmentId(apartmentId)
                .ifPresent(exterior -> dto.setExterior(convertToExteriorDto(exterior)));

        installationsRepository.findByApartmentId(apartmentId)
                .ifPresent(installations -> dto.setInstallations(convertToInstallationsDto(installations)));

        energieRepository.findByApartmentId(apartmentId)
                .ifPresent(energie -> dto.setEnergie(convertToEnergieDto(energie)));

        return dto;
    }

    @Transactional
    public ApartmentDetailsDto updateApartmentDetails(Long apartmentId, UpdateApartmentDetailsRequest request) {
        Apartment apartment = apartmentRepository.findById(apartmentId)
                .orElseThrow(() -> new RuntimeException("Apartment not found"));

        Long residentId = SecurityContextUtil.getCurrentUserId();
        verifyResidentHasAccess(residentId, apartment.getBuildingId(), apartmentId);

        if (request.getGeneralInfo() != null) {
            updateGeneralInfo(apartmentId, request.getGeneralInfo(), residentId);
        }

        if (request.getInterior() != null) {
            updateInterior(apartmentId, request.getInterior(), residentId);
        }

        if (request.getExterior() != null) {
            updateExterior(apartmentId, request.getExterior(), residentId);
        }

        if (request.getInstallations() != null) {
            updateInstallations(apartmentId, request.getInstallations(), residentId);
        }

        if (request.getEnergie() != null) {
            updateEnergie(apartmentId, request.getEnergie(), residentId);
        }

        return getApartmentDetails(apartmentId);
    }

    @Transactional
    public ApartmentPhotoDto uploadPhoto(Long apartmentId, MultipartFile file) {
        Apartment apartment = apartmentRepository.findById(apartmentId)
                .orElseThrow(() -> new RuntimeException("Apartment not found"));

        Long residentId = SecurityContextUtil.getCurrentUserId();
        verifyResidentHasAccess(residentId, apartment.getBuildingId(), apartmentId);

        String photoUrl = fileService.uploadFile(file, "apartments/" + apartmentId);

        List<ApartmentPhoto> existingPhotos = photoRepository.findByApartmentIdOrderByDisplayOrderAsc(apartmentId);
        int nextOrder = existingPhotos.size();

        ApartmentPhoto photo = new ApartmentPhoto();
        photo.setApartmentId(apartmentId);
        photo.setPhotoUrl(photoUrl);
        photo.setDisplayOrder(nextOrder);
        photo.setUploadedAt(LocalDateTime.now());
        photo.setUploadedBy(residentId);

        photo = photoRepository.save(photo);
        return convertToPhotoDto(photo);
    }

    @Transactional
    public void deletePhoto(Long photoId) {
        ApartmentPhoto photo = photoRepository.findById(photoId)
                .orElseThrow(() -> new RuntimeException("Photo not found"));

        Apartment apartment = apartmentRepository.findById(photo.getApartmentId())
                .orElseThrow(() -> new RuntimeException("Apartment not found"));

        Long residentId = SecurityContextUtil.getCurrentUserId();
        verifyResidentHasAccess(residentId, apartment.getBuildingId(), photo.getApartmentId());

        photoRepository.delete(photo);
    }

    @Transactional
    public void reorderPhotos(Long apartmentId, List<Long> photoIds) {
        Apartment apartment = apartmentRepository.findById(apartmentId)
                .orElseThrow(() -> new RuntimeException("Apartment not found"));

        Long residentId = SecurityContextUtil.getCurrentUserId();
        verifyResidentHasAccess(residentId, apartment.getBuildingId(), apartmentId);

        for (int i = 0; i < photoIds.size(); i++) {
            Long photoId = photoIds.get(i);
            photoRepository.findById(photoId).ifPresent(photo -> {
                if (photo.getApartmentId().equals(apartmentId)) {
                    photo.setDisplayOrder(i);
                    photoRepository.save(photo);
                }
            });
        }
    }

    private void verifyResidentHasAccess(Long residentId, Long buildingId, Long apartmentId) {
        ResidentBuilding rb = residentBuildingRepository
                .findByResidentIdAndBuildingId(residentId, buildingId)
                .orElseThrow(() -> new RuntimeException("Access denied"));

        if (rb.getApartmentId() != null && !rb.getApartmentId().equals(apartmentId)) {
            throw new RuntimeException("You can only manage your own apartment");
        }
    }

    private void updateGeneralInfo(Long apartmentId, UpdateApartmentDetailsRequest.GeneralInfoRequest request, Long residentId) {
        ApartmentGeneralInfo info = generalInfoRepository.findByApartmentId(apartmentId)
                .orElse(new ApartmentGeneralInfo());

        info.setApartmentId(apartmentId);
        info.setNbChambres(request.getNbChambres());
        info.setNbSalleBain(request.getNbSalleBain());
        info.setSurface(request.getSurface());
        info.setEtage(request.getEtage());
        info.setUpdatedAt(LocalDateTime.now());
        info.setUpdatedBy(residentId);

        generalInfoRepository.save(info);
    }

    private void updateInterior(Long apartmentId, UpdateApartmentDetailsRequest.InteriorRequest request, Long residentId) {
        ApartmentInterior interior = interiorRepository.findByApartmentId(apartmentId)
                .orElse(new ApartmentInterior());

        interior.setApartmentId(apartmentId);
        interior.setQuartierLieu(request.getQuartierLieu());
        interior.setSurfaceHabitable(request.getSurfaceHabitable());
        interior.setSurfaceSalon(request.getSurfaceSalon());
        interior.setTypeCuisine(request.getTypeCuisine());
        interior.setSurfaceCuisine(request.getSurfaceCuisine());

        if (request.getSurfaceChambres() != null) {
            try {
                interior.setSurfaceChambres(objectMapper.writeValueAsString(request.getSurfaceChambres()));
            } catch (JsonProcessingException e) {
                throw new RuntimeException("Error serializing room surfaces", e);
            }
        }

        interior.setNbSalleDouche(request.getNbSalleDouche());
        interior.setNbToilette(request.getNbToilette());
        interior.setCave(request.getCave());
        interior.setGrenier(request.getGrenier());
        interior.setUpdatedAt(LocalDateTime.now());
        interior.setUpdatedBy(residentId);

        interiorRepository.save(interior);
    }

    private void updateExterior(Long apartmentId, UpdateApartmentDetailsRequest.ExteriorRequest request, Long residentId) {
        ApartmentExterior exterior = exteriorRepository.findByApartmentId(apartmentId)
                .orElse(new ApartmentExterior());

        exterior.setApartmentId(apartmentId);
        exterior.setSurfaceTerrasse(request.getSurfaceTerrasse());
        exterior.setOrientationTerrasse(request.getOrientationTerrasse());
        exterior.setUpdatedAt(LocalDateTime.now());
        exterior.setUpdatedBy(residentId);

        exteriorRepository.save(exterior);
    }

    private void updateInstallations(Long apartmentId, UpdateApartmentDetailsRequest.InstallationsRequest request, Long residentId) {
        ApartmentInstallations installations = installationsRepository.findByApartmentId(apartmentId)
                .orElse(new ApartmentInstallations());

        installations.setApartmentId(apartmentId);
        installations.setAscenseur(request.getAscenseur());
        installations.setAccesHandicap(request.getAccesHandicap());
        installations.setParlophone(request.getParlophone());
        installations.setInterphoneVideo(request.getInterphoneVideo());
        installations.setPorteBlindee(request.getPorteBlindee());
        installations.setPiscine(request.getPiscine());
        installations.setUpdatedAt(LocalDateTime.now());
        installations.setUpdatedBy(residentId);

        installationsRepository.save(installations);
    }

    private void updateEnergie(Long apartmentId, UpdateApartmentDetailsRequest.EnergieRequest request, Long residentId) {
        ApartmentEnergie energie = energieRepository.findByApartmentId(apartmentId)
                .orElse(new ApartmentEnergie());

        energie.setApartmentId(apartmentId);
        energie.setClasseEnergetique(request.getClasseEnergetique());
        energie.setConsommationEnergiePrimaire(request.getConsommationEnergiePrimaire());
        energie.setConsommationTheoriqueTotale(request.getConsommationTheoriqueTotale());
        energie.setEmissionCo2(request.getEmissionCo2());
        energie.setNumeroRapportPeb(request.getNumeroRapportPeb());
        energie.setTypeChauffage(request.getTypeChauffage());
        energie.setDoubleVitrage(request.getDoubleVitrage());
        energie.setUpdatedAt(LocalDateTime.now());
        energie.setUpdatedBy(residentId);

        energieRepository.save(energie);
    }

    private ApartmentPhotoDto convertToPhotoDto(ApartmentPhoto photo) {
        return new ApartmentPhotoDto(
                photo.getId(),
                photo.getApartmentId(),
                photo.getPhotoUrl(),
                photo.getDisplayOrder(),
                photo.getUploadedAt(),
                photo.getUploadedBy()
        );
    }

    private ApartmentDetailsDto.GeneralInfoDto convertToGeneralInfoDto(ApartmentGeneralInfo info) {
        return new ApartmentDetailsDto.GeneralInfoDto(
                info.getId(),
                info.getNbChambres(),
                info.getNbSalleBain(),
                info.getSurface(),
                info.getEtage(),
                info.getUpdatedAt()
        );
    }

    private ApartmentDetailsDto.InteriorDto convertToInteriorDto(ApartmentInterior interior) {
        List<BigDecimal> surfaceChambres = new ArrayList<>();
        if (interior.getSurfaceChambres() != null) {
            try {
                surfaceChambres = objectMapper.readValue(
                        interior.getSurfaceChambres(),
                        objectMapper.getTypeFactory().constructCollectionType(List.class, BigDecimal.class)
                );
            } catch (JsonProcessingException e) {
                surfaceChambres = new ArrayList<>();
            }
        }

        return new ApartmentDetailsDto.InteriorDto(
                interior.getId(),
                interior.getQuartierLieu(),
                interior.getSurfaceHabitable(),
                interior.getSurfaceSalon(),
                interior.getTypeCuisine(),
                interior.getSurfaceCuisine(),
                surfaceChambres,
                interior.getNbSalleDouche(),
                interior.getNbToilette(),
                interior.getCave(),
                interior.getGrenier(),
                interior.getUpdatedAt()
        );
    }

    private ApartmentDetailsDto.ExteriorDto convertToExteriorDto(ApartmentExterior exterior) {
        return new ApartmentDetailsDto.ExteriorDto(
                exterior.getId(),
                exterior.getSurfaceTerrasse(),
                exterior.getOrientationTerrasse(),
                exterior.getUpdatedAt()
        );
    }

    private ApartmentDetailsDto.InstallationsDto convertToInstallationsDto(ApartmentInstallations installations) {
        return new ApartmentDetailsDto.InstallationsDto(
                installations.getId(),
                installations.getAscenseur(),
                installations.getAccesHandicap(),
                installations.getParlophone(),
                installations.getInterphoneVideo(),
                installations.getPorteBlindee(),
                installations.getPiscine(),
                installations.getUpdatedAt()
        );
    }

    private ApartmentDetailsDto.EnergieDto convertToEnergieDto(ApartmentEnergie energie) {
        return new ApartmentDetailsDto.EnergieDto(
                energie.getId(),
                energie.getClasseEnergetique(),
                energie.getConsommationEnergiePrimaire(),
                energie.getConsommationTheoriqueTotale(),
                energie.getEmissionCo2(),
                energie.getNumeroRapportPeb(),
                energie.getTypeChauffage(),
                energie.getDoubleVitrage(),
                energie.getUpdatedAt()
        );
    }
}
