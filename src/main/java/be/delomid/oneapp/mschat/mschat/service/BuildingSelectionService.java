package be.delomid.oneapp.mschat.mschat.service;

import be.delomid.oneapp.mschat.mschat.config.JwtConfig;
import be.delomid.oneapp.mschat.mschat.dto.AddressDto;
import be.delomid.oneapp.mschat.mschat.dto.AuthResponse;
import be.delomid.oneapp.mschat.mschat.dto.BuildingSelectionDto;
import be.delomid.oneapp.mschat.mschat.model.Resident;
import be.delomid.oneapp.mschat.mschat.model.ResidentBuilding;
import be.delomid.oneapp.mschat.mschat.repository.ResidentBuildingRepository;
import be.delomid.oneapp.mschat.mschat.repository.ResidentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class BuildingSelectionService {

    private final ResidentBuildingRepository residentBuildingRepository;
    private final ResidentRepository residentRepository;
    private final JwtConfig jwtConfig;

    public List<BuildingSelectionDto> getUserBuildings(String userId) {
        log.debug("Getting buildings for user: {}", userId);

        // Récupérer l'utilisateur par email ou ID
        Resident resident = residentRepository.findByEmail(userId)
                .or(() -> residentRepository.findById(userId))
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + userId));

        List<ResidentBuilding> residentBuildings = residentBuildingRepository.findActiveByResidentId(resident.getIdUsers());

        return residentBuildings.stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public AuthResponse selectBuilding(String userId, String buildingId) {
        log.debug("User {} selecting building: {}", userId, buildingId);

        // Récupérer l'utilisateur
        Resident resident = residentRepository.findByEmail(userId)
                .or(() -> residentRepository.findById(userId))
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + userId));

        // Vérifier que l'utilisateur a accès à ce bâtiment
        ResidentBuilding residentBuilding = residentBuildingRepository
                .findByResidentIdAndBuildingId(resident.getIdUsers(), buildingId)
                .or(() -> residentBuildingRepository.findByResidentEmailAndBuildingId(resident.getEmail(), buildingId))
                .orElseThrow(() -> new IllegalArgumentException("User does not have access to this building"));

        // Générer un nouveau token avec les informations du bâtiment sélectionné
        String token = jwtConfig.generateTokenWithBuilding(
                resident.getEmail(),
                resident.getIdUsers(),
                residentBuilding.getRoleInBuilding().name(),
                buildingId
        );

        String refreshToken = jwtConfig.generateRefreshToken(
                resident.getEmail(),
                resident.getIdUsers()
        );

        String apartmentId = null;
        if (residentBuilding.getApartment() != null) {
            apartmentId = residentBuilding.getApartment().getIdApartment();
        }

        log.debug("Building selected successfully: {} for user: {}", buildingId, userId);

        return AuthResponse.builder()
                .token(token)
                .refreshToken(refreshToken)
                .userId(resident.getIdUsers())
                .email(resident.getEmail())
                .fname(resident.getFname())
                .lname(resident.getLname())
                .role(residentBuilding.getRoleInBuilding())
                .accountStatus(resident.getAccountStatus())
                .buildingId(buildingId)
                .apartmentId(apartmentId)
                .otpRequired(false)
                .message("Bâtiment sélectionné avec succès")
                .build();
    }

    private BuildingSelectionDto convertToDto(ResidentBuilding residentBuilding) {
        AddressDto addressDto = null;
        if (residentBuilding.getBuilding().getAddress() != null) {
            addressDto = AddressDto.builder()
                    .idAddress(residentBuilding.getBuilding().getAddress().getIdAddress())
                    .address(residentBuilding.getBuilding().getAddress().getAddress())
                    .addressSuite(residentBuilding.getBuilding().getAddress().getAddressSuite())
                    .codePostal(residentBuilding.getBuilding().getAddress().getCodePostal())
                    .ville(residentBuilding.getBuilding().getAddress().getVille())
                    .etatDep(residentBuilding.getBuilding().getAddress().getEtatDep())
                    .observation(residentBuilding.getBuilding().getAddress().getObservation())
                    .build();
        }

        String apartmentId = null;
        String apartmentLabel = null;
        String apartmentNumber = null;
        Integer apartmentFloor = null;

        if (residentBuilding.getApartment() != null) {
            apartmentId = residentBuilding.getApartment().getIdApartment();
            apartmentLabel = residentBuilding.getApartment().getApartmentLabel();
            apartmentNumber = residentBuilding.getApartment().getApartmentNumber();
            apartmentFloor = residentBuilding.getApartment().getApartmentFloor();
        }

        return BuildingSelectionDto.builder()
                .buildingId(residentBuilding.getBuilding().getBuildingId())
                .buildingLabel(residentBuilding.getBuilding().getBuildingLabel())
                .buildingNumber(residentBuilding.getBuilding().getBuildingNumber())
                .buildingPicture(residentBuilding.getBuilding().getBuildingPicture())
                .address(addressDto)
                .roleInBuilding(residentBuilding.getRoleInBuilding())
                .apartmentId(apartmentId)
                .apartmentLabel(apartmentLabel)
                .apartmentNumber(apartmentNumber)
                .apartmentFloor(apartmentFloor)
                .build();
    }
}