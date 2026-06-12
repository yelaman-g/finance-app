package com.aifb.platform.auth.service.google;

import com.aifb.platform.common.exception.UnauthorizedException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import java.nio.charset.StandardCharsets;
import java.util.Base64;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class DevGoogleTokenVerifierTest {

    private final DevGoogleTokenVerifier verifier =
            new DevGoogleTokenVerifier(new ObjectMapper());

    private String token(String json) {
        return "dev." + Base64.getUrlEncoder().withoutPadding()
                .encodeToString(json.getBytes(StandardCharsets.UTF_8));
    }

    @Test
    void parsesValidDevToken() {
        GoogleIdentity id = verifier.verify(token(
                "{\"sub\":\"g-1\",\"email\":\"a@gmail.com\",\"name\":\"Alice\","
                        + "\"picture\":\"http://x/p.png\",\"email_verified\":true}"));
        assertThat(id.subject()).isEqualTo("g-1");
        assertThat(id.email()).isEqualTo("a@gmail.com");
        assertThat(id.fullName()).isEqualTo("Alice");
        assertThat(id.pictureUrl()).isEqualTo("http://x/p.png");
        assertThat(id.emailVerified()).isTrue();
    }

    @Test
    void emailVerifiedDefaultsTrueWhenMissing() {
        GoogleIdentity id = verifier.verify(token(
                "{\"sub\":\"g-2\",\"email\":\"b@gmail.com\"}"));
        assertThat(id.emailVerified()).isTrue();
    }

    @Test
    void rejectsTokenWithoutPrefix() {
        assertThatThrownBy(() -> verifier.verify("not-a-dev-token"))
                .isInstanceOf(UnauthorizedException.class);
    }

    @Test
    void rejectsMalformedPayload() {
        assertThatThrownBy(() -> verifier.verify("dev.@@@notbase64@@@"))
                .isInstanceOf(UnauthorizedException.class);
    }

    @Test
    void rejectsMissingSubOrEmail() {
        assertThatThrownBy(() -> verifier.verify(token("{\"email\":\"c@gmail.com\"}")))
                .isInstanceOf(UnauthorizedException.class);
    }

    @Test
    void rejectsNullToken() {
        assertThatThrownBy(() -> verifier.verify(null))
                .isInstanceOf(UnauthorizedException.class);
    }
}
