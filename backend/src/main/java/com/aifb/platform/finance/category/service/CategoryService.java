package com.aifb.platform.finance.category.service;

import com.aifb.platform.common.exception.ConflictException;
import com.aifb.platform.common.exception.ForbiddenException;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.finance.category.api.dto.CategoryResponse;
import com.aifb.platform.finance.category.api.dto.CreateCategoryRequest;
import com.aifb.platform.finance.category.api.dto.UpdateCategoryRequest;
import com.aifb.platform.finance.category.domain.Category;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.repository.CategoryRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
public class CategoryService {

    private final CategoryRepository repository;

    public CategoryService(CategoryRepository repository) {
        this.repository = repository;
    }

    @Transactional(readOnly = true)
    public List<CategoryResponse> list(UUID userId, CategoryType type) {
        return repository.findVisible(userId, type).stream()
                .map(CategoryResponse::from)
                .toList();
    }

    @Transactional
    public CategoryResponse create(UUID userId, CreateCategoryRequest req) {
        if (repository.existsByUserIdAndTypeAndNameIgnoreCaseAndDeletedAtIsNull(
                userId, req.type(), req.name())) {
            throw new ConflictException("Категория с таким именем уже существует");
        }
        Category category = new Category(userId, req.name(), req.type(), req.icon(), req.color());
        return CategoryResponse.from(repository.save(category));
    }

    @Transactional
    public CategoryResponse update(UUID userId, UUID id, UpdateCategoryRequest req) {
        Category category = ownedCategory(userId, id);
        category.setName(req.name());
        category.setIcon(req.icon());
        category.setColor(req.color());
        return CategoryResponse.from(repository.save(category));
    }

    @Transactional
    public void delete(UUID userId, UUID id) {
        Category category = ownedCategory(userId, id);
        category.softDelete(Instant.now());
        repository.save(category);
    }

    private Category ownedCategory(UUID userId, UUID id) {
        Category category = repository.findById(id)
                .filter(c -> !c.isDeleted())
                .orElseThrow(() -> new NotFoundException("Категория не найдена"));
        if (category.isSystem()) {
            throw new ForbiddenException("Системные категории нельзя изменять");
        }
        if (!userId.equals(category.getUserId())) {
            throw new NotFoundException("Категория не найдена");
        }
        return category;
    }
}
