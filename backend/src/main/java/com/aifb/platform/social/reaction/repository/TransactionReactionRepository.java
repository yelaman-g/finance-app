package com.aifb.platform.social.reaction.repository;

import com.aifb.platform.social.reaction.domain.TransactionReaction;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface TransactionReactionRepository extends JpaRepository<TransactionReaction, UUID> {

    Optional<TransactionReaction> findByTransactionIdAndUserId(UUID transactionId, UUID userId);

    List<TransactionReaction> findByTransactionIdIn(List<UUID> transactionIds);

    void deleteByTransactionIdAndUserId(UUID transactionId, UUID userId);
}
