package com.aifb.platform.chat.api;

import com.aifb.platform.chat.api.dto.ChatMessageResponse;
import com.aifb.platform.chat.service.ChatService;
import com.aifb.platform.common.api.ApiResponse;
import com.aifb.platform.common.security.AuthPrincipal;
import com.aifb.platform.common.security.CurrentUser;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * REST endpoint for chat history.
 * Real-time messaging is handled via WebSocket/STOMP in {@link ChatWsController}.
 */
@RestController
@RequestMapping("/api/v1/chat")
public class ChatController {

    private final ChatService chatService;

    public ChatController(ChatService chatService) {
        this.chatService = chatService;
    }

    @GetMapping
    public ApiResponse<List<ChatMessageResponse>> history(@CurrentUser AuthPrincipal principal) {
        return ApiResponse.ok(chatService.history(principal.userId()));
    }
}
