package be.delomid.oneapp.mschat.mschat.controller;

import be.delomid.oneapp.mschat.mschat.dto.MessageDto;
import be.delomid.oneapp.mschat.mschat.dto.SendMessageRequest;
import be.delomid.oneapp.mschat.mschat.service.MessageService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessageHeaderAccessor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;

import java.security.Principal;

@Controller
@RequiredArgsConstructor
@Slf4j
public class WebSocketMessageController {

    private final MessageService messageService;
    private final SimpMessagingTemplate messagingTemplate;

    @MessageMapping("/message.send")
    public void sendMessage(@Payload SendMessageRequest request,
                            SimpMessageHeaderAccessor headerAccessor,
                            Principal principal) {

        try {
            // Récupérer l'ID utilisateur du JWT
            String userId = principal.getName();

            // Envoyer le message via le service
            MessageDto message = messageService.sendMessage(request, userId);

            // Diffuser le message à tous les membres du canal
            messagingTemplate.convertAndSend(
                    "/topic/channel/" + request.getChannelId(),
                    message
            );

            log.debug("Message sent via WebSocket: channelId={}, userId={}, type={}",
                    request.getChannelId(), userId, request.getType());

        } catch (Exception e) {
            log.error("Error sending message via WebSocket", e);

            // Envoyer une erreur à l'utilisateur
            messagingTemplate.convertAndSendToUser(
                    principal.getName(),
                    "/queue/errors",
                    "Error sending message: " + e.getMessage()
            );
        }
    }

    @MessageMapping("/message.typing")
    public void handleTyping(@Payload TypingEvent typingEvent, Principal principal) {
        // Diffuser l'événement "en train d'écrire" aux autres membres du canal
        typingEvent.setUserId(principal.getName());

        messagingTemplate.convertAndSend(
                "/topic/channel/" + typingEvent.getChannelId() + "/typing",
                typingEvent
        );
    }

    public static class TypingEvent {
        private Long channelId;
        private String userId;
        private boolean isTyping;

        // Getters and setters
        public Long getChannelId() { return channelId; }
        public void setChannelId(Long channelId) { this.channelId = channelId; }
        public String getUserId() { return userId; }
        public void setUserId(String userId) { this.userId = userId; }
        public boolean isTyping() { return isTyping; }
        public void setTyping(boolean typing) { isTyping = typing; }
    }
}