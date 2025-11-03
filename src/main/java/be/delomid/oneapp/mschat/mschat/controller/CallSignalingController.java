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

            messagingTemplate.convertAndSendToUser(
                    to,
                    "/queue/signal",
                    Map.of(
                            "type", type,
                            "data", data
                    )
            );
        } catch (Exception e) {
            log.error("Error handling signaling message", e);
        }
    }
}
