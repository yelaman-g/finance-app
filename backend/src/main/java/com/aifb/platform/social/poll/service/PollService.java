package com.aifb.platform.social.poll.service;

import com.aifb.platform.common.exception.DomainException;
import com.aifb.platform.common.exception.ErrorCode;
import com.aifb.platform.common.exception.ForbiddenException;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.household.service.HouseholdContextService;
import com.aifb.platform.household.service.HouseholdContextService.HouseholdContext;
import com.aifb.platform.social.poll.api.dto.CreatePollRequest;
import com.aifb.platform.social.poll.api.dto.PollOptionResult;
import com.aifb.platform.social.poll.api.dto.PollResponse;
import com.aifb.platform.social.poll.api.dto.VoteRequest;
import com.aifb.platform.social.poll.domain.Poll;
import com.aifb.platform.social.poll.domain.PollOption;
import com.aifb.platform.social.poll.domain.PollVote;
import com.aifb.platform.social.poll.repository.PollOptionRepository;
import com.aifb.platform.social.poll.repository.PollRepository;
import com.aifb.platform.social.poll.repository.PollVoteRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class PollService {

    private final PollRepository pollRepository;
    private final PollOptionRepository pollOptionRepository;
    private final PollVoteRepository pollVoteRepository;
    private final HouseholdContextService householdContext;

    public PollService(PollRepository pollRepository,
                       PollOptionRepository pollOptionRepository,
                       PollVoteRepository pollVoteRepository,
                       HouseholdContextService householdContext) {
        this.pollRepository = pollRepository;
        this.pollOptionRepository = pollOptionRepository;
        this.pollVoteRepository = pollVoteRepository;
        this.householdContext = householdContext;
    }

    @Transactional(readOnly = true)
    public List<PollResponse> list(UUID userId) {
        HouseholdContext ctx = householdContext.membershipOrNull(userId);
        if (ctx == null) {
            return List.of();
        }

        List<Poll> polls = pollRepository.findByHouseholdIdOrderByCreatedAtDesc(ctx.householdId());
        if (polls.isEmpty()) {
            return List.of();
        }

        List<UUID> pollIds = polls.stream().map(Poll::getId).toList();

        // Fetch all options for all polls in one query
        List<PollOption> allOptions = pollOptionRepository.findByPollIdIn(pollIds);
        Map<UUID, List<PollOption>> optionsByPollId = allOptions.stream()
                .collect(Collectors.groupingBy(PollOption::getPollId));

        // Fetch all votes for all polls in one query
        List<PollVote> allVotes = pollVoteRepository.findByPollIdIn(pollIds);
        // Count votes per option
        Map<UUID, Long> voteCountByOptionId = allVotes.stream()
                .collect(Collectors.groupingBy(PollVote::getOptionId, Collectors.counting()));
        // My vote per poll
        Map<UUID, UUID> myVoteByPollId = allVotes.stream()
                .filter(v -> v.getUserId().equals(userId))
                .collect(Collectors.toMap(PollVote::getPollId, PollVote::getOptionId));

        List<PollResponse> result = new ArrayList<>();
        for (Poll poll : polls) {
            List<PollOption> options = optionsByPollId.getOrDefault(poll.getId(), List.of());
            // Sort by position
            List<PollOptionResult> optionResults = options.stream()
                    .sorted((a, b) -> Integer.compare(a.getPosition(), b.getPosition()))
                    .map(opt -> new PollOptionResult(
                            opt.getId(),
                            opt.getText(),
                            voteCountByOptionId.getOrDefault(opt.getId(), 0L)))
                    .toList();

            UUID myVote = myVoteByPollId.get(poll.getId());
            result.add(new PollResponse(
                    poll.getId(),
                    poll.getQuestion(),
                    poll.isClosed(),
                    poll.getCreatedBy(),
                    optionResults,
                    myVote));
        }
        return result;
    }

    @Transactional
    public PollResponse create(UUID userId, CreatePollRequest request) {
        HouseholdContext ctx = householdContext.requireContribute(userId);

        List<String> options = request.options();
        if (options == null || options.size() < 2 || options.size() > 10) {
            throw new DomainException(ErrorCode.VALIDATION_FAILED,
                    "Опрос должен содержать от 2 до 10 вариантов ответа");
        }

        Poll poll = new Poll(ctx.householdId(), userId, request.question());
        pollRepository.save(poll);

        List<PollOption> savedOptions = new ArrayList<>();
        for (int i = 0; i < options.size(); i++) {
            String text = options.get(i);
            if (text == null || text.isBlank()) {
                throw new DomainException(ErrorCode.VALIDATION_FAILED, "Вариант ответа не может быть пустым");
            }
            PollOption opt = new PollOption(poll.getId(), text.trim(), i);
            pollOptionRepository.save(opt);
            savedOptions.add(opt);
        }

        List<PollOptionResult> optionResults = savedOptions.stream()
                .map(opt -> new PollOptionResult(opt.getId(), opt.getText(), 0L))
                .toList();

        return new PollResponse(
                poll.getId(),
                poll.getQuestion(),
                poll.isClosed(),
                poll.getCreatedBy(),
                optionResults,
                null);
    }

    @Transactional
    public void vote(UUID userId, UUID pollId, UUID optionId) {
        HouseholdContext ctx = householdContext.requireContribute(userId);

        Poll poll = pollRepository.findById(pollId)
                .orElseThrow(() -> new NotFoundException("Опрос не найден"));

        if (!poll.getHouseholdId().equals(ctx.householdId())) {
            throw new NotFoundException("Опрос не найден");
        }

        if (poll.isClosed()) {
            throw new DomainException(ErrorCode.VALIDATION_FAILED, "Опрос уже закрыт");
        }

        // Verify option belongs to poll
        PollOption option = pollOptionRepository.findById(optionId)
                .orElseThrow(() -> new NotFoundException("Вариант ответа не найден"));
        if (!option.getPollId().equals(pollId)) {
            throw new NotFoundException("Вариант ответа не принадлежит данному опросу");
        }

        // Upsert: replace existing vote or create new
        Optional<PollVote> existing = pollVoteRepository.findByPollIdAndUserId(pollId, userId);
        if (existing.isPresent()) {
            // Delete old vote and create new one (UNIQUE constraint on poll_id, user_id)
            pollVoteRepository.delete(existing.get());
            pollVoteRepository.flush();
        }

        PollVote vote = new PollVote(pollId, optionId, userId);
        pollVoteRepository.save(vote);
    }

    @Transactional
    public PollResponse close(UUID userId, UUID pollId) {
        HouseholdContext ctx = householdContext.requireMembership(userId);

        Poll poll = pollRepository.findById(pollId)
                .orElseThrow(() -> new NotFoundException("Опрос не найден"));

        if (!poll.getHouseholdId().equals(ctx.householdId())) {
            throw new NotFoundException("Опрос не найден");
        }

        // Only creator or OWNER/ADULT (canManageSharedContent) can close
        boolean isCreator = poll.getCreatedBy().equals(userId);
        boolean canManage = ctx.canManageSharedContent();

        if (!isCreator && !canManage) {
            throw new ForbiddenException("Только создатель или администратор семьи может закрыть опрос");
        }

        poll.close();
        pollRepository.save(poll);

        // Build response
        List<PollOption> options = pollOptionRepository.findByPollIdOrderByPosition(poll.getId());
        List<PollVote> votes = pollVoteRepository.findByPollIdIn(List.of(pollId));
        Map<UUID, Long> countByOption = votes.stream()
                .collect(Collectors.groupingBy(PollVote::getOptionId, Collectors.counting()));
        UUID myVote = votes.stream()
                .filter(v -> v.getUserId().equals(userId))
                .map(PollVote::getOptionId)
                .findFirst()
                .orElse(null);

        List<PollOptionResult> optionResults = options.stream()
                .map(opt -> new PollOptionResult(opt.getId(), opt.getText(),
                        countByOption.getOrDefault(opt.getId(), 0L)))
                .toList();

        return new PollResponse(poll.getId(), poll.getQuestion(), poll.isClosed(),
                poll.getCreatedBy(), optionResults, myVote);
    }
}
