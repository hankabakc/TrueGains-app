# Build stage
FROM eclipse-temurin:25-jdk AS build
WORKDIR /app
COPY . .
RUN ./mvnw clean package -DskipTests

# Run stage
FROM eclipse-temurin:25-jre
# Sağlık kontrolü (docker-compose.yml → backend.healthcheck) curl ile yapılır. JRE imajında ne
# curl ne wget var; kontrol bu yüzden konteyner kurulduğundan beri hiç geçmiyordu.
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
# Uygulama 8082'de dinliyor (application.properties: server.port=8082). Burada 8080
# yazıyordu; EXPOSE yalnızca belge niteliğinde olduğu için sessizce yanlış kalmıştı.
EXPOSE 8082
ENTRYPOINT ["java", "-jar", "app.jar"]
