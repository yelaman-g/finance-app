package com.aifb.platform.notification.service;

import com.aifb.platform.auth.domain.User;
import com.aifb.platform.auth.repository.UserRepository;
import com.aifb.platform.notification.domain.DevicePlatform;
import com.aifb.platform.notification.domain.DeviceToken;
import com.aifb.platform.notification.domain.SentNotification;
import com.aifb.platform.notification.repository.DeviceTokenRepository;
import com.aifb.platform.notification.repository.SentNotificationRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class NotificationService {

    private static final Logger log = LoggerFactory.getLogger(NotificationService.class);

    private final DeviceTokenRepository tokens;
    private final SentNotificationRepository sent;
    private final UserRepository users;
    private final PushSender pushSender;

    public NotificationService(DeviceTokenRepository tokens, SentNotificationRepository sent,
                               UserRepository users, PushSender pushSender) {
        this.tokens = tokens;
        this.sent = sent;
        this.users = users;
        this.pushSender = pushSender;
    }

    /** Регистрация/переустановка device-токена (upsert по token). */
    @Transactional
    public void registerToken(UUID userId, String token, DevicePlatform platform) {
        tokens.findByToken(token).ifPresentOrElse(
                existing -> existing.reassign(userId, platform),
                () -> tokens.save(new DeviceToken(userId, token, platform)));
    }

    /** Снятие токена (logout/opt-out). Идемпотентно. */
    @Transactional
    public void removeToken(UUID userId, String token) {
        tokens.findByToken(token)
                .filter(t -> t.getUserId().equals(userId))
                .ifPresent(tokens::delete);
    }

    /** Доставка одного кандидата с дедупом и фан-аутом на семью. */
    @Transactional
    public void deliver(NotificationCandidate c) {
        boolean already = sent.existsBySourceTypeAndSourceIdAndOccurrenceDateAndThresholdDay(
                c.sourceType(), c.sourceId(), c.occurrenceDate(), c.thresholdDay());
        if (already) {
            return;
        }
        List<UUID> recipients = recipients(c);
        List<DeviceToken> deviceTokens = recipients.isEmpty()
                ? List.of() : tokens.findByUserIdIn(recipients);
        Map<String, String> data = Map.of(
                "type", c.sourceType().name(), "id", c.sourceId().toString());
        for (DeviceToken dt : deviceTokens) {
            PushResult r = pushSender.send(dt.getToken(), c.title(), c.body(), data);
            if (r.tokenInvalid()) {
                tokens.delete(dt);
            }
        }
        try {
            sent.save(new SentNotification(c.ownerUserId(), c.sourceType(),
                    c.sourceId(), c.occurrenceDate(), c.thresholdDay()));
        } catch (DataIntegrityViolationException race) {
            log.debug("sent_notifications гонка — уже отправлено: {}", c.sourceId());
        }
    }

    private List<UUID> recipients(NotificationCandidate c) {
        if (c.householdId() == null) {
            return List.of(c.ownerUserId());
        }
        return users.findByHouseholdId(c.householdId()).stream().map(User::getId).toList();
    }
}
