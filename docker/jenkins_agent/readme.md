# Docker Flutter Image for Jenkins Agent

## Bau des Image

```bash
docker build . -t falconone/jenkins-flutter:latest
```

## Push des Image

```bash
docker push falconone/jenkins-flutter:latest
```

## Tagging des Image

```bash
docker image tag 7318d73a9573 falconone/jenkins-flutter:latest
```

### Download des Flutter Krams

```bash
# Start des Containers
docker run -it falconone:jenkins-flutter /bin/bash

# Download des Repositorys
git clone https://github.com/RegNex/shopping_app_ui.git
cd shopping_app_ui

# Kompilieren des Android Bundles
flutter build appbundle

# Resultiert in der Datei: build/app/outputs/bundle/release/app-release.aab
```

Funktioniert leider nur für Android!

#### Bau einer iOS App

```bash
# Kompilieren des iOS Bundles (nur MacOS)
flutter build ios
```

## Tests

Der Quellcode kann direkt über Flutter getestet werden:

```bash
# Unit Tests 
flutter test

# Quellcode Tests
flutter analyze
```

## Clean UP

```bash
# Nach beenden der Tests:
docker container prune
```
