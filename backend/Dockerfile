FROM gradle:8.10.2-jdk17 AS build
WORKDIR /app
COPY . /app
RUN gradle :backend:installDist --no-daemon

FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=build /app/backend/build/install/backend /app/backend
ENV PORT=8080
EXPOSE 8080
CMD ["/app/backend/bin/backend"]
