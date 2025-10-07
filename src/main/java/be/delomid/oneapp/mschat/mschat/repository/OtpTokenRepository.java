package be.delomid.oneapp.mschat.mschat.repository;

import be.delomid.oneapp.mschat.mschat.model.OtpToken;
import be.delomid.oneapp.mschat.mschat.model.OtpType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.Optional;

@Repository
public interface OtpTokenRepository extends JpaRepository<OtpToken, Long> {
    
    @Query("SELECT o FROM OtpToken o WHERE o.email = :email AND o.otpCode = :otpCode AND o.otpType = :otpType AND o.isUsed = false AND o.expiresAt > :now")
    Optional<OtpToken> findValidOtp(@Param("email") String email, 
                                   @Param("otpCode") String otpCode, 
                                   @Param("otpType") OtpType otpType,
                                   @Param("now") LocalDateTime now);
    
    void deleteByEmailAndOtpType(String email, OtpType otpType);
    
    void deleteByExpiresAtBefore(LocalDateTime dateTime);
}