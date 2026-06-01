package com.aifb.platform;

import com.aifb.platform.support.AbstractIntegrationTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import com.aifb.platform.support.TestAuth;

import static org.assertj.core.api.Assertions.assertThat;

class SmokeContextIT extends AbstractIntegrationTest {

    @Autowired
    TestAuth testAuth;

    @Test
    void contextLoadsAndCanMintToken() {
        TestAuth.AuthedUser u = testAuth.createUser();
        assertThat(u.bearer()).startsWith("Bearer ");
        assertThat(u.id()).isNotNull();
    }
}
