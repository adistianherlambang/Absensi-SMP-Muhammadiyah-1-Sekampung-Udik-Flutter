FROM ubuntu:22.04

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install essential dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    openjdk-17-jdk \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Set Flutter environment variables
ENV FLUTTER_HOME=/sdks/flutter
ENV PATH="${FLUTTER_HOME}/bin:${FLUTTER_HOME}/bin/cache/dart-sdk/bin:${PATH}"

# Clone Flutter 3.35.4
RUN git clone -b 3.35.4 --depth 1 https://github.com/flutter/flutter.git ${FLUTTER_HOME}

# Pre-download dependencies and run flutter doctor
RUN flutter config --no-analytics \
    && flutter doctor

WORKDIR /app

CMD ["flutter", "--version"]
