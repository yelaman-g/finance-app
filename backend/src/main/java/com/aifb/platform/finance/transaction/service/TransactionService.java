package com.aifb.platform.finance.transaction.service;

import com.aifb.platform.common.api.PageResponse;
import com.aifb.platform.common.exception.ErrorCode;
import com.aifb.platform.common.exception.DomainException;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.finance.category.domain.Category;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.repository.CategoryRepository;
import com.aifb.platform.finance.transaction.api.dto.CreateTransactionRequest;
import com.aifb.platform.finance.transaction.api.dto.TransactionResponse;
import com.aifb.platform.finance.transaction.api.dto.UpdateTransactionRequest;
import com.aifb.platform.finance.transaction.domain.Transaction;
import com.aifb.platform.finance.transaction.repository.TransactionRepository;
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

    public TransactionService(TransactionRepository repository,
                              CategoryRepository categoryRepository) {
        this.repository = repository;
        this.categoryRepository = categoryRepository;
    }

    @Transactional(readOnly = true)
    public PageResponse<TransactionResponse> list(UUID userId, LocalDate from, LocalDate to,
                                                  CategoryType type, UUID categoryId,
                                                  int page, int size) {
        Pageable pageable = PageRequest.of(page, size,
                Sort.by(Sort.Direction.DESC, "occurredOn")
                        .and(Sort.by(Sort.Direction.DESC, "createdAt")));
        Page<Transaction> result = repository.search(userId, from, to, type, categoryId, pageable);

        Map<UUID, Category> categories = categoryRepository.findByIdInAndDeletedAtIsNull(
                        result.getContent().stream().map(Transaction::getCategoryId).distinct().toList())
                .stream().collect(Collectors.toMap(Category::getId, Function.identity()));

        Page<TransactionResponse> mapped = result.map(
                t -> TransactionResponse.from(t, categories.get(t.getCategoryId())));
        return PageResponse.from(mapped);
    }

    @Transactional(readOnly = true)
    public TransactionResponse get(UUID userId, UUID id) {
        Transaction t = repository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new NotFoundException("Транзакция не найдена"));
        return TransactionResponse.from(t, loadCategory(t.getCategoryId()));
    }

    @Transactional
    public TransactionResponse create(UUID userId, CreateTransactionRequest req) {
        Category category = resolveCategory(userId, req.categoryId(), req.type());
        Transaction t = new Transaction(userId, category.getId(), req.type(),
                req.amount(), req.note(), req.occurredOn());
        return TransactionResponse.from(repository.save(t), category);
    }

    @Transactional
    public TransactionResponse update(UUID userId, UUID id, UpdateTransactionRequest req) {
        Transaction t = repository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new NotFoundException("Транзакция не найдена"));
        Category category = resolveCategory(userId, req.categoryId(), req.type());
        t.setCategoryId(category.getId());
        t.setType(req.type());
        t.setAmount(req.amount());
        t.setNote(req.note());
        t.setOccurredOn(req.occurredOn());
        return TransactionResponse.from(repository.save(t), category);
    }

    @Transactional
    public void delete(UUID userId, UUID id) {
        Transaction t = repository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new NotFoundException("Транзакция не найдена"));
        repository.delete(t);
    }

    private Category resolveCategory(UUID userId, UUID categoryId, CategoryType type) {
        Category category = categoryRepository.findVisibleByIdForUser(categoryId, userId)
                .orElseThrow(() -> new NotFoundException("Категория не найдена"));
        if (category.getType() != type) {
            throw new DomainException(ErrorCode.VALIDATION_FAILED,
                    "Тип операции не совпадает с типом категории");
        }
        return category;
    }

    private Category loadCategory(UUID categoryId) {
        List<Category> found = categoryRepository.findByIdInAndDeletedAtIsNull(List.of(categoryId));
        return found.isEmpty() ? null : found.get(0);
    }
}
