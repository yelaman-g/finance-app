package com.aifb.platform.auth.service.google;

public interface GoogleTokenVerifier {
    GoogleIdentity verify(String idToken);
}
