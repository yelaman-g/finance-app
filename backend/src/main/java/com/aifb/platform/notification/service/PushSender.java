package com.aifb.platform.notification.service;

import java.util.Map;

public interface PushSender {
    /** Отправить одно уведомление на один токен. */
    PushResult send(String token, String title, String body, Map<String, String> data);
}
