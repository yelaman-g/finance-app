package com.aifb.platform.notification.service;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.AndroidConfig;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.MessagingErrorCode;
import com.google.firebase.messaging.Notification;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.ByteArrayInputStream;
import java.io.FileInputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.Map;

/**
 * Реальная отправка через Firebase Admin SDK. Инициализируется из service-account JSON.
 * Включается только при aifb.fcm.dev-mode=false (см. FcmConfig).
 */
public class FcmPushSender implements PushSender {

    private static final Logger log = LoggerFactory.getLogger(FcmPushSender.class);
    private final FirebaseMessaging messaging;

    public FcmPushSender(String serviceAccountJson) {
        if (serviceAccountJson == null || serviceAccountJson.isBlank()) {
            throw new IllegalArgumentException(
                    "aifb.fcm.service-account-json must be set when aifb.fcm.dev-mode=false");
        }
        try {
            String v = serviceAccountJson.trim();
            InputStream in = v.startsWith("{")
                    ? new ByteArrayInputStream(v.getBytes(StandardCharsets.UTF_8))
                    : new FileInputStream(v);
            try (in) {
                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.fromStream(in))
                        .build();
                FirebaseApp app = FirebaseApp.getApps().isEmpty()
                        ? FirebaseApp.initializeApp(options) : FirebaseApp.getInstance();
                this.messaging = FirebaseMessaging.getInstance(app);
            }
        } catch (Exception e) {
            throw new IllegalStateException("Failed to initialize Firebase Admin SDK", e);
        }
    }

    @Override
    public PushResult send(String token, String title, String body, Map<String, String> data) {
        Message.Builder msg = Message.builder()
                .setToken(token)
                .setNotification(Notification.builder().setTitle(title).setBody(body).build())
                .setAndroidConfig(AndroidConfig.builder().setPriority(AndroidConfig.Priority.HIGH).build());
        if (data != null) {
            data.forEach(msg::putData);
        }
        try {
            messaging.send(msg.build());
            return PushResult.ok();
        } catch (FirebaseMessagingException e) {
            MessagingErrorCode code = e.getMessagingErrorCode();
            if (code == MessagingErrorCode.UNREGISTERED || code == MessagingErrorCode.INVALID_ARGUMENT) {
                log.warn("[FCM] невалидный токен, удаляем: {}", token);
                return PushResult.invalidToken();
            }
            log.error("[FCM] ошибка отправки на {}: {}", token, e.getMessage());
            return PushResult.failed();
        }
    }
}
