package be.delomid.oneapp.mschat.mschat.service;

import be.delomid.oneapp.mschat.mschat.config.AppConfig;
import be.delomid.oneapp.mschat.mschat.model.*;
import be.delomid.oneapp.mschat.mschat.repository.ApartmentRepository;
import be.delomid.oneapp.mschat.mschat.repository.BuildingRepository;
import be.delomid.oneapp.mschat.mschat.repository.CountryRepository;
import be.delomid.oneapp.mschat.mschat.repository.ResidentRepository;
import be.delomid.oneapp.mschat.mschat.repository.ResidentBuildingRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class DataInitializationService implements CommandLineRunner {

    private final CountryRepository countryRepository;
    private final ResidentRepository residentRepository;
    private final BuildingRepository buildingRepository;
    private final ApartmentRepository apartmentRepository;
    private final ResidentBuildingRepository residentBuildingRepository;
    private final PasswordEncoder passwordEncoder;
    private final AppConfig appConfig;

    @Override
    @Transactional
    public void run(String... args) {
        log.info("Initializing application data...");

        initializeCountries();
        initializeSuperAdmin();
        initializeTestData();

        log.info("Application data initialization completed");
    }

    private void initializeCountries() {
        if (countryRepository.count() == 0) {
            log.info("Initializing countries data...");

            List<Country> countries = Arrays.asList(
                    new Country(null, "France", "FR", "FRA", null),
                    new Country(null, "Belgique", "BE", "BEL", null),
                    new Country(null, "Suisse", "CH", "CHE", null),
                    new Country(null, "Canada", "CA", "CAN", null),
                    new Country(null, "Maroc", "MA", "MAR", null),
                    new Country(null, "Tunisie", "TN", "TUN", null),
                    new Country(null, "Algérie", "DZ", "DZA", null)
            );

            countryRepository.saveAll(countries);
            log.info("Countries initialized: {} countries added", countries.size());
        }
    }

    private void initializeSuperAdmin() {
        String adminEmail = appConfig.getAdmin().getDefaultSuperAdminEmail();
        String adminPassword = appConfig.getAdmin().getDefaultSuperAdminPassword();

        if (adminEmail != null && adminPassword != null &&
                residentRepository.findByEmail(adminEmail).isEmpty()) {

            log.info("Creating default super admin...");

            Resident superAdmin = Resident.builder()
                    .idUsers(UUID.randomUUID().toString())
                    .fname("Super")
                    .lname("Admin")
                    .email(adminEmail)
                    .password(passwordEncoder.encode(adminPassword))
                    .role(UserRole.SUPER_ADMIN)
                    .accountStatus(AccountStatus.ACTIVE)
                    .isEnabled(true)
                    .isAccountNonExpired(true)
                    .isAccountNonLocked(true)
                    .isCredentialsNonExpired(true)
                    .build();

            residentRepository.save(superAdmin);
            log.info("Super admin created with email: {}", adminEmail);
        }
    }

    private void initializeTestData() {
        // Créer un immeuble de test
        if (buildingRepository.count() == 0) {
            log.info("Creating test building and residents...");

            Country france = countryRepository.findByCodeIso3("FRA");
            if (france == null) {
                france = countryRepository.findAll().get(0); // Prendre le premier pays disponible
            }

            // Créer une adresse de test
            Address testAddress = Address.builder()
                    .address("123 Rue de la Paix")
                    .codePostal("75001")
                    .ville("Paris")
                    .pays(france)
                    .build();

            // Créer un immeuble de test
            Building testBuilding = Building.builder()
                    .buildingId("FRA-2024-TEST")
                    .buildingLabel("Résidence Test")
                    .buildingNumber("123")
                    .yearOfConstruction(2020)
                    .address(testAddress)
                    .build();

            testBuilding = buildingRepository.save(testBuilding);

            // Créer des appartements de test
            Apartment apartment1 = Apartment.builder()
                    .idApartment("FRA-2024-TEST-A101")
                    .apartmentLabel("Appartement 101")
                    .apartmentNumber("101")
                    .apartmentFloor(1)
                    .livingAreaSurface(new BigDecimal("65.5"))
                    .numberOfRooms(3)
                    .numberOfBedrooms(2)
                    .haveBalconyOrTerrace(true)
                    .isFurnished(false)
                    .building(testBuilding)
                    .build();

            Apartment apartment2 = Apartment.builder()
                    .idApartment("FRA-2024-TEST-A102")
                    .apartmentLabel("Appartement 102")
                    .apartmentNumber("102")
                    .apartmentFloor(1)
                    .livingAreaSurface(new BigDecimal("58.0"))
                    .numberOfRooms(2)
                    .numberOfBedrooms(1)
                    .haveBalconyOrTerrace(false)
                    .isFurnished(true)
                    .building(testBuilding)
                    .build();

            apartment1 = apartmentRepository.save(apartment1);
            apartment2 = apartmentRepository.save(apartment2);

            // Créer des résidents de test
            Resident resident1 = Resident.builder()
                    .idUsers(UUID.randomUUID().toString())
                    .fname("Moatez")
                    .lname("BORGI")
                    .email("moatezelborgi@gmail.com")
                    .password(passwordEncoder.encode("password123"))
                    .phoneNumber("+33123456789")
                    .role(UserRole.RESIDENT)
                    .accountStatus(AccountStatus.ACTIVE)
                    .isEnabled(true)
                    .isAccountNonExpired(true)
                    .isAccountNonLocked(true)
                    .isCredentialsNonExpired(true)
                    .build();

            Resident resident2 = Resident.builder()
                    .idUsers(UUID.randomUUID().toString())
                    .fname("Test")
                    .lname("Test")
                    .email("moatezborgi@softverse.com")
                    .password(passwordEncoder.encode("password123"))
                    .phoneNumber("+33987654321")
                    .role(UserRole.RESIDENT)
                    .accountStatus(AccountStatus.ACTIVE)
                    .isEnabled(true)
                    .isAccountNonExpired(true)
                    .isAccountNonLocked(true).build();
            resident1 = residentRepository.save(resident1);

            resident2 = residentRepository.save(resident2);

            // Assigner les résidents aux appartements
            apartment1.setResident(resident1);
            apartment2.setResident(resident2);
            apartmentRepository.save(apartment1);
            apartmentRepository.save(apartment2);

            // Créer les relations ResidentBuilding
            ResidentBuilding residentBuilding1 = ResidentBuilding.builder()
                    .resident(resident1)
                    .building(testBuilding)
                    .apartment(apartment1)
                    .roleInBuilding(UserRole.RESIDENT)
                    .build();

            ResidentBuilding residentBuilding2 = ResidentBuilding.builder()
                    .resident(resident2)
                    .building(testBuilding)
                    .apartment(apartment2)
                    .roleInBuilding(UserRole.RESIDENT)
                    .build();

            residentBuildingRepository.save(residentBuilding1);
            residentBuildingRepository.save(residentBuilding2);

            // Créer un deuxième bâtiment pour tester le multi-bâtiment
            Building testBuilding2 = Building.builder()
                    .buildingId("FRA-2024-TEST2")
                    .buildingLabel("Résidence Test 2")
                    .buildingNumber("456")
                    .yearOfConstruction(2022)
                    .address(Address.builder()
                            .address("456 Avenue des Champs")
                            .codePostal("75008")
                            .ville("Paris")
                            .pays(france)
                            .build())
                    .build();

            testBuilding2 = buildingRepository.save(testBuilding2);

            // Ajouter resident1 comme admin du deuxième bâtiment
            ResidentBuilding residentBuilding1Admin = ResidentBuilding.builder()
                    .resident(resident1)
                    .building(testBuilding2)
                    .roleInBuilding(UserRole.BUILDING_ADMIN)
                    .build();

            residentBuildingRepository.save(residentBuilding1Admin);

            // Créer un troisième bâtiment pour tester avec resident1 comme résident simple
            Building testBuilding3 = Building.builder()
                    .buildingId("FRA-2024-TEST3")
                    .buildingLabel("Résidence Test 3")
                    .buildingNumber("789")
                    .yearOfConstruction(2023)
                    .address(Address.builder()
                            .address("789 Boulevard Saint-Germain")
                            .codePostal("75006")
                            .ville("Paris")
                            .pays(france)
                            .build())
                    .build();

            testBuilding3 = buildingRepository.save(testBuilding3);

            // Créer un appartement dans le troisième bâtiment
            Apartment apartment3 = Apartment.builder()
                    .idApartment("FRA-2024-TEST3-A201")
                    .apartmentLabel("Appartement 201")
                    .apartmentNumber("201")
                    .apartmentFloor(2)
                    .livingAreaSurface(new BigDecimal("75.0"))
                    .numberOfRooms(4)
                    .numberOfBedrooms(3)
                    .haveBalconyOrTerrace(true)
                    .isFurnished(false)
                    .building(testBuilding3)
                    .build();

            apartment3 = apartmentRepository.save(apartment3);

            // Ajouter resident1 comme résident du troisième bâtiment
            ResidentBuilding residentBuilding1Resident = ResidentBuilding.builder()
                    .resident(resident1)
                    .building(testBuilding3)
                    .apartment(apartment3)
                    .roleInBuilding(UserRole.RESIDENT)
                    .build();

            residentBuildingRepository.save(residentBuilding1Resident);

            // ==================== RÉSUMÉ ====================

        }
    }
}