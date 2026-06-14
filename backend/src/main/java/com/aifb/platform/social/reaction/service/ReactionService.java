package com.aifb.platform.social.reaction.service;

import com.aifb.platform.common.exception.ForbiddenException;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.finance.transaction.domain.Transaction;
import com.aifb.platform.finance.transaction.repository.TransactionRepository;
import com.aifb.platform.household.service.HouseholdContextService;
import com.aifb.platform.social.reaction.api.dto.ReactionResponse;
import com.aifb.platform.social.reaction.domain.TransactionReaction;
import com.aifb.platform.social.reaction.repository.TransactionReactionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class ReactionService {

    private final TransactionRepository transactionRepository;
    private final TransactionReactionRepository reactionRepository;
    private final HouseholdContextService householdContextService;

    public ReactionService(TransactionRepository transactionRepository,
                           TransactionReactionRepository reactionRepository,
                           HouseholdContextService householdContextService) {
        this.transactionRepository = transactionRepository;
        this.reactionRepository = reactionRepository;
        this.householdContextService = householdContextService;
    }

    @Transactional
    public void react(UUID userId, UUID transactionId, String emoji) {
        Transaction tx = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new NotFoundException("Транзакция не найдена"));

        if (!tx.isShared()) {
            throw new ForbiddenException("Реакции доступны только для семейных транзакций");
        }

        HouseholdContextService.HouseholdContext ctx = householdContextService.membershipOrNull(userId);
        if (ctx == null || !ctx.householdId().equals(tx.getHouseholdId())) {
            throw new ForbiddenException("Вы не состоите в семье этой транзакции");
        }

        // throws ForbiddenException for GUEST
        householdContextService.requireContribute(userId);

        reactionRepository.findByTransactionIdAndUserId(transactionId, userId)
                .ifPresentOrElse(
                        existing -> existing.setEmoji(emoji),
                        () -> reactionRepository.save(new TransactionReaction(transactionId, userId, emoji))
                );
    }

    @Transactional
    public void removeReaction(UUID userId, UUID transactionId) {
        reactionRepository.deleteByTransactionIdAndUserId(transactionId, userId);
    }

    @Transactional(readOnly = true)
    public Map<UUID, List<ReactionResponse>> reactionsByTransaction(UUID userId,
                                                                     List<UUID> transactionIds) {
        return reactionRepository.findByTransactionIdIn(transactionIds)
                .stream()
                .collect(Collectors.groupingBy(
                        TransactionReaction::getTransactionId,
                        Collectors.mapping(ReactionResponse::from, Collectors.toList())
                ));
    }
}
