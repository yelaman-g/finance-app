package com.aifb.platform.notification.domain;

import com.aifb.platform.common.persistence.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;

import java.util.UUID;

@Entity
@Table(name = "device_tokens")
public class DeviceToken extends BaseEntity {

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(nullable = false, length = 512, unique = true)
    private String token;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private DevicePlatform platform = DevicePlatform.ANDROID;

    protected DeviceToken() {}

    public DeviceToken(UUID userId, String token, DevicePlatform platform) {
        this.id = UUID.randomUUID();
        this.userId = userId;
        this.token = token;
        this.platform = platform == null ? DevicePlatform.ANDROID : platform;
    }

    public UUID getUserId() { return userId; }
    public String getToken() { return token; }
    public DevicePlatform getPlatform() { return platform; }

    public void reassign(UUID userId, DevicePlatform platform) {
        this.userId = userId;
        this.platform = platform == null ? DevicePlatform.ANDROID : platform;
    }
}
