package com.aifb.platform.finance.category.domain;

import com.aifb.platform.common.persistence.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "categories")
public class Category extends BaseEntity {

    @Column(name = "user_id")
    private UUID userId; // null => системная категория

    @Column(nullable = false, length = 80)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private CategoryType type;

    @Column(length = 40)
    private String icon;

    @Column(length = 9)
    private String color;

    @Column(name = "is_system", nullable = false)
    private boolean system;

    @Column(name = "deleted_at")
    private Instant deletedAt;

    protected Category() {
    }

    public Category(UUID userId, String name, CategoryType type, String icon, String color) {
        this.id = UUID.randomUUID();
        this.userId = userId;
        this.name = name;
        this.type = type;
        this.icon = icon;
        this.color = color;
        this.system = false;
    }

    public UUID getUserId() { return userId; }
    public String getName() { return name; }
    public CategoryType getType() { return type; }
    public String getIcon() { return icon; }
    public String getColor() { return color; }
    public boolean isSystem() { return system; }
    public Instant getDeletedAt() { return deletedAt; }
    public boolean isDeleted() { return deletedAt != null; }

    public void setName(String name) { this.name = name; }
    public void setIcon(String icon) { this.icon = icon; }
    public void setColor(String color) { this.color = color; }

    public void softDelete(Instant when) { this.deletedAt = when; }
}
