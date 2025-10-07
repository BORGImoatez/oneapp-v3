package be.delomid.oneapp.mschat.mschat.model;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import lombok.*;

import java.util.List;

@Entity
@Table(name = "countries")
@Data
@NoArgsConstructor
@AllArgsConstructor
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
@EqualsAndHashCode(exclude = {"addressList"})
@ToString(exclude = {"addressList"})
public class Country {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank(message = "Le nom du pays est obligatoire")
    @Column(nullable = false, unique = true)
    private String nom;

    @NotBlank(message = "Le code ISO2 est obligatoire")
    @Column(name = "code_iso2", nullable = false, unique = true, length = 2)
    private String codeIso2;

    @NotBlank(message = "Le code ISO3 est obligatoire")
    @Column(name = "code_iso3", nullable = false, unique = true, length = 3)
    private String codeIso3;
    @OneToMany(mappedBy = "pays", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<Address> addressList;
}