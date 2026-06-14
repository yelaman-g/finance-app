package com.aifb.platform.finance.budget.service;

import com.aifb.platform.auth.domain.User;
import com.aifb.platform.auth.repository.UserRepository;
import com.aifb.platform.finance.budget.domain.BudgetLimit;
import com.aifb.platform.finance.budget.domain.BudgetTargetType;
import com.aifb.platform.finance.budget.repository.BudgetLimitRepository;
import com.aifb.platform.finance.category.domain.Category;
import com.aifb.platform.finance.category.repository.CategoryRepository;
import com.aifb.platform.finance.group.domain.CategoryGroup;
import com.aifb.platform.finance.group.repository.CategoryGroupRepository;
import com.aifb.platform.finance.transaction.event.ExpenseRecordedEvent;
import com.aifb.platform.notification.domain.NotificationSource;
import com.aifb.platform.notification.domain.SentNotification;
import com.aifb.platform.notification.repository.SentNotificationRepository;
import com.aifb.platform.notification.service.NotificationService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Clock;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * После коммита создания расхода проверяет затронутые лимиты и шлёт push при подходе к лимиту
 * (когда трата впервые в этом месяце достигает {@code notify_threshold_percent}).
 * Дедуп — раз в календарный месяц на лимит (через {@code sent_notifications}, source=BUDGET).
 * Личный лимит → push владельцу; семейный → всем членам семьи.
 */
@Service
public class BudgetAlertService {

    private static final Logger log = LoggerFactory.getLogger(BudgetAlertService.class);

    private final BudgetLimitRepository limits;
    private final BudgetService budgetService;
    private final CategoryRepository categoryRepository;
    private final CategoryGroupRepository groupRepository;
    private final NotificationService notifications;
    private final SentNotificationRepository sent;
    private final UserRepository users;
    private final Clock clock;

    public BudgetAlertService(BudgetLimitRepository limits, BudgetService budgetService,
                              CategoryRepository categoryRepository, CategoryGroupRepository groupRepository,
                              NotificationService notifications, SentNotificationRepository sent,
                              UserRepository users, Clock clock) {
        this.limits = limits;
        this.budgetService = budgetService;
        this.categoryRepository = categoryRepository;
        this.groupRepository = groupRepository;
        this.notifications = notifications;
        this.sent = sent;
        this.users = users;
        this.clock = clock;
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void onExpense(ExpenseRecordedEvent e) {
        UUID groupId = categoryRepository.findById(e.categoryId()).map(Category::getGroupId).orElse(null);
        List<BudgetLimit> affected = new ArrayList<>();
        limits.findByCategoryIdAndUserIdAndHouseholdIdIsNull(e.categoryId(), e.userId()).ifPresent(affected::add);
        if (groupId != null) {
            limits.findByGroupIdAndUserIdAndHouseholdIdIsNull(groupId, e.userId()).ifPresent(affected::add);
        }
        if (e.householdId() != null) {
            limits.findByCategoryIdAndHouseholdId(e.categoryId(), e.householdId()).ifPresent(affected::add);
            if (groupId != null) {
                limits.findByGroupIdAndHouseholdId(groupId, e.householdId()).ifPresent(affected::add);
            }
        }
        for (BudgetLimit limit : affected) {
            checkLimit(limit);
        }
    }

    private void checkLimit(BudgetLimit limit) {
        BigDecimal spent = budgetService.currentSpending(limit);
        int threshold = limit.getNotifyThresholdPercent();
        // spent/amount >= threshold/100  ⇔  spent*100 >= amount*threshold
        boolean crossed = spent.multiply(BigDecimal.valueOf(100))
                .compareTo(limit.getAmount().multiply(BigDecimal.valueOf(threshold))) >= 0;
        if (!crossed) {
            return;
        }
        LocalDate monthStart = LocalDate.now(clock).withDayOfMonth(1);
        if (sent.existsBySourceTypeAndSourceIdAndOccurrenceDateAndThresholdDay(
                NotificationSource.BUDGET, limit.getId(), monthStart, threshold)) {
            return;
        }
        List<UUID> recipients = limit.isShared()
                ? users.findByHouseholdId(limit.getHouseholdId()).stream().map(User::getId).toList()
                : List.of(limit.getUserId());
        int spentPct = spent.multiply(BigDecimal.valueOf(100))
                .divide(limit.getAmount(), 0, RoundingMode.HALF_UP).intValue();
        String body = targetName(limit) + ": потрачено " + spentPct + "% ("
                + money(spent) + " из " + money(limit.getAmount()) + " ₸)";
        notifications.pushToUsers(recipients, "Лимит почти исчерпан", body,
                Map.of("type", "BUDGET", "id", limit.getId().toString()));
        try {
            sent.save(new SentNotification(limit.getUserId(), NotificationSource.BUDGET,
                    limit.getId(), monthStart, threshold));
        } catch (DataIntegrityViolationException race) {
            log.debug("budget alert гонка — уже отправлено: {}", limit.getId());
        }
    }

    private String targetName(BudgetLimit limit) {
        if (limit.getTargetType() == BudgetTargetType.CATEGORY) {
            return categoryRepository.findById(limit.getCategoryId())
                    .map(Category::getName).orElse("Категория");
        }
        return groupRepository.findById(limit.getGroupId())
                .map(CategoryGroup::getName).orElse("Группа");
    }

    private static String money(BigDecimal a) {
        BigDecimal s = a.stripTrailingZeros();
        if (s.scale() < 0) {
            s = s.setScale(0);
        }
        return s.toPlainString();
    }
}
