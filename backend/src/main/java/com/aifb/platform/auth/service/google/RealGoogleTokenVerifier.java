package com.aifb.platform.auth.service.google;

import com.aifb.platform.common.exception.ErrorCode;
import com.aifb.platform.common.exception.UnauthorizedException;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.googleapis.javanet.GoogleNetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;

import java.util.Collections;

/**
 * Верифицирует подпись/aud/exp Google ID-token через библиотеку google-api-client.
 * Активен при aifb.google.dev-mode=false; audience = aifb.google.client-id.
 */
public class RealGoogleTokenVerifier implements GoogleTokenVerifier {

    private final GoogleIdTokenVerifier verifier;

    public RealGoogleTokenVerifier(String clientId) {
        if (clientId == null || clientId.isBlank()) {
            throw new IllegalArgumentException(
                    "aifb.google.client-id must be set when aifb.google.dev-mode=false");
        }
        try {
            this.verifier = new GoogleIdTokenVerifier.Builder(
                    GoogleNetHttpTransport.newTrustedTransport(), GsonFactory.getDefaultInstance())
                    .setAudience(Collections.singletonList(clientId))
                    .build();
        } catch (Exception e) {
            throw new IllegalStateException("Failed to initialize Google token verifier", e);
        }
    }

    @Override
    public GoogleIdentity verify(String idToken) {
        try {
            GoogleIdToken token = verifier.verify(idToken);
            if (token == null) {
                throw invalid();
            }
            GoogleIdToken.Payload p = token.getPayload();
            return new GoogleIdentity(
                    p.getSubject(),
                    p.getEmail(),
                    Boolean.TRUE.equals(p.getEmailVerified()),
                    (String) p.get("name"),
                    (String) p.get("picture"));
        } catch (UnauthorizedException e) {
            throw e;
        } catch (Exception e) {
            throw invalid();
        }
    }

    private static UnauthorizedException invalid() {
        return new UnauthorizedException(ErrorCode.AUTH_GOOGLE_TOKEN_INVALID, "Invalid Google token");
    }
}
