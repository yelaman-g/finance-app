package com.aifb.platform.social.reaction.api.dto;

import com.aifb.platform.social.reaction.domain.TransactionReaction;

import java.util.UUID;

public record ReactionResponse(UUID userId, String emoji) {

    public static ReactionResponse from(TransactionReaction reaction) {
        return new ReactionResponse(reaction.getUserId(), reaction.getEmoji());
    }
}
