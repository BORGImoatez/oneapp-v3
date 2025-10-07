package be.delomid.oneapp.mschat.mschat.service;

import be.delomid.oneapp.mschat.mschat.model.OtpToken;
import be.delomid.oneapp.mschat.mschat.model.OtpType;
import be.delomid.oneapp.mschat.mschat.repository.OtpTokenRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
public class OtpService {
    
    private final OtpTokenRepository otpTokenRepository;
    private final EmailService emailService;
    private final SecureRandom random = new SecureRandom();
    
    @Transactional
    public void generateAndSendOtp(String email, OtpType otpType) {
        // Supprimer les anciens OTP pour cet email et ce type
        otpTokenRepository.deleteByEmailAndOtpType(email, otpType);
        
        // Générer un nouveau code OTP
        String otpCode = generateOtpCode();
        
        // Créer et sauvegarder le token OTP
        OtpToken otpToken = OtpToken.builder()
                .email(email)
                .otpCode(otpCode)
                .otpType(otpType)
                .expiresAt(LocalDateTime.now().plusMinutes(10)) // Expire dans 10 minutes
                .build();
        
        otpTokenRepository.save(otpToken);
        
        // Envoyer l'email
        String purpose = switch (otpType) {
            case LOGIN -> "la connexion";
            case REGISTRATION -> "l'inscription";
            case PASSWORD_RESET -> "la réinitialisation du mot de passe";
        };
        
        emailService.sendOtpEmail(email, otpCode, purpose);
        log.debug("OTP generated and sent for email: {} and type: {}", email, otpType);
    }
    
    @Transactional
    public boolean verifyOtp(String email, String otpCode, OtpType otpType) {
        Optional<OtpToken> otpToken = otpTokenRepository.findValidOtp(
                email, otpCode, otpType, LocalDateTime.now()
        );
        
        if (otpToken.isPresent()) {
            // Marquer l'OTP comme utilisé
            otpToken.get().setIsUsed(true);
            otpTokenRepository.save(otpToken.get());
            
            log.debug("OTP verified successfully for email: {}", email);
            return true;
        }
        
        log.debug("OTP verification failed for email: {}", email);
        return false;
    }
    
    private String generateOtpCode() {
        return String.format("%06d", random.nextInt(1000000));
    }
    
    // Nettoyer les OTP expirés toutes les heures
    @Scheduled(fixedRate = 3600000)
    @Transactional
    public void cleanupExpiredOtps() {
        otpTokenRepository.deleteByExpiresAtBefore(LocalDateTime.now());
        log.debug("Expired OTPs cleaned up");
    }
}