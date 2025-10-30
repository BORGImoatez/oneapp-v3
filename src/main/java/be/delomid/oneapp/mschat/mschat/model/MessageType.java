package be.delomid.oneapp.mschat.mschat.model;

public enum MessageType {
    TEXT,       // Message texte simple
    IMAGE,      // Image
    FILE,       // Fichier
    AUDIO,      // Message vocal/audio
    VIDEO,      // Fichier vidéo
    SYSTEM,     // Message système (utilisateur rejoint, quitte, etc.)
    CALL        // Message d'appel (manqué, réussi, etc.)
}