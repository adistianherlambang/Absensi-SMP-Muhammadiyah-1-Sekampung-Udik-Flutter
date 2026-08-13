#!/usr/bin/env bash
set -e

COMMAND=${1:-"version"}

case "$COMMAND" in
  build-image)
    echo "Building Docker image with Flutter 3.35.4..."
    docker compose build
    ;;
  version)
    docker compose run --rm flutter-app flutter --version
    ;;
  pub-get)
    docker compose run --rm flutter-app flutter pub get
    ;;
  test)
    docker compose run --rm flutter-app flutter test
    ;;
  build-web)
    docker compose run --rm flutter-app flutter build web
    ;;
  build-apk)
    docker compose run --rm flutter-app flutter build apk
    ;;
  run-web)
    echo "Starting Flutter web dev server on http://localhost:8080..."
    docker compose run --rm -p 8080:8080 flutter-app flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0
    ;;
  bash|shell)
    docker compose run --rm flutter-app bash
    ;;
  *)
    docker compose run --rm flutter-app flutter "$@"
    ;;
esac
