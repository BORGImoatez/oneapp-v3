package be.delomid.oneapp.mschat.mschat.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "apartment_installations")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ApartmentInstallations {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "apartment_id", nullable = false, unique = true)
    private Long apartmentId;

    private Boolean ascenseur = false;

    @Column(name = "acces_handicap")
    private Boolean accesHandicap = false;

    private Boolean parlophone = false;

    @Column(name = "interphone_video")
    private Boolean interphoneVideo = false;

    @Column(name = "porte_blindee")
    private Boolean porteBlindee = false;

    private Boolean piscine = false;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt = LocalDateTime.now();

    @Column(name = "updated_by")
    private Long updatedBy;
}
