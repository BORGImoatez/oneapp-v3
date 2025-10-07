package be.delomid.oneapp.mschat.mschat.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;
import lombok.Data;

@Configuration
@ConfigurationProperties(prefix = "app")
@Data
public class AppConfig {

    private String name;
    private String version;
    private String description;
    private Otp otp = new Otp();
    private Admin admin = new Admin();
    private Security security = new Security();

    @Data
    public static class Otp {
        private int expirationMinutes = 10;
        private int maxAttempts = 3;
    }

    @Data
    public static class Admin {
        private String defaultSuperAdminEmail;
        private String defaultSuperAdminPassword;
    }

    @Data
    public static class Security {
        private Cors cors = new Cors();
        @Data
        public static class Cors {
            private String[] allowedOrigins;
            private String[] allowedMethods;
            private String[] allowedHeaders;
            private boolean allowCredentials = true;
        }
    }
}