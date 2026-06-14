package com.aifb.platform.social.poll.repository;

import com.aifb.platform.social.poll.domain.PollVote;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface PollVoteRepository extends JpaRepository<PollVote, UUID> {

    List<PollVote> findByPollIdIn(Collection<UUID> pollIds);

    Optional<PollVote> findByPollIdAndUserId(UUID pollId, UUID userId);

    long countByOptionId(UUID optionId);
}
