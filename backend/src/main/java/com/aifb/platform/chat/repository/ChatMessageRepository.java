package com.aifb.platform.chat.repository;

import com.aifb.platform.chat.domain.ChatMessage;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface ChatMessageRepository extends JpaRepository<ChatMessage, UUID> {

    /**
     * Returns up to 100 most-recent messages for a household, ordered newest-first.
     * The service layer reverses this to return oldest-first to callers.
     */
    List<ChatMessage> findTop100ByHouseholdIdOrderByCreatedAtDesc(UUID householdId);
}
