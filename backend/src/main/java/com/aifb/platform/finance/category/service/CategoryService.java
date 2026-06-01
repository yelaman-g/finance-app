package com.aifb.platform.finance.category.service;

import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.common.exception.ConflictException;
import com.aifb.platform.common.exception.DomainException;
import com.aifb.platform.common.exception.ErrorCode;
import com.aifb.platform.common.exception.ForbiddenException;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.finance.category.api.dto.CategoryResponse;
import com.aifb.platform.finance.category.api.dto.CreateCategoryRequest;
import com.aifb.platform.finance.category.api.dto.UpdateCategoryRequest;
import com.aifb.platform.finance.category.domain.Category;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.repository.CategoryRepository;
import com.aifb.platform.finance.group.domain.CategoryGroup;
import com.aifb.platform.finance.group.repository.CategoryGroupRepository;
import com.aifb.platform.household.service.HouseholdContextService;
import com.aifb.platform.household.service.HouseholdContextService.HouseholdContext;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
public class CategoryService {

    private final CategoryRepository repository;
    private final HouseholdContextService householdContext;
    private final CategoryGroupRepository groupRepository;

    public CategoryService(CategoryRepository repository,
                           HouseholdContextService householdContext,
                           CategoryGroupRepository groupRepository) {
        this.repository = repository;
        this.householdContext = householdContext;
        this.groupRepository = groupRepository;
    }

    @Transactional(readOnly = true)
    public List<CategoryResponse> list(UUID userId, CategoryType type, Scope scope) {
        List<Category> categories;
        if (scope == Scope.FAMILY) {
            HouseholdContext ctx = householdContext.membershipOrNull(userId);
            categories = ctx == null ? List.of()
                    : repository.findVisibleFamily(ctx.householdId(), type);
        } else {
            categories = repository.findVisiblePersonal(userId, type);
        }
        return categories.stream().map(CategoryResponse::from).toList();
    }

    @Transactional
    public CategoryResponse create(UUID userId, CreateCategoryRequest req) {
        if (req.shared()) {
            HouseholdContext ctx = householdContext.requireManageSharedContent(userId);
            if (repository.existsByHouseholdIdAndTypeAndNameIgnoreCaseAndDeletedAtIsNull(
                    ctx.householdId(), req.type(), req.name())) {
                throw new ConflictException("Семейная категория с таким именем уже существует");
            }
            Category category = new Category(userId, req.name(), req.type(), req.icon(), req.color());
            category.assignHousehold(ctx.householdId());
            applyGroup(category, req.groupId(), userId, ctx.householdId());
            return CategoryResponse.from(repository.save(category));
        }
        if (repository.existsByUserIdAndTypeAndNameIgnoreCaseAndDeletedAtIsNull(
                userId, req.type(), req.name())) {
            throw new ConflictException("Категория с таким именем уже существует");
        }
        Category category = new Category(userId, req.name(), req.type(), req.icon(), req.color());
        applyGroup(category, req.groupId(), userId, null);
        return CategoryResponse.from(repository.save(category));
    }

    @Transactional
    public CategoryResponse update(UUID userId, UUID id, UpdateCategoryRequest req) {
        Category category = manageableCategory(userId, id);
        category.setName(req.name());
        category.setIcon(req.icon());
        category.setColor(req.color());
        applyGroup(category, req.groupId(), userId, category.getHouseholdId());
        return CategoryResponse.from(repository.save(category));
    }

    @Transactional
    public void delete(UUID userId, UUID id) {
        Category category = manageableCategory(userId, id);
        category.softDelete(Instant.now());
        repository.save(category);
    }

    private void applyGroup(Category category, UUID groupId, UUID userId, UUID householdId) {
        if (groupId == null) {
            category.assignGroup(null);
            return;
        }
        CategoryGroup group = groupRepository.findById(groupId)
                .orElseThrow(() -> new DomainException(ErrorCode.VALIDATION_FAILED, "Группа не найдена"));
        boolean sameScope = householdId == null
                ? (group.getHouseholdId() == null && userId.equals(group.getUserId()))
                : householdId.equals(group.getHouseholdId());
        if (!sameScope) {
            throw new DomainException(ErrorCode.VALIDATION_FAILED, "Группа недоступна в этом контексте");
        }
        if (group.getType() != category.getType()) {
            throw new DomainException(ErrorCode.VALIDATION_FAILED, "Тип группы не совпадает с категорией");
        }
        category.assignGroup(group.getId());
    }

    private Category manageableCategory(UUID userId, UUID id) {
        Category category = repository.findById(id)
                .filter(c -> !c.isDeleted())
                .orElseThrow(() -> new NotFoundException("Категория не найдена"));
        if (category.isSystem()) {
            throw new ForbiddenException("Системные категории нельзя изменять");
        }
        if (category.isShared()) {
            HouseholdContext ctx = householdContext.membershipOrNull(userId);
            if (ctx == null || !ctx.householdId().equals(category.getHouseholdId())) {
                throw new NotFoundException("Категория не найдена");
            }
            if (!ctx.canManageSharedContent()) {
                throw new ForbiddenException("Недостаточно прав для семейной категории");
            }
            return category;
        }
        if (!userId.equals(category.getUserId())) {
            throw new NotFoundException("Категория не найдена");
        }
        return category;
    }
}
