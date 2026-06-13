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

import java.math.BigDecimal;
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
            // Строка пишется даже если нуль отправок (нет токенов): ключ дедупа — (source, occurrence_date, threshold),
            // поэтому будущие пороги сработают; прошедший порог повторно не отправляется — это намеренно.
            sent.save(new SentNotification(c.ownerUserId(), c.sourceType(),
                    c.sourceId(), c.occurrenceDate(), c.thresholdDay()));
        } catch (DataIntegrityViolationException race) {
            log.debug("sent_notifications гонка — уже отправлено: {}", c.sourceId());
        }
    }

    /** Немедленный push о новом семейном расходе всем членам семьи, КРОМЕ автора. Без дедупа.
     *  Не @Transactional: FCM-отправка (I/O) не должна держать DB-соединение; невалидные токены
     *  удаляются одним deleteAll после цикла (репозиторный метод сам транзакционен). */
    public void notifyFamilyExpense(UUID householdId, UUID authorUserId, UUID transactionId,
                                    BigDecimal amount, String note) {
        if (householdId == null) {
            return;
        }
        List<UUID> recipients = users.findByHouseholdId(householdId).stream()
                .map(User::getId)
                .filter(id -> !id.equals(authorUserId))
                .toList();
        if (recipients.isEmpty()) {
            return;
        }
        List<DeviceToken> deviceTokens = tokens.findByUserIdIn(recipients);
        String body = (note == null || note.isBlank())
                ? money(amount) + " ₸"
                : money(amount) + " ₸ — " + note;
        Map<String, String> data = Map.of("type", "EXPENSE", "transactionId", transactionId.toString());
        java.util.List<DeviceToken> invalid = new java.util.ArrayList<>();
        for (DeviceToken dt : deviceTokens) {
            PushResult r = pushSender.send(dt.getToken(), "Новый семейный расход", body, data);
            if (r.tokenInvalid()) {
                invalid.add(dt);
            }
        }
        if (!invalid.isEmpty()) {
            tokens.deleteAll(invalid);
        }
    }

    private static String money(BigDecimal a) {
        BigDecimal s = a.stripTrailingZeros();
        if (s.scale() < 0) {
            s = s.setScale(0);
        }
        return s.toPlainString();
    }

    private List<UUID> recipients(NotificationCandidate c) {
        if (c.householdId() == null) {
            return List.of(c.ownerUserId());
        }
        java.util.LinkedHashSet<UUID> ids = new java.util.LinkedHashSet<>();
        ids.add(c.ownerUserId());
        users.findByHouseholdId(c.householdId()).forEach(u -> ids.add(u.getId()));
        return new java.util.ArrayList<>(ids);
    }
}
