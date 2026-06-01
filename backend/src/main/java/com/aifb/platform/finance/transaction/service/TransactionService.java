package com.aifb.platform.finance.transaction.service;

import com.aifb.platform.common.api.PageResponse;
import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.common.exception.DomainException;
import com.aifb.platform.common.exception.ErrorCode;
import com.aifb.platform.common.exception.ForbiddenException;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.finance.category.domain.Category;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.repository.CategoryRepository;
import com.aifb.platform.finance.transaction.api.dto.CreateTransactionRequest;
import com.aifb.platform.finance.transaction.api.dto.TransactionResponse;
import com.aifb.platform.finance.transaction.api.dto.UpdateTransactionRequest;
import com.aifb.platform.finance.transaction.domain.Transaction;
import com.aifb.platform.finance.transaction.repository.TransactionRepository;
import com.aifb.platform.household.service.HouseholdContextService;
import com.aifb.platform.household.service.HouseholdContextService.HouseholdContext;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
public class TransactionService {

    private final TransactionRepository repository;
    private final CategoryRepository categoryRepository;
    private final HouseholdContextService householdContext;

    public TransactionService(TransactionRepository repository,
                              CategoryRepository categoryRepository,
                              HouseholdContextService householdContext) {
        this.repository = repository;
        this.categoryRepository = categoryRepository;
        this.householdContext = householdContext;
    }

    @Transactional(readOnly = true)
    public PageResponse<TransactionResponse> list(UUID userId, LocalDate from, LocalDate to,
                                                  CategoryType type, UUID categoryId,
                                                  Scope scope, int page, int size) {
        Pageable pageable = PageRequest.of(page, size,
                Sort.by(Sort.Direction.DESC, "occurredOn")
                        .and(Sort.by(Sort.Direction.DESC, "createdAt")));
        Page<Transaction> result;
        if (scope == Scope.FAMILY) {
            HouseholdContext ctx = householdContext.membershipOrNull(userId);
            result = ctx == null ? Page.empty(pageable)
                    : repository.searchFamily(ctx.householdId(), from, to, type, categoryId, pageable);
        } else {
            result = repository.search(userId, from, to, type, categoryId, pageable);
        }
        Map<UUID, Category> categories = categoryRepository.findByIdIn(
                        result.getContent().stream().map(Transaction::getCategoryId).distinct().toList())
                .stream().collect(Collectors.toMap(Category::getId, Function.identity()));
        return PageResponse.from(result.map(
                t -> TransactionResponse.from(t, categories.get(t.getCategoryId()))));
    }

    @Transactional(readOnly = true)
    public TransactionResponse get(UUID userId, UUID id) {
        Transaction t = visibleTransaction(userId, id);
        return TransactionResponse.from(t, loadCategory(t.getCategoryId()));
    }

    @Transactional
    public TransactionResponse create(UUID userId, CreateTransactionRequest req) {
        if (req.shared()) {
            HouseholdContext ctx = householdContext.requireMembership(userId);
            Category category = categoryRepository.findVisibleByIdFamily(req.categoryId(), ctx.householdId())
                    .orElseThrow(() -> new NotFoundException("Категория не найдена"));
            validateType(category, req.type());
            Transaction t = new Transaction(userId, category.getId(), req.type(),
                    req.amount(), req.note(), req.occurredOn());
            t.assignHousehold(ctx.householdId());
            return TransactionResponse.from(repository.save(t), category);
        }
        Category category = categoryRepository.findVisibleByIdPersonal(req.categoryId(), userId)
                .orElseThrow(() -> new NotFoundException("Категория не найдена"));
        validateType(category, req.type());
        Transaction t = new Transaction(userId, category.getId(), req.type(),
                req.amount(), req.note(), req.occurredOn());
        return TransactionResponse.from(repository.save(t), category);
    }

    @Transactional
    public TransactionResponse update(UUID userId, UUID id, UpdateTransactionRequest req) {
        Transaction t = editableTransaction(userId, id);
        Category category = resolveCategoryForExisting(userId, t, req.categoryId(), req.type());
        t.setCategoryId(category.getId());
        t.setType(req.type());
        t.setAmount(req.amount());
        t.setNote(req.note());
        t.setOccurredOn(req.occurredOn());
        return TransactionResponse.from(repository.save(t), category);
    }

    @Transactional
    public void delete(UUID userId, UUID id) {
        Transaction t = editableTransaction(userId, id);
        repository.delete(t);
    }

    private void validateType(Category category, CategoryType type) {
        if (category.getType() != type) {
            throw new DomainException(ErrorCode.VALIDATION_FAILED,
                    "Тип операции не совпадает с типом категории");
        }
    }

    private Transaction visibleTransaction(UUID userId, UUID id) {
        Transaction t = repository.findById(id)
                .orElseThrow(() -> new NotFoundException("Транзакция не найдена"));
        if (t.isShared()) {
            HouseholdContext ctx = householdContext.membershipOrNull(userId);
            if (ctx == null || !ctx.householdId().equals(t.getHouseholdId())) {
                throw new NotFoundException("Транзакция не найдена");
            }
            return t;
        }
        if (!userId.equals(t.getUserId())) {
            throw new NotFoundException("Транзакция не найдена");
        }
        return t;
    }

    private Transaction editableTransaction(UUID userId, UUID id) {
        Transaction t = visibleTransaction(userId, id);
        if (t.isShared()) {
            HouseholdContext ctx = householdContext.membershipOrNull(userId);
            boolean own = userId.equals(t.getUserId());
            boolean canManage = ctx != null && ctx.canManageSharedContent();
            if (!own && !canManage) {
                throw new ForbiddenException("Нет прав на изменение чужой семейной операции");
            }
        }
        return t;
    }

    private Category resolveCategoryForExisting(UUID userId, Transaction t,
                                                UUID categoryId, CategoryType type) {
        Category category = t.isShared()
                ? categoryRepository.findVisibleByIdFamily(categoryId, t.getHouseholdId())
                    .orElseThrow(() -> new NotFoundException("Категория не найдена"))
                : categoryRepository.findVisibleByIdPersonal(categoryId, userId)
                    .orElseThrow(() -> new NotFoundException("Категория не найдена"));
        validateType(category, type);
        return category;
    }

    private Category loadCategory(UUID categoryId) {
        List<Category> found = categoryRepository.findByIdIn(List.of(categoryId));
        return found.isEmpty() ? null : found.get(0);
    }
}
