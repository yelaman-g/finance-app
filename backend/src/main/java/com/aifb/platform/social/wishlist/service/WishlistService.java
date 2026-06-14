package com.aifb.platform.social.wishlist.service;

import com.aifb.platform.auth.repository.UserRepository;
import com.aifb.platform.common.exception.ForbiddenException;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.household.service.HouseholdContextService;
import com.aifb.platform.household.service.HouseholdContextService.HouseholdContext;
import com.aifb.platform.social.wishlist.api.dto.AddWishlistItemRequest;
import com.aifb.platform.social.wishlist.api.dto.WishlistItemResponse;
import com.aifb.platform.social.wishlist.domain.WishlistItem;
import com.aifb.platform.social.wishlist.repository.WishlistItemRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class WishlistService {

    private final WishlistItemRepository repository;
    private final HouseholdContextService householdContext;
    private final UserRepository userRepository;

    public WishlistService(WishlistItemRepository repository,
                           HouseholdContextService householdContext,
                           UserRepository userRepository) {
        this.repository = repository;
        this.householdContext = householdContext;
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public List<WishlistItemResponse> list(UUID userId) {
        HouseholdContext ctx = householdContext.membershipOrNull(userId);
        if (ctx == null) {
            return List.of();
        }
        Map<UUID, String> nameById = userRepository.findByHouseholdId(ctx.householdId())
                .stream()
                .collect(Collectors.toMap(u -> u.getId(), u -> u.getFullName()));

        return repository.findByHouseholdIdOrderByCreatedAtDesc(ctx.householdId())
                .stream()
                .map(item -> WishlistItemResponse.from(
                        item,
                        nameById.getOrDefault(item.getUserId(), "Unknown")))
                .toList();
    }

    @Transactional
    public WishlistItemResponse add(UUID userId, AddWishlistItemRequest request) {
        HouseholdContext ctx = householdContext.requireContribute(userId);
        WishlistItem item = new WishlistItem(ctx.householdId(), userId, request.title(), request.note());
        repository.save(item);
        String ownerName = userRepository.findById(userId)
                .map(u -> u.getFullName())
                .orElse("Unknown");
        return WishlistItemResponse.from(item, ownerName);
    }

    @Transactional
    public void delete(UUID userId, UUID itemId) {
        HouseholdContext ctx = householdContext.requireMembership(userId);
        WishlistItem item = loadItem(itemId, ctx.householdId());
        if (!item.getUserId().equals(userId)) {
            throw new ForbiddenException("Можно удалять только свои желания");
        }
        repository.delete(item);
    }

    @Transactional
    public WishlistItemResponse reserve(UUID userId, UUID itemId) {
        HouseholdContext ctx = householdContext.requireContribute(userId);
        WishlistItem item = loadItem(itemId, ctx.householdId());
        if (item.getUserId().equals(userId)) {
            throw new ForbiddenException("Нельзя зарезервировать свой подарок");
        }
        item.reserve(userId);
        repository.save(item);
        String ownerName = userRepository.findById(item.getUserId())
                .map(u -> u.getFullName())
                .orElse("Unknown");
        return WishlistItemResponse.from(item, ownerName);
    }

    @Transactional
    public WishlistItemResponse unreserve(UUID userId, UUID itemId) {
        HouseholdContext ctx = householdContext.requireMembership(userId);
        WishlistItem item = loadItem(itemId, ctx.householdId());
        if (!userId.equals(item.getReservedBy())) {
            throw new ForbiddenException("Снять резерв может только тот, кто его поставил");
        }
        item.clearReserve();
        repository.save(item);
        String ownerName = userRepository.findById(item.getUserId())
                .map(u -> u.getFullName())
                .orElse("Unknown");
        return WishlistItemResponse.from(item, ownerName);
    }

    private WishlistItem loadItem(UUID itemId, UUID householdId) {
        WishlistItem item = repository.findById(itemId)
                .orElseThrow(() -> new NotFoundException("Желание не найдено"));
        if (!householdId.equals(item.getHouseholdId())) {
            throw new NotFoundException("Желание не найдено");
        }
        return item;
    }
}
