package be.delomid.oneapp.mschat.mschat.model;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "addresses")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(exclude = {"pays"})
@ToString(exclude = {"pays"})
public class Address {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_address")
    private Long idAddress;

    @Column(name = "address", nullable = false)
    private String address;

    @Column(name = "address_suite")
    private String addressSuite;

    @Column(name = "code_postal", nullable = false)
    private String codePostal;

    @Column(name = "ville", nullable = false)
    private String ville;

    @Column(name = "etat_dep")
    private String etatDep;

    @ManyToOne(fetch = FetchType.LAZY)
    private Country pays;

    @Column(name = "observation", columnDefinition = "TEXT")
    private String observation;
}