package com.aifb.platform.social.poll.repository;

import com.aifb.platform.social.poll.domain.PollOption;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.UUID;

public interface PollOptionRepository extends JpaRepository<PollOption, UUID> {

    List<PollOption> findByPollIdOrderByPosition(UUID pollId);

    List<PollOption> findByPollIdIn(Collection<UUID> pollIds);
}
