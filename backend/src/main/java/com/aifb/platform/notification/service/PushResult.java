package com.aifb.platform.notification.service;

/** accepted — доставлено/принято FCM; tokenInvalid — токен протух, удалить. */
public record PushResult(boolean accepted, boolean tokenInvalid) {
    public static PushResult ok() { return new PushResult(true, false); }
    public static PushResult invalidToken() { return new PushResult(false, true); }
    public static PushResult failed() { return new PushResult(false, false); }
}
