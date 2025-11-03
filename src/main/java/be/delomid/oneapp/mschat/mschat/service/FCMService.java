package be.delomid.oneapp.mschat.mschat.service;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
@Slf4j
public class FCMService {

    @Value("${firebase.config.path:#{null}}")
    private String firebaseConfigPath;

    @PostConstruct
    public void initialize() {
        try {
            if (firebaseConfigPath != null && !firebaseConfigPath.isEmpty()) {
                InputStream serviceAccount;

                // Essayer d'abord comme ressource du classpath
                try {
                    ClassPathResource resource = new ClassPathResource(firebaseConfigPath);
                    serviceAccount = resource.getInputStream();
                    log.info("Loaded Firebase config from classpath: {}", firebaseConfigPath);
                } catch (Exception e) {
                    // Sinon, essayer comme chemin de fichier absolu
                    serviceAccount = new FileInputStream(firebaseConfigPath);
                    log.info("Loaded Firebase config from file system: {}", firebaseConfigPath);
                }

                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                        .build();

                if (FirebaseApp.getApps().isEmpty()) {
                    FirebaseApp.initializeApp(options);
                    log.info("Firebase initialized successfully");
                }

                serviceAccount.close();
            } else {
                log.warn("Firebase config path not set. Push notifications will not work.");
            }
        } catch (IOException e) {
            log.error("Error initializing Firebase: {}", e.getMessage(), e);
        }
    }

    public void sendNotificationToToken(String fcmToken, String title, String body, String channelId) {
        sendPushNotification(fcmToken, title, body, "CHANNEL_CREATED", channelId);
    }

    public void sendPushNotification(String fcmToken, String title, String body, String type, String channelId) {
        if (fcmToken == null || fcmToken.isEmpty()) {
            log.warn("FCM token is empty, skipping notification");
            return;
        }

        try {
            Message.Builder messageBuilder = Message.builder()
                    .setToken(fcmToken)
                    .setNotification(Notification.builder()
                            .setTitle(title)
                            .setBody(body)
                            .build())
                    .putData("type", type != null ? type : "MESSAGE")
                    .setAndroidConfig(AndroidConfig.builder()
                            .setPriority(AndroidConfig.Priority.HIGH)
                            .setNotification(AndroidNotification.builder()
                                    .setSound("default")
                                    .setChannelId("high_importance_channel")
                                    .build())
                            .build())
                    .setApnsConfig(ApnsConfig.builder()
                            .setAps(Aps.builder()
                                    .setSound("default")
                                    .setBadge(1)
                                    .build())
                            .build());

            if (channelId != null) {
                messageBuilder.putData("channelId", channelId);
            }

            Message message = messageBuilder.build();
            String response = FirebaseMessaging.getInstance().send(message);
            log.info("Successfully sent push notification: {}", response);
        } catch (Exception e) {
            log.error("Error sending push notification to token {}: {}", fcmToken, e.getMessage());
        }
    }

    public void sendIncomingCallNotification(String fcmToken, String callerId, String callerName, String callerAvatar, Long callId, Long channelId) {
        if (fcmToken == null || fcmToken.isEmpty()) {
            log.warn("FCM token is empty, skipping incoming call notification");
            return;
        }

        try {
            Message message = Message.builder()
                    .setToken(fcmToken)
                    .setNotification(Notification.builder()
                            .setTitle("Appel entrant")
                            .setBody(callerName + " vous appelle")
                            .build())
                    .putData("type", "INCOMING_CALL")
                    .putData("callId", callId.toString())
                    .putData("callerId", callerId)
                    .putData("callerName", callerName)
                    .putData("callerAvatar", callerAvatar != null ? callerAvatar : "")
                    .putData("channelId", channelId.toString())
                    .setAndroidConfig(AndroidConfig.builder()
                            .setPriority(AndroidConfig.Priority.HIGH)
                            .setNotification(AndroidNotification.builder()
                                    .setSound("default")
                                    .setChannelId("incoming_call_channel")
                                    .setPriority(AndroidNotification.Priority.MAX)
                                    .setVisibility(AndroidNotification.Visibility.PUBLIC)
                                    .build())
                            .build())
                    .setApnsConfig(ApnsConfig.builder()
                            .putHeader("apns-priority", "10")
                            .putHeader("apns-push-type", "alert")
                            .setAps(Aps.builder()
                                    .setContentAvailable(true)
                                    .setSound("default")
                                    .setBadge(1)
                                    .build())
                            .build())
                    .build();

            String response = FirebaseMessaging.getInstance().send(message);
            log.info("Successfully sent incoming call notification: {}", response);
        } catch (Exception e) {
            log.error("Error sending incoming call notification to token {}: {}", fcmToken, e.getMessage());
        }
    }

    public void sendNotificationToMultipleTokens(List<String> fcmTokens, String title, String body, String channelId) {
        if (fcmTokens == null || fcmTokens.isEmpty()) {
            log.warn("FCM tokens list is empty, skipping notifications");
            return;
        }

        List<String> validTokens = fcmTokens.stream()
                .filter(token -> token != null && !token.isEmpty())
                .collect(Collectors.toList());

        if (validTokens.isEmpty()) {
            log.warn("No valid FCM tokens found, skipping notifications");
            return;
        }

        if (validTokens.size() > 500) {
            log.warn("Too many tokens ({}), splitting into batches", validTokens.size());
            List<List<String>> batches = partition(validTokens, 500);
            for (List<String> batch : batches) {
                sendBatch(batch, title, body, channelId);
            }
        } else {
            sendBatch(validTokens, title, body, channelId);
        }
    }

    private void sendBatch(List<String> tokens, String title, String body, String channelId) {
        int successCount = 0;
        int failureCount = 0;

        for (String token : tokens) {
            try {
                Message message = Message.builder()
                        .setToken(token)
                        .setNotification(Notification.builder()
                                .setTitle(title)
                                .setBody(body)
                                .build())
                        .putData("channelId", channelId)
                        .putData("type", "CHANNEL_CREATED")
                        .setAndroidConfig(AndroidConfig.builder()
                                .setPriority(AndroidConfig.Priority.HIGH)
                                .setNotification(AndroidNotification.builder()
                                        .setSound("default")
                                        .setChannelId("channel_notifications")
                                        .build())
                                .build())
                        .setApnsConfig(ApnsConfig.builder()
                                .setAps(Aps.builder()
                                        .setSound("default")
                                        .build())
                                .build())
                        .build();

                String response = FirebaseMessaging.getInstance().send(message);
                successCount++;
                log.debug("Successfully sent notification to token: {}", response);
            } catch (Exception e) {
                failureCount++;
                log.error("Failed to send to token {}: {}", token, e.getMessage());
            }
        }

        log.info("Successfully sent {} notifications, failed: {}", successCount, failureCount);
    }

    private <T> List<List<T>> partition(List<T> list, int size) {
        List<List<T>> partitions = new ArrayList<>();
        for (int i = 0; i < list.size(); i += size) {
            partitions.add(list.subList(i, Math.min(i + size, list.size())));
        }
        return partitions;
    }
}
