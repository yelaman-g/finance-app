package com.aifb.platform.finance.budget.service;

import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.common.exception.ConflictException;
import com.aifb.platform.common.exception.DomainException;
import com.aifb.platform.common.exception.ErrorCode;
import com.aifb.platform.common.exception.ForbiddenException;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.finance.budget.api.dto.BudgetResponse;
import com.aifb.platform.finance.budget.api.dto.BudgetWarning;
import com.aifb.platform.finance.budget.api.dto.CreateBudgetRequest;
import com.aifb.platform.finance.budget.api.dto.UpdateBudgetRequest;
import com.aifb.platform.finance.budget.domain.BudgetLimit;
import com.aifb.platform.finance.budget.domain.BudgetStatus;
import com.aifb.platform.finance.budget.domain.BudgetTargetType;
import com.aifb.platform.finance.budget.repository.BudgetLimitRepository;
import com.aifb.platform.finance.budget.repository.BudgetSpendingRepository;
import com.aifb.platform.finance.category.domain.Category;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.repository.CategoryRepository;
import com.aifb.platform.finance.group.domain.CategoryGroup;
import com.aifb.platform.finance.group.repository.CategoryGroupRepository;
import com.aifb.platform.household.service.HouseholdContextService;
import com.aifb.platform.household.service.HouseholdContextService.HouseholdContext;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class BudgetService {

    private final BudgetLimitRepository repository;
    private final BudgetSpendingRepository spendingRepository;
    private final CategoryRepository categoryRepository;
    private final CategoryGroupRepository groupRepository;
    private final HouseholdContextService householdContext;

    public BudgetService(BudgetLimitRepository repository,
                         BudgetSpendingRepository spendingRepository,
                         CategoryRepository categoryRepository,
                         CategoryGroupRepository groupRepository,
                         HouseholdContextService householdContext) {
        this.repository = repository;
        this.spendingRepository = spendingRepository;
        this.categoryRepository = categoryRepository;
        this.groupRepository = groupRepository;
        this.householdContext = householdContext;
    }

    @Transactional
    public BudgetResponse create(UUID userId, CreateBudgetRequest req) {
        UUID householdId = null;
        if (req.shared()) {
            HouseholdContext ctx = householdContext.requireManageSharedContent(userId);
            householdId = ctx.householdId();
        }
        BudgetLimit limit;
        if (req.targetType() == BudgetTargetType.CATEGORY) {
            if (req.categoryId() == null) {
                throw new DomainException(ErrorCode.VALIDATION_FAILED, "Не указана категория");
            }
            Category category = resolveVisibleCategory(userId, householdId, req.categoryId());
            if (category.getType() != CategoryType.EXPENSE) {
                throw new DomainException(ErrorCode.VALIDATION_FAILED, "Лимит только для расходов");
            }
            boolean dupCat = householdId == null
                    ? repository.findByCategoryIdAndUserIdAndHouseholdIdIsNull(category.getId(), userId).isPresent()
                    : repository.findByCategoryIdAndHouseholdId(category.getId(), householdId).isPresent();
            if (dupCat) {
                throw new ConflictException("Лимит на эту категорию уже существует");
            }
            limit = new BudgetLimit(userId, category.getId(), null, req.amount());
        } else {
            if (req.groupId() == null) {
                throw new DomainException(ErrorCode.VALIDATION_FAILED, "Не указана группа");
            }
            CategoryGroup group = resolveVisibleGroup(userId, householdId, req.groupId());
            if (group.getType() != CategoryType.EXPENSE) {
                throw new DomainException(ErrorCode.VALIDATION_FAILED, "Лимит только для расходов");
            }
            boolean dupGroup = householdId == null
                    ? repository.findByGroupIdAndUserIdAndHouseholdIdIsNull(group.getId(), userId).isPresent()
                    : repository.findByGroupIdAndHouseholdId(group.getId(), householdId).isPresent();
            if (dupGroup) {
                throw new ConflictException("Лимит на эту группу уже существует");
            }
            limit = new BudgetLimit(userId, null, group.getId(), req.amount());
        }
        if (householdId != null) {
            limit.assignHousehold(householdId);
        }
        return toResponse(repository.save(limit));
    }

    @Transactional(readOnly = true)
    public List<BudgetResponse> list(UUID userId, Scope scope) {
        List<BudgetLimit> limits;
        if (scope == Scope.FAMILY) {
            HouseholdContext ctx = householdContext.membershipOrNull(userId);
            limits = ctx == null ? List.of() : repository.findByHouseholdId(ctx.householdId());
        } else {
            limits = repository.findByUserIdAndHouseholdIdIsNull(userId);
        }
        return limits.stream().map(this::toResponse).toList();
    }

    @Transactional
    public BudgetResponse update(UUID userId, UUID id, UpdateBudgetRequest req) {
        BudgetLimit limit = manageableLimit(userId, id);
        limit.setAmount(req.amount());
        return toResponse(repository.save(limit));
    }

    @Transactional
    public void delete(UUID userId, UUID id) {
        repository.delete(manageableLimit(userId, id));
    }

    @Transactional(readOnly = true)
    public List<BudgetWarning> warningsForExpense(UUID userId, UUID householdId,
                                                  UUID categoryId, UUID groupId) {
        List<BudgetWarning> warnings = new ArrayList<>();
        findScopedByCategory(userId, householdId, categoryId).ifPresent(limit ->
                addIfNotOk(warnings, limit));
        if (groupId != null) {
            findScopedByGroup(userId, householdId, groupId).ifPresent(limit ->
                    addIfNotOk(warnings, limit));
        }
        return warnings;
    }

    private Optional<BudgetLimit> findScopedByCategory(UUID userId, UUID householdId, UUID categoryId) {
        return householdId == null
                ? repository.findByCategoryIdAndUserIdAndHouseholdIdIsNull(categoryId, userId)
                : repository.findByCategoryIdAndHouseholdId(categoryId, householdId);
    }

    private Optional<BudgetLimit> findScopedByGroup(UUID userId, UUID householdId, UUID groupId) {
        return householdId == null
                ? repository.findByGroupIdAndUserIdAndHouseholdIdIsNull(groupId, userId)
                : repository.findByGroupIdAndHouseholdId(groupId, householdId);
    }

    private void addIfNotOk(List<BudgetWarning> warnings, BudgetLimit limit) {
        BigDecimal spent = spent(limit);
        BudgetStatus status = BudgetStatus.of(spent, limit.getAmount());
        if (status != BudgetStatus.OK) {
            warnings.add(new BudgetWarning(limit.getTargetType().name(), targetName(limit),
                    limit.getAmount(), spent, percentage(spent, limit.getAmount()), status.name()));
        }
    }

    private Category resolveVisibleCategory(UUID userId, UUID householdId, UUID categoryId) {
        return (householdId == null
                ? categoryRepository.findVisibleByIdPersonal(categoryId, userId)
                : categoryRepository.findVisibleByIdFamily(categoryId, householdId))
                .orElseThrow(() -> new NotFoundException("Категория не найдена"));
    }

    private CategoryGroup resolveVisibleGroup(UUID userId, UUID householdId, UUID groupId) {
        return (householdId == null
                ? groupRepository.findByIdAndUserIdAndHouseholdIdIsNull(groupId, userId)
                : groupRepository.findByIdAndHouseholdId(groupId, householdId))
                .orElseThrow(() -> new NotFoundException("Группа не найдена"));
    }

    private BudgetLimit manageableLimit(UUID userId, UUID id) {
        BudgetLimit limit = repository.findById(id)
                .orElseThrow(() -> new NotFoundException("Лимит не найден"));
        if (limit.isShared()) {
            HouseholdContext ctx = householdContext.membershipOrNull(userId);
            if (ctx == null || !ctx.householdId().equals(limit.getHouseholdId())) {
                throw new NotFoundException("Лимит не найден");
            }
            if (!ctx.canManageSharedContent()) {
                throw new ForbiddenException("Недостаточно прав для семейного лимита");
            }
            return limit;
        }
        if (!userId.equals(limit.getUserId())) {
            throw new NotFoundException("Лимит не найден");
        }
        return limit;
    }

    private BigDecimal spent(BudgetLimit limit) {
        LocalDate today = LocalDate.now();
        LocalDate from = today.withDayOfMonth(1);
        if (limit.getTargetType() == BudgetTargetType.CATEGORY) {
            return spendingRepository.sumExpenseForCategory(
                    limit.getUserId(), limit.getHouseholdId(), limit.getCategoryId(), from, today);
        }
        return spendingRepository.sumExpenseForGroup(
                limit.getUserId(), limit.getHouseholdId(), limit.getGroupId(), from, today);
    }

    private String targetName(BudgetLimit limit) {
        if (limit.getTargetType() == BudgetTargetType.CATEGORY) {
            return categoryRepository.findById(limit.getCategoryId())
                    .map(Category::getName).orElse("—");
        }
        return groupRepository.findById(limit.getGroupId())
                .map(CategoryGroup::getName).orElse("—");
    }

    private double percentage(BigDecimal spent, BigDecimal limit) {
        return spent.multiply(BigDecimal.valueOf(100))
                .divide(limit, 1, RoundingMode.HALF_UP).doubleValue();
    }

    private BudgetResponse toResponse(BudgetLimit limit) {
        BigDecimal spent = spent(limit);
        UUID targetId = limit.getTargetType() == BudgetTargetType.CATEGORY
                ? limit.getCategoryId() : limit.getGroupId();
        return new BudgetResponse(
                limit.getId(), limit.getTargetType().name(), targetId, targetName(limit),
                limit.getAmount(), spent, percentage(spent, limit.getAmount()),
                BudgetStatus.of(spent, limit.getAmount()).name(), limit.isShared());
    }
}
