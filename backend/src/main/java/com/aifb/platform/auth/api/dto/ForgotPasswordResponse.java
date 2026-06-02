package com.aifb.platform.auth.api.dto;

import java.time.Instant;

/**
 * Ответ на запрос кода сброса. Поле {@code devCode} существует только потому,
 * что SMTP не настроен (dev-режим): код возвращается клиенту напрямую. В проде
 * код отправляется письмом, а {@code devCode}/{@code expiresAt} становятся null.
 */
public record ForgotPasswordResponse(String devCode, Instant expiresAt) {
}
