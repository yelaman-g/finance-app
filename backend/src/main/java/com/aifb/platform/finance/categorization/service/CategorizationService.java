package com.aifb.platform.finance.categorization.service;

import com.aifb.platform.common.exception.ConflictException;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.finance.categorization.api.dto.CreateRuleRequest;
import com.aifb.platform.finance.categorization.api.dto.RuleResponse;
import com.aifb.platform.finance.categorization.api.dto.UpdateRuleRequest;
import com.aifb.platform.finance.categorization.domain.CategorizationRule;
import com.aifb.platform.finance.categorization.repository.CategorizationRuleRepository;
import com.aifb.platform.finance.category.domain.Category;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.repository.CategoryRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class CategorizationService {

    private final CategorizationRuleRepository repository;
    private final CategoryRepository categoryRepository;

    public CategorizationService(CategorizationRuleRepository repository,
                                 CategoryRepository categoryRepository) {
        this.repository = repository;
        this.categoryRepository = categoryRepository;
    }

    @Transactional(readOnly = true)
    public List<RuleResponse> list(UUID userId) {
        return repository.findByUserIdOrderByCreatedAtDesc(userId).stream()
                .map(this::toResponse).toList();
    }

    @Transactional
    public RuleResponse create(UUID userId, CreateRuleRequest req) {
        requireOwnVisibleCategory(userId, req.categoryId());
        if (repository.existsByUserIdAndKeywordIgnoreCase(userId, req.keyword())) {
            throw new ConflictException("Правило с таким ключевым словом уже есть");
        }
        CategorizationRule rule = new CategorizationRule(userId, req.keyword(), req.categoryId());
        return toResponse(repository.save(rule));
    }

    @Transactional
    public RuleResponse update(UUID userId, UUID id, UpdateRuleRequest req) {
        CategorizationRule rule = repository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new NotFoundException("Правило не найдено"));
        requireOwnVisibleCategory(userId, req.categoryId());
        if (!rule.getKeyword().equalsIgnoreCase(req.keyword())
                && repository.existsByUserIdAndKeywordIgnoreCase(userId, req.keyword())) {
            throw new ConflictException("Правило с таким ключевым словом уже есть");
        }
        rule.setKeyword(req.keyword());
        rule.setCategoryId(req.categoryId());
        return toResponse(repository.save(rule));
    }

    @Transactional
    public void delete(UUID userId, UUID id) {
        CategorizationRule rule = repository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new NotFoundException("Правило не найдено"));
        repository.delete(rule);
    }

    @Transactional(readOnly = true)
    public Optional<UUID> resolve(UUID userId, String note, CategoryType type) {
        if (note == null || note.isBlank()) {
            return Optional.empty();
        }
        String lower = note.toLowerCase();
        return repository.findForMatching(userId, type).stream()
                .filter(r -> lower.contains(r.getKeyword().toLowerCase()))
                .map(CategorizationRule::getCategoryId)
                .findFirst();
    }

    private void requireOwnVisibleCategory(UUID userId, UUID categoryId) {
        categoryRepository.findVisibleByIdPersonal(categoryId, userId)
                .orElseThrow(() -> new NotFoundException("Категория не найдена"));
    }

    private RuleResponse toResponse(CategorizationRule rule) {
        String name = categoryRepository.findById(rule.getCategoryId())
                .map(Category::getName).orElse("—");
        return new RuleResponse(rule.getId(), rule.getKeyword(), rule.getCategoryId(), name);
    }
}
