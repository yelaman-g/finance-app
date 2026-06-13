# syntax=docker/dockerfile:1
# Деплой Spring Boot-бэкенда (каталог backend/) для Railway/любого PaaS.
# Контекст сборки — КОРЕНЬ репозитория (монорепо backend/ + frontend/), поэтому
# Root Directory в Railway менять НЕ нужно — этот Dockerfile в корне Railway найдёт сам.

# --- этап сборки ---
FROM eclipse-temurin:21-jdk AS build
WORKDIR /app

# Сначала только то, что влияет на разрешение зависимостей — для кэша слоёв.
COPY backend/gradlew backend/settings.gradle backend/build.gradle ./
COPY backend/gradle ./gradle
RUN chmod +x gradlew && ./gradlew --no-daemon dependencies > /dev/null 2>&1 || true

# Затем исходники и сборка исполняемого jar (тесты пропускаем — БД в сборке нет).
COPY backend/src ./src
RUN ./gradlew --no-daemon clean bootJar -x test

# bootJar кладёт исполняемый jar в build/libs; берём его (исключая *-plain.jar, если есть).
RUN cp "$(ls build/libs/*.jar | grep -v -- '-plain' | head -1)" /app/app.jar

# --- этап запуска ---
FROM eclipse-temurin:21-jre AS run
WORKDIR /app

# Непривилегированный пользователь.
RUN useradd -r -u 1001 spring
USER spring

COPY --from=build /app/app.jar /app/app.jar

# Railway маршрутизирует на $PORT (Spring читает его из application.yml).
EXPOSE 9090

ENTRYPOINT ["java","-XX:MaxRAMPercentage=75.0","-jar","/app/app.jar"]
