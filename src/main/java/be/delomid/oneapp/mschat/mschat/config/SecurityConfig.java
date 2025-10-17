package be.delomid.oneapp.mschat.mschat.config;

import be.delomid.oneapp.mschat.mschat.service.CustomUserDetailsService;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableGlobalMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

@Configuration
@EnableWebSecurity
@EnableGlobalMethodSecurity(prePostEnabled = true)
@RequiredArgsConstructor
public class SecurityConfig {

    private final CustomUserDetailsService userDetailsService;
    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final AppConfig appConfig;

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                .csrf(AbstractHttpConfigurer::disable)
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(authz -> authz
                        // Swagger UI endpoints
                        .requestMatchers(
                                "/swagger-ui.html",
                                "/swagger-ui/**",
                                "/v3/api-docs/**",
                                "/swagger-resources/**",
                                "/webjars/**"
                        ).permitAll()
                        // Auth endpoints
                        .requestMatchers("/auth/**").permitAll()
                        // WebSocket endpoints
                        .requestMatchers("/ws/**").permitAll() // WebSocket handled by custom interceptor
                        // Actuator endpoints
                        .requestMatchers("/actuator/**").permitAll()
                        // Info endpoints
                        .requestMatchers("/info/**").permitAll()
                        // File endpoints - allow public access for images
                        .requestMatchers("/files/**").permitAll()
                        // Public channels
                        .requestMatchers("/channels/public/**").permitAll()
                        .requestMatchers("/api/v1/channels/public/**").permitAll()
                        // Admin endpoints
                        .requestMatchers("/admin/**").hasAnyRole("BUILDING_ADMIN", "GROUP_ADMIN", "SUPER_ADMIN")
                        // Building, apartment, resident endpoints
                        .requestMatchers("/buildings/**", "/apartments/**", "/residents/**").hasAnyRole("RESIDENT", "BUILDING_ADMIN", "GROUP_ADMIN", "SUPER_ADMIN")
                        // All other requests require authentication
                        .anyRequest().authenticated()
                )
                .authenticationProvider(authenticationProvider())
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    @Bean
    public DaoAuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider authProvider = new DaoAuthenticationProvider();
        authProvider.setUserDetailsService(userDetailsService);
        authProvider.setPasswordEncoder(passwordEncoder());
        return authProvider;
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();

        // Utiliser la configuration depuis application.properties
        if (appConfig.getSecurity().getCors().getAllowedOrigins() != null) {
            configuration.setAllowedOrigins(List.of(appConfig.getSecurity().getCors().getAllowedOrigins()));
        } else {
            configuration.setAllowedOriginPatterns(List.of("*"));
        }

        if (appConfig.getSecurity().getCors().getAllowedMethods() != null) {
            configuration.setAllowedMethods(List.of(appConfig.getSecurity().getCors().getAllowedMethods()));
        } else {
            configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        }

        if (appConfig.getSecurity().getCors().getAllowedHeaders() != null) {
            configuration.setAllowedHeaders(List.of(appConfig.getSecurity().getCors().getAllowedHeaders()));
        } else {
            configuration.setAllowedHeaders(List.of("*"));
        }

        configuration.setAllowCredentials(appConfig.getSecurity().getCors().isAllowCredentials());

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
}