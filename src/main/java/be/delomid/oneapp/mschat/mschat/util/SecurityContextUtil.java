package be.delomid.oneapp.mschat.mschat.util;

import be.delomid.oneapp.mschat.mschat.interceptor.JwtWebSocketInterceptor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.Map;

@Slf4j
public class SecurityContextUtil {

    public static String getCurrentBuildingId() {
        try {
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            if (authentication != null) {
                // Vérifier si c'est un JwtPrincipal (WebSocket)
                if (authentication.getPrincipal() instanceof JwtWebSocketInterceptor.JwtPrincipal) {
                    JwtWebSocketInterceptor.JwtPrincipal principal = (JwtWebSocketInterceptor.JwtPrincipal) authentication.getPrincipal();
                    String buildingId = principal.getBuildingId();
                    log.debug("Building ID extracted from JwtPrincipal: {}", buildingId);
                    return buildingId;
                }

                // Sinon extraire depuis les details (HTTP)
                Object details = authentication.getDetails();
                log.debug("Authentication details type: {}", details != null ? details.getClass().getName() : "null");

                if (details instanceof Map) {
                    @SuppressWarnings("unchecked")
                    Map<String, Object> detailsMap = (Map<String, Object>) details;
                    log.debug("Details map keys: {}", detailsMap.keySet());

                    Object buildingId = detailsMap.get("buildingId");
                    if (buildingId != null) {
                        log.info("Building ID extracted from authentication details: {}", buildingId);
                        return buildingId.toString();
                    } else {
                        log.warn("buildingId key not found in authentication details");
                    }
                }
            } else {
                log.warn("No authentication found in SecurityContext");
            }
        } catch (Exception e) {
            log.error("Error extracting building ID from security context", e);
        }
        return null;
    }

    public static String getCurrentUserId() {
        try {
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            if (authentication != null) {
                Object details = authentication.getDetails();
                if (details instanceof Map) {
                    @SuppressWarnings("unchecked")
                    Map<String, Object> detailsMap = (Map<String, Object>) details;
                    Object userId = detailsMap.get("userId");
                    if (userId != null) {
                        return userId.toString();
                    }
                }
                return authentication.getName();
            }
        } catch (Exception e) {
            log.error("Error extracting user ID from security context", e);
        }
        return null;
    }

    public static String getCurrentUserRole() {
        try {
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            if (authentication != null) {
                Object details = authentication.getDetails();
                if (details instanceof Map) {
                    @SuppressWarnings("unchecked")
                    Map<String, Object> detailsMap = (Map<String, Object>) details;
                    Object role = detailsMap.get("role");
                    if (role != null) {
                        return role.toString();
                    }
                }
            }
        } catch (Exception e) {
            log.error("Error extracting role from security context", e);
        }
        return null;
    }
}