package com.aifb.platform.chat.service;

import com.aifb.platform.auth.domain.User;
import com.aifb.platform.auth.repository.UserRepository;
import com.aifb.platform.chat.api.dto.ChatMessageResponse;
import com.aifb.platform.chat.domain.ChatMessage;
import com.aifb.platform.chat.repository.ChatMessageRepository;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.household.service.HouseholdContextService;
import com.aifb.platform.household.service.HouseholdContextService.HouseholdContext;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class ChatService {

    private final ChatMessageRepository chatMessageRepository;
    private final HouseholdContextService householdContext;
    private final UserRepository userRepository;

    public ChatService(ChatMessageRepository chatMessageRepository,
                       HouseholdContextService householdContext,
                       UserRepository userRepository) {
        this.chatMessageRepository = chatMessageRepository;
        this.householdContext = householdContext;
        this.userRepository = userRepository;
    }

    /**
     * Returns up to 100 messages for the caller's household, oldest-first.
     * Returns empty list if the user is not in a household.
     */
    @Transactional(readOnly = true)
    public List<ChatMessageResponse> history(UUID userId) {
        HouseholdContext ctx = householdContext.membershipOrNull(userId);
        if (ctx == null) {
            return List.of();
        }
        List<ChatMessage> messages =
                chatMessageRepository.findTop100ByHouseholdIdOrderByCreatedAtDesc(ctx.householdId());

        // Build sender name lookup
        Map<UUID, String> nameById = buildNameMap(ctx.householdId());

        // Reverse to oldest-first
        List<ChatMessage> ordered = new ArrayList<>(messages);
        Collections.reverse(ordered);

        return ordered.stream()
                .map(m -> toResponse(m, nameById))
                .toList();
    }

    /**
     * Persists a new message and returns the response (including householdId for WS routing).
     * Throws ForbiddenException if the sender is a GUEST.
     */
    @Transactional
    public ChatMessageResponse send(UUID senderId, String text) {
        // requireContribute throws ForbiddenException for GUESTs
        HouseholdContext ctx = householdContext.requireContribute(senderId);

        ChatMessage message = new ChatMessage(ctx.householdId(), senderId, text);
        ChatMessage saved = chatMessageRepository.save(message);

        String senderName = userRepository.findById(senderId)
                .map(User::getFullName)
                .orElse("Unknown");

        return new ChatMessageResponse(
                saved.getId(),
                saved.getHouseholdId(),
                saved.getSenderId(),
                senderName,
                saved.getText(),
                saved.getCreatedAt());
    }

    // ─── private helpers ────────────────────────────────────────────────────

    private Map<UUID, String> buildNameMap(UUID householdId) {
        return userRepository.findByHouseholdId(householdId)
                .stream()
                .collect(Collectors.toMap(User::getId, User::getFullName));
    }

    private ChatMessageResponse toResponse(ChatMessage m, Map<UUID, String> nameById) {
        return new ChatMessageResponse(
                m.getId(),
                m.getHouseholdId(),
                m.getSenderId(),
                nameById.getOrDefault(m.getSenderId(), "Unknown"),
                m.getText(),
                m.getCreatedAt());
    }
}
