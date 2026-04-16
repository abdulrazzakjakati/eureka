# --- STAGE 1: Build JAR natively (fast) ---
FROM --platform=$BUILDPLATFORM maven:3.9.6-eclipse-temurin-17 AS builder
WORKDIR /build

# Cache dependencies
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Compile code
COPY src ./src
RUN mvn clean package -DskipTests

# --- STAGE 2: Multi-arch Runtime ---
FROM eclipse-temurin:17-jre
WORKDIR /app

# Alpine uses 'addgroup' and 'adduser'
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy JAR from builder
COPY --from=builder /build/target/*.jar app.jar
RUN chown appuser:appgroup /app/app.jar

USER appuser
EXPOSE 8761

# Healthcheck (Note: Alpine needs 'wget' or 'curl' installed to work)
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:8761/actuator/health || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]