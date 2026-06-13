package com.aifb.platform.notification.service;

import com.aifb.platform.finance.transaction.event.SharedExpenseCreatedEvent;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/** Шлёт push о новом семейном расходе ПОСЛЕ коммита создания операции. */
@Component
public class ExpenseNotificationListener {

    private final NotificationService notifications;

    public ExpenseNotificationListener(NotificationService notifications) {
        this.notifications = notifications;
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onSharedExpense(SharedExpenseCreatedEvent e) {
        notifications.notifyFamilyExpense(e.householdId(), e.authorUserId(),
                e.transactionId(), e.amount(), e.note());
    }
}
