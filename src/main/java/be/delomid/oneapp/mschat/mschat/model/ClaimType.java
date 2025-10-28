package be.delomid.oneapp.mschat.mschat.model;

public enum ClaimType {
    INCENDIE("Incendie"),
    VOL("Vol"),
    DEGATS_DES_EAUX("Dégâts des eaux"),
    DEGAT_NATUREL("Dégât naturel (orage, ...)"),
    CONTAMINATION("Contamination (champignons, nuisibles)"),
    BRIS_DE_PORTES("Bris de porte(s)"),
    BRIS_DE_VITRES("Bris de vitre(s)"),
    AUTRE("Autre");

    private final String displayName;

    ClaimType(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
