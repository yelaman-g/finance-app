package com.aifb.platform.auth.service.google;

import com.aifb.platform.common.exception.ErrorCode;
import com.aifb.platform.common.exception.UnauthorizedException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.nio.charset.StandardCharsets;
import java.util.Base64;

/**
 * Принимает неподписанный токен вида {@code dev.<base64url(JSON)>} без обращения
 * к сети. Аналог dev-кода восстановления пароля: удобно для тестов и демо без
 * реального Google-проекта. ДОЛЖЕН быть выключен в продакшне (GOOGLE_DEV_MODE=false).
 */
public class DevGoogleTokenVerifier implements GoogleTokenVerifier {

    private static final String PREFIX = "dev.";
    private final ObjectMapper objectMapper;

    public DevGoogleTokenVerifier(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    @Override
    public GoogleIdentity verify(String idToken) {
        if (idToken == null || !idToken.startsWith(PREFIX)) {
            throw invalid();
        }
        try {
            byte[] decoded = Base64.getUrlDecoder().decode(idToken.substring(PREFIX.length()));
            // readTree → raw JsonNode (no POJO mapping), so FAIL_ON_UNKNOWN_PROPERTIES does not apply
            JsonNode node = objectMapper.readTree(new String(decoded, StandardCharsets.UTF_8));
            String sub = text(node, "sub");
            String email = text(node, "email");
            if (sub == null || email == null) {
                throw invalid();
            }
            boolean emailVerified = !node.has("email_verified")
                    || node.get("email_verified").asBoolean(true);
            return new GoogleIdentity(sub, email, emailVerified, text(node, "name"), text(node, "picture"));
        } catch (UnauthorizedException e) {
            throw e;
        } catch (Exception e) {
            throw invalid();
        }
    }

    private static String text(JsonNode node, String field) {
        JsonNode v = node.get(field);
        return v == null || v.isNull() ? null : v.asText();
    }

    private static UnauthorizedException invalid() {
        return new UnauthorizedException(ErrorCode.AUTH_GOOGLE_TOKEN_INVALID, "Invalid Google token");
    }
}
