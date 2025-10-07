package be.delomid.oneapp.mschat.mschat.service;


import be.delomid.oneapp.mschat.mschat.dto.CreateResidentRequest;
import be.delomid.oneapp.mschat.mschat.dto.ResidentDto;
import be.delomid.oneapp.mschat.mschat.model.AccountStatus;
import be.delomid.oneapp.mschat.mschat.model.Apartment;
import be.delomid.oneapp.mschat.mschat.model.Resident;
import be.delomid.oneapp.mschat.mschat.model.UserRole;
import be.delomid.oneapp.mschat.mschat.repository.ApartmentRepository;
import be.delomid.oneapp.mschat.mschat.repository.ResidentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
 import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class ResidentService {

    private final ResidentRepository residentRepository;
    private final ApartmentRepository apartmentRepository;
    private final PasswordEncoder passwordEncoder;

    @Transactional
    public ResidentDto createResident(CreateResidentRequest request) {
        log.debug("Creating resident: {}", request.getIdUsers());


        // Vérifier si l'email existe déjà
        residentRepository.findByEmail(request.getEmail()).ifPresent(existing -> {
            throw new IllegalArgumentException("Email already exists: " + request.getEmail());
        });

        Resident resident = Resident.builder()
                .idUsers(String.valueOf(UUID.randomUUID()))
                .fname(request.getFname())
                .lname(request.getLname())
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .phoneNumber(request.getPhoneNumber())
                .picture(request.getPicture())
                .role(UserRole.RESIDENT)
                .accountStatus(AccountStatus.PENDING)
                .build();

        resident = residentRepository.save(resident);
        log.debug("Resident created successfully: {}", resident.getIdUsers());

        return convertToDto(resident);
    }

    public Page<ResidentDto> getAllResidents(Pageable pageable) {
        log.debug("Getting all residents with pagination");
        Page<Resident> residents = residentRepository.findAll(pageable);
        return residents.map(this::convertToDto);
    }

    public ResidentDto getResidentById(String userId) {
        Resident resident = residentRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Resident not found: " + userId));
        return convertToDto(resident);
    }

    public Optional<ResidentDto> getResidentByEmail(String email) {
        return residentRepository.findByEmail(email)
                .map(this::convertToDto);
    }

    public List<ResidentDto> getResidentsByBuilding(String buildingId) {
        List<Resident> residents = residentRepository.findByBuildingId(buildingId);
        return residents.stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public Page<ResidentDto> searchResidentsByName(String name, Pageable pageable) {
        Page<Resident> residents = residentRepository.findByNameContaining(name, pageable);
        return residents.map(this::convertToDto);
    }

    @Transactional
    public ResidentDto updateResident(String userId, CreateResidentRequest request) {
        Resident resident = residentRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Resident not found: " + userId));

        // Vérifier si l'email existe déjà pour un autre utilisateur
        residentRepository.findByEmail(request.getEmail()).ifPresent(existing -> {
            if (!existing.getIdUsers().equals(userId)) {
                throw new IllegalArgumentException("Email already exists: " + request.getEmail());
            }
        });

        resident.setFname(request.getFname());
        resident.setLname(request.getLname());
        resident.setEmail(request.getEmail());
        if (request.getPassword() != null && !request.getPassword().isEmpty()) {
            resident.setPassword(passwordEncoder.encode(request.getPassword()));
        }
        resident.setPhoneNumber(request.getPhoneNumber());
        resident.setPicture(request.getPicture());

        resident = residentRepository.save(resident);
        return convertToDto(resident);
    }

    @Transactional
    public void deleteResident(String userId) {
        Resident resident = residentRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Resident not found: " + userId));

        // Libérer l'appartement si le résident en a un
        Optional<Apartment> apartment = apartmentRepository.findByResidentIdUsers(userId);
        apartment.ifPresent(apt -> {
            apt.setResident(null);
            apartmentRepository.save(apt);
        });

        residentRepository.deleteById(userId);
        log.debug("Resident deleted: {}", userId);
    }

    public Optional<ResidentDto> getResidentApartmentInfo(String userId) {
        return apartmentRepository.findByResidentIdUsers(userId)
                .map(apartment -> {
                    Resident resident = apartment.getResident();
                    return convertToDto(resident);
                });
    }

    private ResidentDto convertToDto(Resident resident) {
        String apartmentId = null;
        String buildingId = null;

        if (resident.getApartment() != null) {
            apartmentId = resident.getApartment().getIdApartment();
            buildingId = resident.getApartment().getBuilding().getBuildingId();
        }

        return ResidentDto.builder()
                .idUsers(String.valueOf(resident.getIdUsers()))
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