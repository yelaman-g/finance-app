package com.aifb.platform.shopping.service;

import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.household.service.HouseholdContextService;
import com.aifb.platform.household.service.HouseholdContextService.HouseholdContext;
import com.aifb.platform.shopping.api.dto.ShoppingItemResponse;
import com.aifb.platform.shopping.domain.ShoppingItem;
import com.aifb.platform.shopping.repository.ShoppingItemRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
public class ShoppingService {

    private final ShoppingItemRepository repository;
    private final HouseholdContextService householdContext;

    public ShoppingService(ShoppingItemRepository repository,
                           HouseholdContextService householdContext) {
        this.repository = repository;
        this.householdContext = householdContext;
    }

    @Transactional(readOnly = true)
    public List<ShoppingItemResponse> list(UUID userId) {
        HouseholdContext ctx = householdContext.membershipOrNull(userId);
        if (ctx == null) {
            return List.of();
        }
        return repository.findByHouseholdIdOrderByCheckedAscUpdatedAtDesc(ctx.householdId())
                .stream()
                .map(ShoppingItemResponse::from)
                .toList();
    }

    @Transactional
    public ShoppingItemResponse add(UUID userId, String title) {
        HouseholdContext ctx = householdContext.requireContribute(userId);
        ShoppingItem item = new ShoppingItem(ctx.householdId(), title, userId);
        return ShoppingItemResponse.from(repository.save(item));
    }

    @Transactional
    public ShoppingItemResponse toggle(UUID userId, UUID itemId) {
        HouseholdContext ctx = householdContext.requireContribute(userId);
        ShoppingItem item = loadItem(itemId, ctx.householdId());
        item.toggle();
        return ShoppingItemResponse.from(repository.save(item));
    }

    @Transactional
    public void delete(UUID userId, UUID itemId) {
        HouseholdContext ctx = householdContext.requireContribute(userId);
        ShoppingItem item = loadItem(itemId, ctx.householdId());
        repository.delete(item);
    }

    private ShoppingItem loadItem(UUID itemId, UUID householdId) {
        ShoppingItem item = repository.findById(itemId)
                .orElseThrow(() -> new NotFoundException("Позиция не найдена"));
        if (!householdId.equals(item.getHouseholdId())) {
            throw new NotFoundException("Позиция не найдена");
        }
        return item;
    }
}
