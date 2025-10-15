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
        if (buildingRepository.count() == 0) {
            log.info("Creating test buildings and residents...");

            Country belgium = countryRepository.findByCodeIso3("BEL");
            if (belgium == null) {
                belgium = countryRepository.findAll().get(0);
            }

            // ==================== BUILDING 1: DELOMID DM LIEGE ====================

            Address addressLiege = Address.builder()
                    .address("Rue de la Régence 1")
                    .codePostal("4000")
                    .ville("Liège")
                    .pays(belgium)
                    .build();

            Building buildingLiege = Building.builder()
                    .buildingId("BEL-2024-DM-LIEGE")
                    .buildingLabel("Delomid DM Liège")
                    .buildingNumber("1")
                    .yearOfConstruction(2020)
                    .address(addressLiege)
                    .build();

            buildingLiege = buildingRepository.save(buildingLiege);
            log.info("Building 1 created: Delomid DM Liège");

            // Créer 3 appartements pour Liège
            Apartment aptLiege1 = Apartment.builder()
                    .idApartment("BEL-2024-DM-LIEGE-A101")
                    .apartmentLabel("Appartement 101")
                    .apartmentNumber("101")
                    .apartmentFloor(1)
                    .livingAreaSurface(new BigDecimal("75.0"))
                    .numberOfRooms(3)
                    .numberOfBedrooms(2)
                    .haveBalconyOrTerrace(true)
                    .isFurnished(false)
                    .building(buildingLiege)
                    .build();

            Apartment aptLiege2 = Apartment.builder()
                    .idApartment("BEL-2024-DM-LIEGE-A102")
                    .apartmentLabel("Appartement 102")
                    .apartmentNumber("102")
                    .apartmentFloor(1)
                    .livingAreaSurface(new BigDecimal("65.0"))
                    .numberOfRooms(2)
                    .numberOfBedrooms(1)
                    .haveBalconyOrTerrace(false)
                    .isFurnished(true)
                    .building(buildingLiege)
                    .build();

            Apartment aptLiege3 = Apartment.builder()
                    .idApartment("BEL-2024-DM-LIEGE-A201")
                    .apartmentLabel("Appartement 201")
                    .apartmentNumber("201")
                    .apartmentFloor(2)
                    .livingAreaSurface(new BigDecimal("80.0"))
                    .numberOfRooms(4)
                    .numberOfBedrooms(3)
                    .haveBalconyOrTerrace(true)
                    .isFurnished(false)
                    .building(buildingLiege)
                    .build();

            aptLiege1 = apartmentRepository.save(aptLiege1);
            aptLiege2 = apartmentRepository.save(aptLiege2);
            aptLiege3 = apartmentRepository.save(aptLiege3);
            log.info("3 apartments created for Delomid DM Liège");

            // Créer les résidents pour Liège
            Resident siamak = Resident.builder()
                    .idUsers(UUID.randomUUID().toString())
                    .fname("Siamak")
                    .lname("Miandarbandi")
                    .email("siamak.miandarbandi@delomid.com")
                    .password(passwordEncoder.encode("password123"))
                    .phoneNumber("+32470123456")
                    .role(UserRole.RESIDENT)
                    .accountStatus(AccountStatus.ACTIVE)
                    .isEnabled(true)
                    .isAccountNonExpired(true)
                    .isAccountNonLocked(true)
                    .isCredentialsNonExpired(true)
                    .build();

            Resident moatezLiege = Resident.builder()
                    .idUsers(UUID.randomUUID().toString())
                    .fname("Moatez")
                    .lname("Borgi")
                    .email("moatez.borgi@delomid.com")
                    .password(passwordEncoder.encode("password123"))
                    .phoneNumber("+32470234567")
                    .role(UserRole.RESIDENT)
                    .accountStatus(AccountStatus.ACTIVE)
                    .isEnabled(true)
                    .isAccountNonExpired(true)
                    .isAccountNonLocked(true)
                    .isCredentialsNonExpired(true)
                    .build();

            Resident farzanehLiege = Resident.builder()
                    .idUsers(UUID.randomUUID().toString())
                    .fname("Farzaneh")
                    .lname("Hajjel")
                    .email("farzaneh.hajjel@delomid.com")
                    .password(passwordEncoder.encode("password123"))
                    .phoneNumber("+32470345678")
                    .role(UserRole.RESIDENT)
                    .accountStatus(AccountStatus.ACTIVE)
                    .isEnabled(true)
                    .isAccountNonExpired(true)
                    .isAccountNonLocked(true)
                    .isCredentialsNonExpired(true)
                    .build();

            siamak = residentRepository.save(siamak);
            moatezLiege = residentRepository.save(moatezLiege);
            farzanehLiege = residentRepository.save(farzanehLiege);
            log.info("3 residents created for Delomid DM Liège");

            // Assigner les résidents aux appartements de Liège
            aptLiege1.setResident(siamak);
            aptLiege2.setResident(moatezLiege);
            aptLiege3.setResident(farzanehLiege);
            apartmentRepository.save(aptLiege1);
            apartmentRepository.save(aptLiege2);
            apartmentRepository.save(aptLiege3);

            // Créer les relations ResidentBuilding pour Liège (Siamak = ADMIN)
            ResidentBuilding rbSiamakLiege = ResidentBuilding.builder()
                    .resident(siamak)
                    .building(buildingLiege)
                    .apartment(aptLiege1)
                    .roleInBuilding(UserRole.BUILDING_ADMIN)
                    .build();

            ResidentBuilding rbMoatezLiege = ResidentBuilding.builder()
                    .resident(moatezLiege)
                    .building(buildingLiege)
                    .apartment(aptLiege2)
                    .roleInBuilding(UserRole.RESIDENT)
                    .build();

            ResidentBuilding rbFarzanehLiege = ResidentBuilding.builder()
                    .resident(farzanehLiege)
                    .building(buildingLiege)
                    .apartment(aptLiege3)
                    .roleInBuilding(UserRole.RESIDENT)
                    .build();

            residentBuildingRepository.save(rbSiamakLiege);
            residentBuildingRepository.save(rbMoatezLiege);
            residentBuildingRepository.save(rbFarzanehLiege);
            log.info("ResidentBuilding relations created for Liège (Siamak = ADMIN)");

            // ==================== BUILDING 2: DELOMID IT BRUXELLES ====================

            Address addressBruxelles = Address.builder()
                    .address("Avenue Louise 100")
                    .codePostal("1050")
                    .ville("Bruxelles")
                    .pays(belgium)
                    .build();

            Building buildingBruxelles = Building.builder()
                    .buildingId("BEL-2024-IT-BRUXELLES")
                    .buildingLabel("Delomid IT Bruxelles")
                    .buildingNumber("100")
                    .yearOfConstruction(2021)
                    .address(addressBruxelles)
                    .build();

            buildingBruxelles = buildingRepository.save(buildingBruxelles);
            log.info("Building 2 created: Delomid IT Bruxelles");

            // Créer 4 appartements pour Bruxelles
            Apartment aptBxl1 = Apartment.builder()
                    .idApartment("BEL-2024-IT-BRUXELLES-A101")
                    .apartmentLabel("Appartement 101")
                    .apartmentNumber("101")
                    .apartmentFloor(1)
                    .livingAreaSurface(new BigDecimal("70.0"))
                    .numberOfRooms(3)
                    .numberOfBedrooms(2)
                    .haveBalconyOrTerrace(true)
                    .isFurnished(false)
                    .building(buildingBruxelles)
                    .build();

            Apartment aptBxl2 = Apartment.builder()
                    .idApartment("BEL-2024-IT-BRUXELLES-A102")
                    .apartmentLabel("Appartement 102")
                    .apartmentNumber("102")
                    .apartmentFloor(1)
                    .livingAreaSurface(new BigDecimal("65.0"))
                    .numberOfRooms(2)
                    .numberOfBedrooms(1)
                    .haveBalconyOrTerrace(false)
                    .isFurnished(true)
                    .building(buildingBruxelles)
                    .build();

            Apartment aptBxl3 = Apartment.builder()
                    .idApartment("BEL-2024-IT-BRUXELLES-A201")
                    .apartmentLabel("Appartement 201")
                    .apartmentNumber("201")
                    .apartmentFloor(2)
                    .livingAreaSurface(new BigDecimal("85.0"))
                    .numberOfRooms(4)
                    .numberOfBedrooms(3)
                    .haveBalconyOrTerrace(true)
                    .isFurnished(false)
                    .building(buildingBruxelles)
                    .build();

            Apartment aptBxl4 = Apartment.builder()
                    .idApartment("BEL-2024-IT-BRUXELLES-A202")
                    .apartmentLabel("Appartement 202")
                    .apartmentNumber("202")
                    .apartmentFloor(2)
                    .livingAreaSurface(new BigDecimal("60.0"))
                    .numberOfRooms(2)
                    .numberOfBedrooms(1)
                    .haveBalconyOrTerrace(true)
                    .isFurnished(true)
                    .building(buildingBruxelles)
                    .build();

            aptBxl1 = apartmentRepository.save(aptBxl1);
            aptBxl2 = apartmentRepository.save(aptBxl2);
            aptBxl3 = apartmentRepository.save(aptBxl3);
            aptBxl4 = apartmentRepository.save(aptBxl4);
            log.info("4 apartments created for Delomid IT Bruxelles");

            // Créer les résidents pour Bruxelles
            Resident amir = Resident.builder()
                    .idUsers(UUID.randomUUID().toString())
                    .fname("Amir")
                    .lname("Miandarbandi")
                    .email("amir.miandarbandi@delomid.com")
                    .password(passwordEncoder.encode("password123"))
                    .phoneNumber("+32470456789")
                    .role(UserRole.RESIDENT)
                    .accountStatus(AccountStatus.ACTIVE)
                    .isEnabled(true)
                    .isAccountNonExpired(true)
                    .isAccountNonLocked(true)
                    .isCredentialsNonExpired(true)
                    .build();

            Resident somayyeh = Resident.builder()
                    .idUsers(UUID.randomUUID().toString())
                    .fname("Somayyeh")
                    .lname("Gholami")
                    .email("somayyeh.gholami@delomid.com")
                    .password(passwordEncoder.encode("password123"))
                    .phoneNumber("+32470567890")
                    .role(UserRole.RESIDENT)
                    .accountStatus(AccountStatus.ACTIVE)
                    .isEnabled(true)
                    .isAccountNonExpired(true)
                    .isAccountNonLocked(true)
                    .isCredentialsNonExpired(true)
                    .build();

            amir = residentRepository.save(amir);
            somayyeh = residentRepository.save(somayyeh);
            log.info("5 residents created/reused for Delomid IT Bruxelles");

            // Assigner les résidents aux appartements de Bruxelles
            aptBxl1.setResident(amir);
            aptBxl2.setResident(moatezLiege);
            aptBxl3.setResident(siamak);
            aptBxl4.setResident(somayyeh);
            apartmentRepository.save(aptBxl1);
            apartmentRepository.save(aptBxl2);
            apartmentRepository.save(aptBxl3);
            apartmentRepository.save(aptBxl4);

            // Créer les relations ResidentBuilding pour Bruxelles (Amir = ADMIN)
            ResidentBuilding rbAmirBxl = ResidentBuilding.builder()
                    .resident(amir)
                    .building(buildingBruxelles)
                    .apartment(aptBxl1)
                    .roleInBuilding(UserRole.BUILDING_ADMIN)
                    .build();

            ResidentBuilding rbMoatezBxl = ResidentBuilding.builder()
                    .resident(moatezLiege)
                    .building(buildingBruxelles)
                    .apartment(aptBxl2)
                    .roleInBuilding(UserRole.RESIDENT)
                    .build();

            ResidentBuilding rbSiamakBxl = ResidentBuilding.builder()
                    .resident(siamak)
                    .building(buildingBruxelles)
                    .apartment(aptBxl3)
                    .roleInBuilding(UserRole.RESIDENT)
                    .build();

            ResidentBuilding rbSomayyehBxl = ResidentBuilding.builder()
                    .resident(somayyeh)
                    .building(buildingBruxelles)
                    .apartment(aptBxl4)
                    .roleInBuilding(UserRole.RESIDENT)
                    .build();

            ResidentBuilding rbFarzanehBxl = ResidentBuilding.builder()
                    .resident(farzanehLiege)
                    .building(buildingBruxelles)
                    .roleInBuilding(UserRole.RESIDENT)
                    .build();

            residentBuildingRepository.save(rbAmirBxl);
            residentBuildingRepository.save(rbMoatezBxl);
            residentBuildingRepository.save(rbSiamakBxl);
            residentBuildingRepository.save(rbSomayyehBxl);
            residentBuildingRepository.save(rbFarzanehBxl);
            log.info("ResidentBuilding relations created for Bruxelles (Amir = ADMIN)");

            log.info("==================== INITIALIZATION COMPLETE ====================");
            log.info("Building 1: Delomid DM Liège - 3 apartments, 3 residents (Siamak = ADMIN)");
            log.info("Building 2: Delomid IT Bruxelles - 4 apartments, 5 residents (Amir = ADMIN)");
        }
    }
}