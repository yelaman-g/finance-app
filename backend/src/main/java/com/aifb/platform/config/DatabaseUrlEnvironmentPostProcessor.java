package com.aifb.platform.config;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.env.EnvironmentPostProcessor;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.MapPropertySource;

import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;

/**
 * Поддержка Railway/Heroku-стиля переменной {@code DATABASE_URL}
 * ({@code postgres(ql)://user:pass@host:port/db?params}), которую Spring напрямую не понимает.
 *
 * <p>Если задан {@code DATABASE_URL} и НЕ задан явный {@code DB_URL}, разбирает URL и
 * выставляет {@code spring.datasource.url/username/password} с наивысшим приоритетом — тогда
 * на Railway достаточно одной переменной-ссылки {@code DATABASE_URL=${{Postgres.DATABASE_URL}}}
 * вместо ручного маппинга трёх ({@code DB_URL/DB_USER/DB_PASSWORD}).
 *
 * <p>Явный {@code DB_URL} (путь из application.yml) всегда приоритетнее. Если URL не удаётся
 * разобрать (нет host) — процессор НЕ активируется (оставляет дефолты), чтобы не создавать
 * заведомо битый JDBC-URL.
 *
 * <p>Разбор ручной (а не {@link java.net.URI}), т.к. URI ломается, когда пароль содержит
 * {@code @}/{@code :}; здесь граница userinfo берётся по последнему {@code @}, а сам
 * user/password дополнительно URL-декодируется.
 */
public class DatabaseUrlEnvironmentPostProcessor implements EnvironmentPostProcessor {

    @Override
    public void postProcessEnvironment(ConfigurableEnvironment environment, SpringApplication application) {
        String databaseUrl = environment.getProperty("DATABASE_URL");
        if (databaseUrl == null || databaseUrl.isBlank()) {
            return;
        }
        String explicitDbUrl = environment.getProperty("DB_URL");
        if (explicitDbUrl != null && !explicitDbUrl.isBlank()) {
            return; // 3-переменный путь имеет приоритет
        }
        int schemeIdx = databaseUrl.indexOf("://");
        if (schemeIdx < 0) {
            return;
        }
        String scheme = databaseUrl.substring(0, schemeIdx);
        if (!scheme.equals("postgres") && !scheme.equals("postgresql")) {
            return;
        }

        String rest = databaseUrl.substring(schemeIdx + 3); // user:pass@host:port/db?params
        String userInfo = null;
        String authorityAndPath = rest;
        int at = rest.lastIndexOf('@'); // последний '@' — граница перед host (пароль может содержать '@')
        if (at >= 0) {
            userInfo = rest.substring(0, at);
            authorityAndPath = rest.substring(at + 1);
        }

        String hostPort = authorityAndPath;
        String pathAndQuery = "";
        int slash = authorityAndPath.indexOf('/');
        if (slash >= 0) {
            hostPort = authorityAndPath.substring(0, slash);
            pathAndQuery = authorityAndPath.substring(slash); // включает ведущий '/'
        }
        if (hostPort.isBlank() || hostPort.startsWith(":")) {
            // host не определить — не активируемся, чтобы не создать битый URL
            System.err.println("[DatabaseUrl] не удалось определить host в DATABASE_URL — пропуск");
            return;
        }

        Map<String, Object> props = new HashMap<>();
        props.put("spring.datasource.url", "jdbc:postgresql://" + hostPort + pathAndQuery);
        if (userInfo != null && !userInfo.isBlank()) {
            int colon = userInfo.indexOf(':');
            String user = colon >= 0 ? userInfo.substring(0, colon) : userInfo;
            String pass = colon >= 0 ? userInfo.substring(colon + 1) : "";
            props.put("spring.datasource.username", URLDecoder.decode(user, StandardCharsets.UTF_8));
            props.put("spring.datasource.password", URLDecoder.decode(pass, StandardCharsets.UTF_8));
        }
        environment.getPropertySources().addFirst(new MapPropertySource("railwayDatabaseUrl", props));
    }
}
