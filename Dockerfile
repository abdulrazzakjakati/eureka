
# Stage 1: Builder
# Use Maven image with JDK 17 to build the application
FROM maven:3.9.6-eclipse-temurin-17 AS builder
# Set working directory
WORKDIR /build
# Copy source code and pom.xml
COPY pom.xml .
# Copy source files
COPY src ./src
# Build the application and skip tests
RUN mvn clean package -DskipTests

# Stage 2: Runtime
# Use a lightweight JRE image
FROM eclipse-temurin:17-jre
# Set working directory
WORKDIR /app

# Use non-root user (DEBIAN SYNTAX - fixed!)
RUN groupadd -r appgroup && \
    useradd --no-log-init -r -g appgroup appuser && \
    mkdir -p /app && \
    chown -R appuser:appgroup /app

# Copy the built jar from the builder stage (before USER switch)
COPY --from=builder /build/target/*.jar app.jar
RUN chown appuser:appgroup /app/app.jar

# Switch to non-root user
USER appuser

# Expose application port
EXPOSE 8761

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:8761/actuator/health || exit 1

# Define the entry point for the container
ENTRYPOINT ["java", "-jar", "app.jar"]
