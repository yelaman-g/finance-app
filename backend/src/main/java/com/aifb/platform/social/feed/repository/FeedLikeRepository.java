package com.aifb.platform.social.feed.repository;

import com.aifb.platform.social.feed.domain.FeedLike;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface FeedLikeRepository extends JpaRepository<FeedLike, UUID> {

    List<FeedLike> findByMomentIdIn(List<UUID> momentIds);

    Optional<FeedLike> findByMomentIdAndUserId(UUID momentId, UUID userId);

    void deleteByMomentIdAndUserId(UUID momentId, UUID userId);

    long countByMomentId(UUID momentId);
}
