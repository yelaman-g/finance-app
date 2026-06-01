package com.aifb.platform.finance.transaction.domain;

import com.aifb.platform.common.persistence.BaseEntity;
import com.aifb.platform.finance.category.domain.CategoryType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "transactions")
public class Transaction extends BaseEntity {

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "category_id", nullable = false)
    private UUID categoryId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private CategoryType type;

    @Column(nullable = false, precision = 15, scale = 2)
    private BigDecimal amount;

    @Column(length = 255)
    private String note;

    @Column(name = "occurred_on", nullable = false)
    private LocalDate occurredOn;

    protected Transaction() {
    }

    public Transaction(UUID userId, UUID categoryId, CategoryType type,
                       BigDecimal amount, String note, LocalDate occurredOn) {
        this.id = UUID.randomUUID();
        this.userId = userId;
        this.categoryId = categoryId;
        this.type = type;
        this.amount = amount;
        this.note = note;
        this.occurredOn = occurredOn;
    }

    public UUID getUserId() { return userId; }
    public UUID getCategoryId() { return categoryId; }
    public CategoryType getType() { return type; }
    public BigDecimal getAmount() { return amount; }
    public String getNote() { return note; }
    public LocalDate getOccurredOn() { return occurredOn; }

    public void setCategoryId(UUID categoryId) { this.categoryId = categoryId; }
    public void setType(CategoryType type) { this.type = type; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }
    public void setNote(String note) { this.note = note; }
    public void setOccurredOn(LocalDate occurredOn) { this.occurredOn = occurredOn; }
}
