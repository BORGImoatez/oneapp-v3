package be.delomid.oneapp.mschat.mschat.controller;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;

import java.util.Map;

@Controller
@Slf4j
public class CallSignalingController {

    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    @MessageMapping("/call.signal")
    public void handleSignaling(Map<String, Object> message) {
        try {
            String type = (String) message.get("type");
            String to = (String) message.get("to");
            Object data = message.get("data");

            log.info("Received signaling message: type={}, to={}", type, to);
            log.info("Sending signal to user: {} at destination: /user/{}/queue/signal", to, to);

            Map<String, Object> signalMessage = Map.of(
                    "type", type,
                    "data", data
            );

            messagingTemplate.convertAndSendToUser(
                    to,
                    "/queue/signal",
                    signalMessage
            );

            log.info("Signal sent successfully to user: {}", to);
        } catch (Exception e) {
            log.error("Error handling signaling message", e);
        }
    }
}
