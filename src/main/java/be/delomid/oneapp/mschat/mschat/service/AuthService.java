package be.delomid.oneapp.mschat.mschat.service;

import be.delomid.oneapp.mschat.mschat.config.JwtConfig;
import be.delomid.oneapp.mschat.mschat.dto.*;
import be.delomid.oneapp.mschat.mschat.model.*;
import be.delomid.oneapp.mschat.mschat.repository.ResidentRepository;
import be.delomid.oneapp.mschat.mschat.repository.ResidentBuildingRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuthService {

    private final ResidentRepository residentRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtConfig jwtConfig;
    private final OtpService otpService;
    private final EmailService emailService;
    private final ResidentBuildingRepository residentBuildingRepository;

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        log.debug("Registering new user: {}", request.getEmail());

        // Vérifier si l'email existe déjà
        if (residentRepository.findByEmail(request.getEmail()).isPresent()) {
            throw new IllegalArgumentException("Email already exists");
        }

        // Créer le résident
        Resident resident = Resident.builder()
                .idUsers(UUID.randomUUID().toString())
                .fname(request.getFname())
                .lname(request.getLname())
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .phoneNumber(request.getPhoneNumber())
                .picture(request.getPicture())
                .role(UserRole.RESIDENT)
                .accountStatus(AccountStatus.PENDING)
                .isEnabled(false)
                .build();

        resident = residentRepository.save(resident);

        // Générer et envoyer OTP pour vérification email
        otpService.generateAndSendOtp(request.getEmail(), OtpType.REGISTRATION);

        return AuthResponse.builder()
                .userId(resident.getIdUsers())
                .email(resident.getEmail())
                .fname(resident.getFname())
                .lname(resident.getLname())
                .role(resident.getRole())
                .accountStatus(resident.getAccountStatus())
                .otpRequired(true)
                .message("Compte créé. Veuillez vérifier votre email avec le code OTP envoyé.")
                .build();
    }

    @Transactional
    public AuthResponse verifyRegistration(VerifyOtpRequest request) {
        if (!otpService.verifyOtp(request.getEmail(), request.getOtpCode(), OtpType.REGISTRATION)) {
            throw new IllegalArgumentException("Code OTP invalide ou expiré");
        }

        Resident resident = residentRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new IllegalArgumentException("Utilisateur non trouvé"));

        resident.setIsEnabled(true);
        resident = residentRepository.save(resident);

        return AuthResponse.builder()
                .userId(resident.getIdUsers())
                .email(resident.getEmail())
                .fname(resident.getFname())
                .lname(resident.getLname())
                .role(resident.getRole())
                .accountStatus(resident.getAccountStatus())
                .otpRequired(false)
                .message("Email vérifié. Votre compte est en attente d'approbation par un administrateur.")
                .build();
    }

    public AuthResponse login(LoginRequest request) {
        log.debug("Login attempt for email: {}", request.getEmail());

        Resident resident = residentRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new IllegalArgumentException("Email ou mot de passe incorrect"));

        if (!passwordEncoder.matches(request.getPassword(), resident.getPassword())) {
            throw new IllegalArgumentException("Email ou mot de passe incorrect");
        }

        if (!resident.isEnabled()) {
            throw new IllegalArgumentException("Compte non vérifié. Veuillez vérifier votre email.");
        }

        if (resident.getAccountStatus() == AccountStatus.BLOCKED) {
            throw new IllegalArgumentException("Compte bloqué. Contactez un administrateur.");
        }

        if (resident.getAccountStatus() == AccountStatus.PENDING) {
            throw new IllegalArgumentException("Compte en attente d'approbation.");
        }

        // Générer et envoyer OTP pour la connexion
        otpService.generateAndSendOtp(request.getEmail(), OtpType.LOGIN);

        return AuthResponse.builder()
                .userId(resident.getIdUsers())
                .email(resident.getEmail())
                .fname(resident.getFname())
                .lname(resident.getLname())
                .role(resident.getRole())
                .accountStatus(resident.getAccountStatus())
                .otpRequired(true)
                .message("Code OTP envoyé à votre email pour finaliser la connexion.")
                .build();
    }

    public AuthResponse verifyLogin(VerifyOtpRequest request) {
        if (!otpService.verifyOtp(request.getEmail(), request.getOtpCode(), OtpType.LOGIN)) {
            throw new IllegalArgumentException("Code OTP invalide ou expiré");
        }

        Resident resident = residentRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new IllegalArgumentException("Utilisateur non trouvé"));

        // Vérifier si l'utilisateur a plusieurs bâtiments
        List<ResidentBuilding> userBuildings = residentBuildingRepository.findActiveByResidentId(resident.getIdUsers());

        log.debug("User {} has {} buildings", resident.getEmail(), userBuildings.size());

        // Générer un token temporaire pour permettre l'accès aux endpoints de sélection de bâtiment
        String tempToken = jwtConfig.generateToken(
                resident.getEmail(),
                resident.getIdUsers(),
                resident.getRole().name()
        );

        if (userBuildings.size() > 1) {
            // L'utilisateur a plusieurs bâtiments, il doit choisir
            log.debug("User has multiple buildings, redirecting to building selection");
            return AuthResponse.builder()
                    .token(tempToken) // Token temporaire pour accéder aux endpoints de sélection
                    .userId(resident.getIdUsers())
                    .email(resident.getEmail())
                    .fname(resident.getFname())
                    .lname(resident.getLname())
                    .role(resident.getRole())
                    .accountStatus(resident.getAccountStatus())
                    .otpRequired(false)
                    .message("BUILDING_SELECTION_REQUIRED")
                    .build();
        } else if (userBuildings.size() == 1) {
            // Un seul bâtiment, connexion directe
            ResidentBuilding residentBuilding = userBuildings.get(0);
            return generateTokenForBuilding(resident, residentBuilding);
        } else {
            // Aucun bâtiment assigné, utiliser l'ancien système
            return generateLegacyToken(resident);
        }
    }

    private AuthResponse generateTokenForBuilding(Resident resident, ResidentBuilding residentBuilding) {
        String token = jwtConfig.generateTokenWithBuilding(
                resident.getEmail(),
                resident.getIdUsers(),
                residentBuilding.getRoleInBuilding().name(),
                residentBuilding.getBuilding().getBuildingId()
        );
        String refreshToken = jwtConfig.generateRefreshToken(
                resident.getEmail(),
                resident.getIdUsers()
        );

        String apartmentId = null;
        if (residentBuilding.getApartment() != null) {
            apartmentId = residentBuilding.getApartment().getIdApartment();
        }

        return AuthResponse.builder()
                .token(token)
                .refreshToken(refreshToken)
                .userId(resident.getIdUsers())
                .email(resident.getEmail())
                .fname(resident.getFname())
                .lname(resident.getLname())
                .role(resident.getRole())
                .accountStatus(resident.getAccountStatus())
                .buildingId(residentBuilding.getBuilding().getBuildingId())
                .apartmentId(apartmentId)
                .otpRequired(false)
                .message("Connexion réussie")
                .build();
    }

    private AuthResponse generateLegacyToken(Resident resident) {
        String token = jwtConfig.generateToken(
                resident.getEmail(),
                resident.getIdUsers(),
                resident.getRole().name()
        );
        String refreshToken = jwtConfig.generateRefreshToken(
                resident.getEmail(),
                resident.getIdUsers()
        );

        // Pour les utilisateurs sans ResidentBuilding (legacy), on ne retourne pas de building/apartment
        return AuthResponse.builder()
                .token(token)
                .refreshToken(refreshToken)
                .userId(resident.getIdUsers())
                .email(resident.getEmail())
                .fname(resident.getFname())
                .lname(resident.getLname())
                .role(resident.getRole())
                .accountStatus(resident.getAccountStatus())
                .buildingId(null)
                .apartmentId(null)
                .otpRequired(false)
                .message("Connexion réussie")
                .build();
    }

    public AuthResponse refreshToken(String refreshToken) {
        try {
            String email = jwtConfig.extractUsername(refreshToken);

            if (jwtConfig.validateToken(refreshToken, email)) {
                Resident resident = residentRepository.findByEmail(email)
                        .orElseThrow(() -> new IllegalArgumentException("Utilisateur non trouvé"));

                String newToken = jwtConfig.generateToken(
                        resident.getEmail(),
                        resident.getIdUsers(),
                        resident.getRole().name()
                );

                return AuthResponse.builder()
                        .token(newToken)
                        .refreshToken(refreshToken)
                        .userId(resident.getIdUsers())
                        .email(resident.getEmail())
                        .role(resident.getRole())
                        .accountStatus(resident.getAccountStatus())
                        .message("Token rafraîchi")
                        .build();
            }
        } catch (Exception e) {
            log.error("Error refreshing token", e);
        }

        throw new IllegalArgumentException("Token de rafraîchissement invalide");
    }

    @Transactional
    public void updateFcmToken(UpdateFcmTokenRequest request) {
        String email = jwtConfig.extractUsernameFromCurrentContext();

        Resident resident = residentRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("Utilisateur non trouvé"));

        resident.setFcmToken(request.getFcmToken());
        residentRepository.save(resident);

        log.info("FCM token updated for user: {}", email);
    }
}