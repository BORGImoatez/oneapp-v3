package be.delomid.oneapp.mschat.mschat.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class RegisterRequest {
    
    @NotBlank(message = "First name is required")
    private String fname;
    
    @NotBlank(message = "Last name is required")
    private String lname;
    
    @Email(message = "Valid email is required")
    @NotBlank(message = "Email is required")
    private String email;
    
    @NotBlank(message = "Password is required")
    @Size(min = 8, message = "Password must be at least 8 characters")
    private String password;
    
    private String phoneNumber;
    private String picture;
    
    // Informations pour demande d'appartement
    private String requestedBuildingId;
    private String requestedApartmentId;
}