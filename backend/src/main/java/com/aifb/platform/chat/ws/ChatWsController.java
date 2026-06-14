package com.aifb.platform.chat.ws;

import com.aifb.platform.chat.api.dto.ChatMessageResponse;
import com.aifb.platform.chat.api.dto.SendMessageRequest;
import com.aifb.platform.chat.service.ChatService;
import com.aifb.platform.common.security.AuthPrincipal;
import jakarta.validation.Valid;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.stereotype.Controller;

import java.security.Principal;
import java.util.UUID;

/**
 * Handles incoming STOMP messages and broadcasts to the household topic.
 *
 * <p>Client sends to: {@code /app/chat.send} (with JSON body {@code {"text":"…"}})
 * <br>Broadcast to: {@code /topic/household.{householdId}}
 */
@Controller
public class ChatWsController {

    private final ChatService chatService;
    private final SimpMessagingTemplate messagingTemplate;

    public ChatWsController(ChatService chatService, SimpMessagingTemplate messagingTemplate) {
        this.chatService = chatService;
        this.messagingTemplate = messagingTemplate;
    }

    @MessageMapping("/chat.send")
    public void send(@Valid SendMessageRequest request, Principal principal) {
        UUID senderId = extractUserId(principal);
        ChatMessageResponse response = chatService.send(senderId, request.text());
        String destination = "/topic/household." + response.householdId();
        messagingTemplate.convertAndSend(destination, response);
    }

    private UUID extractUserId(Principal principal) {
        if (principal instanceof UsernamePasswordAuthenticationToken token
                && token.getPrincipal() instanceof AuthPrincipal authPrincipal) {
            return authPrincipal.userId();
        }
        throw new IllegalStateException("Unexpected principal type: " + principal);
    }
}
