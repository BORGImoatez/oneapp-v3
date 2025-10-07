package be.delomid.oneapp.mschat.mschat.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class AddressDto {
    private Long idAddress;
    private String address;
    private String addressSuite;
    private String codePostal;
    private String ville;
    private String etatDep;
    private String pays;
    private String observation;
}