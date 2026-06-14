package com.aifb.platform.chat.config;

import com.aifb.platform.common.exception.UnauthorizedException;
import com.aifb.platform.common.security.AuthPrincipal;
import com.aifb.platform.common.security.jwt.JwtService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.simp.config.ChannelRegistration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

import java.util.List;

/**
 * STOMP/WebSocket broker configuration.
 *
 * <p>Security: JWT authentication is enforced at STOMP CONNECT time
 * via a ChannelInterceptor. The HTTP handshake endpoint (/ws/**) is
 * added to SecurityConfig's PUBLIC_ENDPOINTS so the servlet filter
 * does not block the upgrade; the interceptor below does the real auth.
 *
 * <p>Topics:
 * <ul>
 *   <li>{@code /topic/household.{householdId}} — broadcast to all household members</li>
 * </ul>
 *
 * <p>App destinations: {@code /app/chat.send}
 */
@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    private static final Logger log = LoggerFactory.getLogger(WebSocketConfig.class);

    private final JwtService jwtService;

    public WebSocketConfig(JwtService jwtService) {
        this.jwtService = jwtService;
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        // SockJS-capable endpoint (for browser clients)
        registry.addEndpoint("/ws")
                .setAllowedOriginPatterns("*")
                .withSockJS();

        // Raw WebSocket endpoint (for native WS clients / mobile / tests)
        registry.addEndpoint("/ws")
                .setAllowedOriginPatterns("*");
    }

    @Override
    public void configureMessageBroker(MessageBrokerRegistry registry) {
        registry.enableSimpleBroker("/topic");
        registry.setApplicationDestinationPrefixes("/app");
    }

    /**
     * Validates JWT on STOMP CONNECT frames and sets the authenticated principal
     * on the STOMP session so {@code @MessageMapping} methods can access it.
     */
    @Override
    public void configureClientInboundChannel(ChannelRegistration registration) {
        registration.interceptors(new ChannelInterceptor() {
            @Override
            public Message<?> preSend(Message<?> message, MessageChannel channel) {
                StompHeaderAccessor accessor =
                        MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);

                if (accessor != null && StompCommand.CONNECT.equals(accessor.getCommand())) {
                    String authHeader = accessor.getFirstNativeHeader("Authorization");
                    if (authHeader == null || !authHeader.startsWith("Bearer ")) {
                        throw new UnauthorizedException(
                                com.aifb.platform.common.exception.ErrorCode.UNAUTHORIZED,
                                "Missing Authorization header on STOMP CONNECT");
                    }
                    String token = authHeader.substring("Bearer ".length()).trim();
                    // JwtService.verify() validates signature, expiry and issuer
                    AuthPrincipal principal = jwtService.verify(token);

                    var authorities = principal.roles().stream()
                            .map(r -> new SimpleGrantedAuthority("ROLE_" + r))
                            .toList();
                    var authentication = new UsernamePasswordAuthenticationToken(
                            principal, null, authorities);
                    // Sets Principal on the STOMP session — accessible in @MessageMapping
                    accessor.setUser(authentication);
                    log.debug("STOMP CONNECT authenticated userId={}", principal.userId());
                }
                return message;
            }
        });
    }
}
