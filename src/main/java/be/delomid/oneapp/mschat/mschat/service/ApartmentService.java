package be.delomid.oneapp.mschat.mschat.service;


import be.delomid.oneapp.mschat.mschat.dto.ApartmentDto;
import be.delomid.oneapp.mschat.mschat.dto.CreateApartmentRequest;
import be.delomid.oneapp.mschat.mschat.dto.ResidentDto;
import be.delomid.oneapp.mschat.mschat.model.Apartment;
import be.delomid.oneapp.mschat.mschat.model.Building;
import be.delomid.oneapp.mschat.mschat.model.Resident;
import be.delomid.oneapp.mschat.mschat.model.ResidentBuilding;
import be.delomid.oneapp.mschat.mschat.repository.ApartmentRepository;
import be.delomid.oneapp.mschat.mschat.repository.BuildingRepository;
import be.delomid.oneapp.mschat.mschat.repository.ResidentRepository;
import be.delomid.oneapp.mschat.mschat.repository.ResidentBuildingRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class ApartmentService {

    private final ApartmentRepository apartmentRepository;
    private final BuildingRepository buildingRepository;
    private final ResidentRepository residentRepository;
    private final ResidentBuildingRepository residentBuildingRepository;

    @Transactional
    public ApartmentDto createApartment(CreateApartmentRequest request) {
        log.debug("Creating apartment: {} in building: {}", request.getApartmentLabel(), request.getBuildingId());

        Building building = buildingRepository.findById(request.getBuildingId())
                .orElseThrow(() -> new IllegalArgumentException("Building not found: " + request.getBuildingId()));
        String apartmentId=request.getBuildingId()+"-"+ LocalDate.now().getYear()+request.getApartmentNumber();
        Apartment apartment = Apartment.builder()
                .idApartment(apartmentId)
                .apartmentLabel(request.getApartmentLabel())
                .apartmentNumber(request.getApartmentNumber())
                .apartmentFloor(request.getApartmentFloor())
                .livingAreaSurface(request.getLivingAreaSurface())
                .numberOfRooms(request.getNumberOfRooms())
                .numberOfBedrooms(request.getNumberOfBedrooms())
                .haveBalconyOrTerrace(request.getHaveBalconyOrTerrace())
                .isFurnished(request.getIsFurnished())
                .building(building)
                .build();

        apartment = apartmentRepository.save(apartment);
        log.debug("Apartment created successfully: {}", apartment.getIdApartment());

        return convertToDto(apartment);
    }

    public Page<ApartmentDto> getApartmentsByBuilding(String buildingId, Pageable pageable) {
        log.debug("Getting apartments for building: {}", buildingId);
        Page<Apartment> apartments = apartmentRepository.findByBuildingBuildingId(buildingId, pageable);
        return apartments.map(this::convertToDto);
    }

    public ApartmentDto getApartmentById(String apartmentId) {
        Apartment apartment = apartmentRepository.findById(apartmentId)
                .orElseThrow(() -> new IllegalArgumentException("Apartment not found: " + apartmentId));
        return convertToDto(apartment);
    }

    public List<ApartmentDto> getAvailableApartments(String buildingId) {
        List<Apartment> apartments = apartmentRepository.findAvailableApartmentsByBuildingId(buildingId);
        return apartments.stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public List<ApartmentDto> getOccupiedApartments(String buildingId) {
        List<Apartment> apartments = apartmentRepository.findOccupiedApartmentsByBuildingId(buildingId);
        return apartments.stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public ApartmentDto assignResidentToApartment(String apartmentId, String userId) {
        Apartment apartment = apartmentRepository.findById(apartmentId)
                .orElseThrow(() -> new IllegalArgumentException("Apartment not found: " + apartmentId));

        if (apartment.getResident() != null) {
            throw new IllegalStateException("Apartment is already occupied");
        }

        Resident resident = residentRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Resident not found: " + userId));

        // Vérifier si le résident n'a pas déjà un appartement
        apartmentRepository.findByResidentIdUsers(userId).ifPresent(existingApt -> {
            throw new IllegalStateException("Resident already has an apartment");
        });

        apartment.setResident(resident);
        apartment = apartmentRepository.save(apartment);

        log.debug("Resident {} assigned to apartment {}", userId, apartmentId);
        return convertToDto(apartment);
    }

    @Transactional
    public ApartmentDto removeResidentFromApartment(String apartmentId) {
        Apartment apartment = apartmentRepository.findById(apartmentId)
                .orElseThrow(() -> new IllegalArgumentException("Apartment not found: " + apartmentId));

        apartment.setResident(null);
        apartment = apartmentRepository.save(apartment);

        log.debug("Resident removed from apartment {}", apartmentId);
        return convertToDto(apartment);
    }

    @Transactional
    public ApartmentDto updateApartment(String apartmentId, CreateApartmentRequest request) {
        Apartment apartment = apartmentRepository.findById(apartmentId)
                .orElseThrow(() -> new IllegalArgumentException("Apartment not found: " + apartmentId));

        apartment.setApartmentLabel(request.getApartmentLabel());
        apartment.setApartmentNumber(request.getApartmentNumber());
        apartment.setApartmentFloor(request.getApartmentFloor());
        apartment.setLivingAreaSurface(request.getLivingAreaSurface());
        apartment.setNumberOfRooms(request.getNumberOfRooms());
        apartment.setNumberOfBedrooms(request.getNumberOfBedrooms());
        apartment.setHaveBalconyOrTerrace(request.getHaveBalconyOrTerrace());
        apartment.setIsFurnished(request.getIsFurnished());

        apartment = apartmentRepository.save(apartment);
        return convertToDto(apartment);
    }

    @Transactional
    public void deleteApartment(String apartmentId) {
        Apartment apartment = apartmentRepository.findById(apartmentId)
                .orElseThrow(() -> new IllegalArgumentException("Apartment not found: " + apartmentId));

        if (apartment.getResident() != null) {
            throw new IllegalStateException("Cannot delete occupied apartment");
        }

        apartmentRepository.deleteById(apartmentId);
        log.debug("Apartment deleted: {}", apartmentId);
    }

    public ApartmentDto getCurrentUserApartment(String buildingId, String userId) {
        log.debug("Getting apartment for user {} in building {}", userId, buildingId);

        Optional<ResidentBuilding> residentBuilding =
                residentBuildingRepository.findByResidentIdAndBuildingId(userId, buildingId)
                        .or(() -> residentBuildingRepository.findByResidentEmailAndBuildingId(userId, buildingId));


        if (residentBuilding.isEmpty() || residentBuilding.get().getApartment() == null) {
            throw new IllegalArgumentException("No apartment found for current user in building: " + buildingId);
        }

        Apartment apartment = residentBuilding.get().getApartment();
        return convertToDto(apartment);
    }

    private ApartmentDto convertToDto(Apartment apartment) {
        ResidentDto residentDto = null;
        if (apartment.getResident() != null) {
            Resident resident = apartment.getResident();
            residentDto = ResidentDto.builder()
                    .idUsers(String.valueOf(resident.getIdUsers()))
                    .fname(resident.getFname())
                    .lname(resident.getLname())
                    .email(resident.getEmail())
                    .phoneNumber(resident.getPhoneNumber())
                    .picture(resident.getPicture())
                    .apartmentId(apartment.getIdApartment())
                    .buildingId(apartment.getBuilding().getBuildingId())
                    .createdAt(resident.getCreatedAt())
                    .updatedAt(resident.getUpdatedAt())
                    .build();
        }

        return ApartmentDto.builder()
                .id(apartment.getIdApartment())
                .idApartment(apartment.getIdApartment())
                .apartmentLabel(apartment.getApartmentLabel())
                .apartmentNumber(apartment.getApartmentNumber())
                .apartmentFloor(apartment.getApartmentFloor())
                .floor(apartment.getApartmentFloor())
                .livingAreaSurface(apartment.getLivingAreaSurface())
                .numberOfRooms(apartment.getNumberOfRooms())
                .numberOfBedrooms(apartment.getNumberOfBedrooms())
                .haveBalconyOrTerrace(apartment.getHaveBalconyOrTerrace())
                .isFurnished(apartment.getIsFurnished())
                .buildingId(apartment.getBuilding().getBuildingId())
                .resident(residentDto)
                .createdAt(apartment.getCreatedAt())
                .updatedAt(apartment.getUpdatedAt())
                .build();
    }
}