package com.aifb.platform.finance.group.service;

import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.common.exception.ForbiddenException;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.group.api.dto.CreateGroupRequest;
import com.aifb.platform.finance.group.api.dto.GroupResponse;
import com.aifb.platform.finance.group.api.dto.UpdateGroupRequest;
import com.aifb.platform.finance.group.domain.CategoryGroup;
import com.aifb.platform.finance.group.repository.CategoryGroupRepository;
import com.aifb.platform.household.service.HouseholdContextService;
import com.aifb.platform.household.service.HouseholdContextService.HouseholdContext;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
public class CategoryGroupService {

    private final CategoryGroupRepository repository;
    private final HouseholdContextService householdContext;

    public CategoryGroupService(CategoryGroupRepository repository,
                                HouseholdContextService householdContext) {
        this.repository = repository;
        this.householdContext = householdContext;
    }

    @Transactional(readOnly = true)
    public List<GroupResponse> list(UUID userId, CategoryType type, Scope scope) {
        List<CategoryGroup> groups;
        if (scope == Scope.FAMILY) {
            HouseholdContext ctx = householdContext.membershipOrNull(userId);
            groups = ctx == null ? List.of()
                    : repository.findVisibleFamily(ctx.householdId(), type);
        } else {
            groups = repository.findVisiblePersonal(userId, type);
        }
        return groups.stream().map(GroupResponse::from).toList();
    }

    @Transactional
    public GroupResponse create(UUID userId, CreateGroupRequest req) {
        CategoryGroup group = new CategoryGroup(userId, req.name(), req.type(), req.icon(), req.color());
        if (req.shared()) {
            HouseholdContext ctx = householdContext.requireManageSharedContent(userId);
            group.assignHousehold(ctx.householdId());
        }
        return GroupResponse.from(repository.save(group));
    }

    @Transactional
    public GroupResponse update(UUID userId, UUID id, UpdateGroupRequest req) {
        CategoryGroup group = manageableGroup(userId, id);
        group.setName(req.name());
        group.setIcon(req.icon());
        group.setColor(req.color());
        return GroupResponse.from(repository.save(group));
    }

    @Transactional
    public void delete(UUID userId, UUID id) {
        CategoryGroup group = manageableGroup(userId, id);
        repository.delete(group);
    }

    private CategoryGroup manageableGroup(UUID userId, UUID id) {
        CategoryGroup group = repository.findById(id)
                .orElseThrow(() -> new NotFoundException("Группа не найдена"));
        if (group.isShared()) {
            HouseholdContext ctx = householdContext.membershipOrNull(userId);
            if (ctx == null || !ctx.householdId().equals(group.getHouseholdId())) {
                throw new NotFoundException("Группа не найдена");
            }
            if (!ctx.canManageSharedContent()) {
                throw new ForbiddenException("Недостаточно прав для семейной группы");
            }
            return group;
        }
        if (!userId.equals(group.getUserId())) {
            throw new NotFoundException("Группа не найдена");
        }
        return group;
    }
}
