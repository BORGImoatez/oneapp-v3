package be.delomid.oneapp.mschat.mschat.controller;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/webrtc")
@RequiredArgsConstructor
public class TurnCredentialsController {

    // ⚠️ DOIT CORRESPONDRE EXACTEMENT à votre turnserver.conf
    private static final String TURN_SECRET = "SuperSecret1234567890abcdef1234567890abcdef";
    private static final String TURN_DOMAIN = "51.91.99.191";
    private static final int TTL = 86400; // 24h (plus stable que 1h)

    @GetMapping("/turn-credentials")
    public ResponseEntity<Map<String, Object>> getTurnCredentials(
            @AuthenticationPrincipal UserDetails userDetails) {

        // Générer le username au format COTURN: timestamp:userid
        String username = generateUsername(
                userDetails != null ? userDetails.getUsername() : "anonymous"
        );

        // Générer le password avec HMAC-SHA1
        String password = generatePassword(username);

        log.info("Generated TURN credentials - Username: {}", username);

        Map<String, Object> response = new HashMap<>();
        response.put("username", username);
        response.put("password", password);
        response.put("ttl", TTL);
        response.put("uris", List.of(
                "turn:" + TURN_DOMAIN + ":3478?transport=udp",
                "turn:" + TURN_DOMAIN + ":3478?transport=tcp",
                "stun:" + TURN_DOMAIN + ":3478"
        ));

        return ResponseEntity.ok(response);
    }

    /**
     * Format COTURN : timestamp:userid
     * Exemple: 1762954199:user123
     */
    private String generateUsername(String userId) {
        long expiry = System.currentTimeMillis() / 1000 + TTL;

        // Nettoyer le userId pour éviter les caractères spéciaux
        String cleanUserId = userId.replaceAll("[^a-zA-Z0-9_-]", "_");

        return expiry + ":" + cleanUserId;
    }

    /**
     * Génère le password avec HMAC-SHA1
     * Le secret DOIT être identique à static-auth-secret dans turnserver.conf
     */
    private String generatePassword(String username) {
        try {
            Mac mac = Mac.getInstance("HmacSHA1");
            SecretKeySpec keySpec = new SecretKeySpec(
                    TURN_SECRET.getBytes(StandardCharsets.UTF_8),
                    "HmacSHA1"
            );
            mac.init(keySpec);

            byte[] result = mac.doFinal(username.getBytes(StandardCharsets.UTF_8));
            String password = Base64.getEncoder().encodeToString(result);

            log.debug("HMAC computed for username: {}", username);

            return password;
        } catch (Exception e) {
            log.error("Failed to generate TURN password", e);
            throw new RuntimeException("Failed to generate TURN password", e);
        }
    }
}