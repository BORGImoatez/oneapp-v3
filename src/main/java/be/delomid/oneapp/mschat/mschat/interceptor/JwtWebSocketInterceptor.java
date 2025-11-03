package be.delomid.oneapp.mschat.mschat.interceptor;

import be.delomid.oneapp.mschat.mschat.config.JwtConfig;
import lombok.Getter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.stereotype.Component;

import java.security.Principal;
import java.util.List;

@Slf4j
@Component
public class JwtWebSocketInterceptor implements ChannelInterceptor {

    @Autowired
    private JwtConfig jwtConfig;

    @Override
    public Message<?> preSend(Message<?> message, MessageChannel channel) {
        StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);

        if (StompCommand.CONNECT.equals(accessor.getCommand())) {
            List<String> authorization = accessor.getNativeHeader("Authorization");

            if (authorization != null && !authorization.isEmpty()) {
                String token = authorization.get(0);
                if (token.startsWith("Bearer ")) {
                    token = token.substring(7);
                }

                try {
                    String email = jwtConfig.extractUsername(token);
                    String userId = jwtConfig.extractUserId(token);
                    String buildingId = jwtConfig.extractBuildingId(token);

                    if (jwtConfig.validateToken(token, email)) {
                        String principalName = userId != null ? userId : email;
                        accessor.setUser(new JwtPrincipal(principalName, email, buildingId));
                        log.info("WebSocket connection authenticated - Principal name (userId): {} | Email: {} | Building: {}", principalName, email, buildingId);
                    } else {
                        log.error("Invalid JWT token for WebSocket connection");
                        return null;
                    }

                } catch (Exception e) {
                    log.error("JWT validation failed: {}", e.getMessage());
                    return null; // Reject the connection
                }
            } else {
                log.error("No Authorization header found in WebSocket connection");
                return null; // Reject the connection
            }
        }

        return message;
    }

    public static class JwtPrincipal implements Principal {
        private final String name;
        @Getter
        private final String email;
        @Getter
        private final String buildingId;

        public JwtPrincipal(String name, String email) {
            this(name, email, null);
        }

        public JwtPrincipal(String name, String email, String buildingId) {
            this.name = name;
            this.email = email;
            this.buildingId = buildingId;
        }

        @Override
        public String getName() {
            return name;
        }

    }
}