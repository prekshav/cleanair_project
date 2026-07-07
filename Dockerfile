# ==========================================
# STAGE 1: Compile the Flutter Web Frontend
# ==========================================
FROM debian:bookworm-slim AS build-env

# Install base system dependencies required by the Flutter SDK compiler
RUN apt-get update && apt-get install -y \
    curl git unzip xz-utils zip libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Clone a stable release branch of the Flutter SDK repository
RUN git clone https://github.com/flutter/flutter.git -b stable /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Pre-download development tools and print diagnostic validation
RUN flutter doctor -v

# Set working directory context and pull in the frontend codebase
WORKDIR /build
COPY cleanair_dashboard/ .

# Fetch application packages and compile to optimized web assets
RUN flutter pub get
RUN flutter build web --release

# ==========================================
# STAGE 2: Assemble the Final Runtime Image
# ==========================================
FROM python:3.11-slim

WORKDIR /app

# Copy python dependencies layout to leverage layer caching optimization
COPY cleanair-backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of your backend framework application logic
COPY cleanair-backend/ .

# Extract the static web output straight from your frontend build environment
COPY --from=build-env /build/build/web ./static

# Cloud Run binds to a dynamic $PORT environment variable at execution runtime
ENV PORT=8080
EXPOSE 8080

# Spin up webserver using shell invocation string to dynamically evaluate environment assignments
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port $PORT"]