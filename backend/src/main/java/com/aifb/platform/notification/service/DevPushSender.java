package com.aifb.platform.notification.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Dev-режим: логирует «отправку» и накапливает её для тестов. Без сети и кредов.
 */
public class DevPushSender implements PushSender {

    private static final Logger log = LoggerFactory.getLogger(DevPushSender.class);

    public record Sent(String token, String title, String body) {}

    private final List<Sent> sentLog = new ArrayList<>();

    @Override
    public synchronized PushResult send(String token, String title, String body, Map<String, String> data) {
        sentLog.add(new Sent(token, title, body));
        log.info("[FCM-DEV] → token={} title={} body={}", token, title, body);
        return PushResult.ok();
    }

    /** Для тестов: все «отправленные» уведомления. */
    public synchronized List<Sent> sent() { return List.copyOf(sentLog); }
}
