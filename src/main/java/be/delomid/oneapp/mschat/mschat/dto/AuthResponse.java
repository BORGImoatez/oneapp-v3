package be.delomid.oneapp.mschat.mschat.dto;

import be.delomid.oneapp.mschat.mschat.model.AccountStatus;
import be.delomid.oneapp.mschat.mschat.model.UserRole;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class AuthResponse {
    private String token;
    private String refreshToken;
    private String userId;
    private String email;
    private String fname;
    private String lname;
    private UserRole role;
    private AccountStatus accountStatus;
    private String buildingId;
    private String apartmentId;
    private boolean otpRequired;
    private String message;
}