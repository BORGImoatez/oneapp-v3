package be.delomid.oneapp.mschat.mschat.service;


import be.delomid.oneapp.mschat.mschat.dto.AddressDto;
import be.delomid.oneapp.mschat.mschat.dto.BuildingDto;
import be.delomid.oneapp.mschat.mschat.dto.CreateBuildingRequest;
import be.delomid.oneapp.mschat.mschat.model.Address;
import be.delomid.oneapp.mschat.mschat.model.Building;
import be.delomid.oneapp.mschat.mschat.model.Country;
import be.delomid.oneapp.mschat.mschat.repository.BuildingRepository;
import be.delomid.oneapp.mschat.mschat.repository.CountryRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.LocalDate;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class BuildingService {

    private final BuildingRepository buildingRepository;
private final CountryRepository countryRepository;
    private final SecureRandom random = new SecureRandom();

    public int generateFourDigitNumber() {
        return 1000 + random.nextInt(9000); // génère un nombre entre 1000 et 9999
    }
    @Transactional
    public BuildingDto createBuilding(CreateBuildingRequest request) {
        log.debug("Creating building: {}", request.getBuildingId());


        if(countryRepository.findByCodeIso3(request.getAddress().getPays())==null) {
            throw new IllegalArgumentException("Country not found");

        }
        Country country=countryRepository.findByCodeIso3(request.getAddress().getPays());
        String randomNumber= String.valueOf(generateFourDigitNumber());
        String buildingId=country.getCodeIso3()+'-'+ LocalDate.now().getYear()+randomNumber;
        log.info("Building ID: {}",buildingId);
        Address address = Address.builder()
                .address(request.getAddress().getAddress())
                .addressSuite(request.getAddress().getAddressSuite())
                .codePostal(request.getAddress().getCodePostal())
                .ville(request.getAddress().getVille())
                .etatDep(request.getAddress().getEtatDep())
                .pays(country)
                .observation(request.getAddress().getObservation())
                .build();

        Building building = Building.builder()
                .buildingId(buildingId)
                .buildingLabel(request.getBuildingLabel())
                .buildingNumber(request.getBuildingNumber())
                .buildingPicture(request.getBuildingPicture())
                .yearOfConstruction(request.getYearOfConstruction())
                .address(address)
                .build();

        building = buildingRepository.save(building);
        log.debug("Building created successfully: {}", building.getBuildingId());

        return convertToDto(building);
    }

    public Page<BuildingDto> getAllBuildings(Pageable pageable) {
        log.debug("Getting all buildings with pagination");
        Page<Building> buildings = buildingRepository.findAll(pageable);
        return buildings.map(this::convertToDto);
    }

    public BuildingDto getBuildingById(String buildingId) {
        Building building = buildingRepository.findById(buildingId)
                .orElseThrow(() -> new IllegalArgumentException("Building not found: " + buildingId));
        return convertToDto(building);
    }

    public List<BuildingDto> getBuildingsByCity(String ville) {
        List<Building> buildings = buildingRepository.findByCity(ville);
        return buildings.stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public List<BuildingDto> getBuildingsByPostalCode(String codePostal) {
        List<Building> buildings = buildingRepository.findByPostalCode(codePostal);
        return buildings.stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public BuildingDto updateBuilding(String buildingId, CreateBuildingRequest request) {
        Building building = buildingRepository.findById(buildingId)
                .orElseThrow(() -> new IllegalArgumentException("Building not found: " + buildingId));

        building.setBuildingLabel(request.getBuildingLabel());
        building.setBuildingNumber(request.getBuildingNumber());
        building.setBuildingPicture(request.getBuildingPicture());
        building.setYearOfConstruction(request.getYearOfConstruction());

        // Update address
        Address address = building.getAddress();
        address.setAddress(request.getAddress().getAddress());
        address.setAddressSuite(request.getAddress().getAddressSuite());
        address.setCodePostal(request.getAddress().getCodePostal());
        address.setVille(request.getAddress().getVille());
        address.setEtatDep(request.getAddress().getEtatDep());
       // address.setPays(request.getAddress().getPays());
        address.setObservation(request.getAddress().getObservation());

        building = buildingRepository.save(building);
        return convertToDto(building);
    }

    @Transactional
    public void deleteBuilding(String buildingId) {
        if (!buildingRepository.existsById(buildingId)) {
            throw new IllegalArgumentException("Building not found: " + buildingId);
        }
        buildingRepository.deleteById(buildingId);
        log.debug("Building deleted: {}", buildingId);
    }

    private BuildingDto convertToDto(Building building) {
        Long totalApartments = buildingRepository.countApartmentsByBuildingId(building.getBuildingId());
        Long occupiedApartments = buildingRepository.countOccupiedApartmentsByBuildingId(building.getBuildingId());

        AddressDto addressDto = null;
        if (building.getAddress() != null) {
            addressDto = AddressDto.builder()
                    .idAddress(building.getAddress().getIdAddress())
                    .address(building.getAddress().getAddress())
                    .addressSuite(building.getAddress().getAddressSuite())
                    .codePostal(building.getAddress().getCodePostal())
                    .ville(building.getAddress().getVille())
                    .etatDep(building.getAddress().getEtatDep())
                   // .pays(building.getAddress().getPays())
                    .observation(building.getAddress().getObservation())
                    .build();
        }

        return BuildingDto.builder()
                .buildingId(building.getBuildingId())
                .buildingLabel(building.getBuildingLabel())
                .buildingNumber(building.getBuildingNumber())
                .buildingPicture(building.getBuildingPicture())
                .yearOfConstruction(building.getYearOfConstruction())
                .address(addressDto)
                .totalApartments(totalApartments)
                .occupiedApartments(occupiedApartments)
                .createdAt(building.getCreatedAt())
                .updatedAt(building.getUpdatedAt())
                .build();
    }
}