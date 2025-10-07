package be.delomid.oneapp.mschat.mschat.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class CreateAddressRequest {
    @NotBlank(message = "Address is required")
    private String address;

    private String addressSuite;

    @NotBlank(message = "Code postal is required")
    private String codePostal;

    @NotBlank(message = "Ville is required")
    private String ville;

    private String etatDep;

    @NotBlank(message = "Pays is required")
    private String pays;

    private String observation;
}