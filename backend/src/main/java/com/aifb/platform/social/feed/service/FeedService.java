package com.aifb.platform.social.feed.service;

import com.aifb.platform.auth.domain.User;
import com.aifb.platform.auth.repository.UserRepository;
import com.aifb.platform.common.exception.ForbiddenException;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.household.service.HouseholdContextService;
import com.aifb.platform.household.service.HouseholdContextService.HouseholdContext;
import com.aifb.platform.social.feed.api.dto.CreateMomentRequest;
import com.aifb.platform.social.feed.api.dto.MomentResponse;
import com.aifb.platform.social.feed.domain.FeedLike;
import com.aifb.platform.social.feed.domain.FeedMoment;
import com.aifb.platform.social.feed.repository.FeedLikeRepository;
import com.aifb.platform.social.feed.repository.FeedMomentRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class FeedService {

    private final FeedMomentRepository momentRepository;
    private final FeedLikeRepository likeRepository;
    private final HouseholdContextService householdContext;
    private final UserRepository userRepository;

    public FeedService(FeedMomentRepository momentRepository,
                       FeedLikeRepository likeRepository,
                       HouseholdContextService householdContext,
                       UserRepository userRepository) {
        this.momentRepository = momentRepository;
        this.likeRepository = likeRepository;
        this.householdContext = householdContext;
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public List<MomentResponse> list(UUID userId) {
        HouseholdContext ctx = householdContext.membershipOrNull(userId);
        if (ctx == null) {
            return List.of();
        }

        List<FeedMoment> moments = momentRepository.findByHouseholdIdOrderByCreatedAtDesc(ctx.householdId());
        if (moments.isEmpty()) {
            return List.of();
        }

        // Build author name map
        Map<UUID, String> nameById = userRepository.findByHouseholdId(ctx.householdId())
                .stream()
                .collect(Collectors.toMap(User::getId, User::getFullName));

        // Fetch all likes for these moments in one query
        List<UUID> momentIds = moments.stream().map(FeedMoment::getId).toList();
        List<FeedLike> allLikes = likeRepository.findByMomentIdIn(momentIds);

        // Count likes per moment
        Map<UUID, Long> likesCount = allLikes.stream()
                .collect(Collectors.groupingBy(FeedLike::getMomentId, Collectors.counting()));

        // Set of moment IDs that the current user liked
        Set<UUID> likedByMe = allLikes.stream()
                .filter(l -> l.getUserId().equals(userId))
                .map(FeedLike::getMomentId)
                .collect(Collectors.toSet());

        return moments.stream()
                .map(m -> new MomentResponse(
                        m.getId(),
                        m.getAuthorId(),
                        nameById.getOrDefault(m.getAuthorId(), "Unknown"),
                        m.getText(),
                        m.getCreatedAt(),
                        likesCount.getOrDefault(m.getId(), 0L),
                        likedByMe.contains(m.getId())
                ))
                .toList();
    }

    @Transactional
    public MomentResponse post(UUID userId, CreateMomentRequest request) {
        HouseholdContext ctx = householdContext.requireContribute(userId);
        FeedMoment moment = new FeedMoment(ctx.householdId(), userId, request.text());
        momentRepository.save(moment);

        String authorName = userRepository.findById(userId)
                .map(User::getFullName)
                .orElse("Unknown");

        return new MomentResponse(
                moment.getId(),
                moment.getAuthorId(),
                authorName,
                moment.getText(),
                moment.getCreatedAt(),
                0L,
                false
        );
    }

    @Transactional
    public void delete(UUID userId, UUID momentId) {
        HouseholdContext ctx = householdContext.requireMembership(userId);
        FeedMoment moment = momentRepository.findById(momentId)
                .orElseThrow(() -> new NotFoundException("Момент не найден"));

        if (!moment.getHouseholdId().equals(ctx.householdId())) {
            throw new NotFoundException("Момент не найден");
        }

        boolean isAuthor = moment.getAuthorId().equals(userId);
        boolean canManage = ctx.canManageSharedContent();

        if (!isAuthor && !canManage) {
            throw new ForbiddenException("Удалить момент может только автор или администратор семьи");
        }

        momentRepository.delete(moment);
    }

    @Transactional
    public void like(UUID userId, UUID momentId) {
        HouseholdContext ctx = householdContext.requireContribute(userId);
        FeedMoment moment = momentRepository.findById(momentId)
                .orElseThrow(() -> new NotFoundException("Момент не найден"));

        if (!moment.getHouseholdId().equals(ctx.householdId())) {
            throw new NotFoundException("Момент не найден");
        }

        // Honor unique constraint: only insert if not already liked
        boolean alreadyLiked = likeRepository.findByMomentIdAndUserId(momentId, userId).isPresent();
        if (!alreadyLiked) {
            likeRepository.save(new FeedLike(momentId, userId));
        }
    }

    @Transactional
    public void unlike(UUID userId, UUID momentId) {
        likeRepository.deleteByMomentIdAndUserId(momentId, userId);
    }
}
