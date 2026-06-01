package com.aifb.platform.auth.domain;

import com.aifb.platform.common.domain.Currency;
import com.aifb.platform.common.persistence.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;

import java.util.UUID;

@Entity
@Table(name = "user_settings")
public class UserSettings extends BaseEntity {

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(name = "currency", nullable = false, length = 3)
    private Currency currency;

    @Column(name = "theme", nullable = false, length = 10)
    private String theme;

    protected UserSettings() {
    }

    public UserSettings(User user) {
        this.id = UUID.randomUUID();
        this.user = user;
        this.currency = Currency.KZT;
        this.theme = "light";
    }

    public User getUser() { return user; }
    public Currency getCurrency() { return currency; }
    public String getTheme() { return theme; }

    public void setCurrency(Currency currency) { this.currency = currency; }
    public void setTheme(String theme) { this.theme = theme; }
}
