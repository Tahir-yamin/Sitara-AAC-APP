# ─── Stage 1: Build Flutter Web ──────────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:3.41.0 AS build

WORKDIR /app

# Install dependencies separately to leverage Docker cache
COPY pubspec.yaml .
RUN flutter pub get

# Copy source and build
COPY . .
RUN flutter build web --release

# ─── Stage 2: Serve with nginx ───────────────────────────────────────────────
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
