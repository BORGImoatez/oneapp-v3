package be.delomid.oneapp.mschat.mschat.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AddResidentToApartmentRequest {

    @NotBlank(message = "Le prénom est obligatoire")
    private String fname;

    @NotBlank(message = "Le nom est obligatoire")
    private String lname;

    @NotBlank(message = "L'email est obligatoire")
    @Email(message = "Format d'email invalide")
    private String email;

    private String phoneNumber;

    @NotBlank(message = "L'ID de l'appartement est obligatoire")
    private String apartmentId;
}
