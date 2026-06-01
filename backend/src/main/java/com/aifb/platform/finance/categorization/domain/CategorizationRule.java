package com.aifb.platform.finance.categorization.domain;

import com.aifb.platform.common.persistence.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

import java.util.UUID;

@Entity
@Table(name = "categorization_rules")
public class CategorizationRule extends BaseEntity {

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(nullable = false, length = 80)
    private String keyword;

    @Column(name = "category_id", nullable = false)
    private UUID categoryId;

    protected CategorizationRule() {
    }

    public CategorizationRule(UUID userId, String keyword, UUID categoryId) {
        this.id = UUID.randomUUID();
        this.userId = userId;
        this.keyword = keyword;
        this.categoryId = categoryId;
    }

    public UUID getUserId() { return userId; }
    public String getKeyword() { return keyword; }
    public UUID getCategoryId() { return categoryId; }

    public void setKeyword(String keyword) { this.keyword = keyword; }
    public void setCategoryId(UUID categoryId) { this.categoryId = categoryId; }
}
