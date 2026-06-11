# Comandos de Instalación por Stack

## JavaScript / TypeScript

### npm
```bash
# Instalación limpia (recomendada si hay package-lock.json)
npm ci

# Instalación normal
npm install

# Instalar dependencia
npm install <paquete>
npm install -D <paquete>  # devDependency
```

### Yarn
```bash
yarn install          # instalar todo
yarn add <paquete>
yarn add -D <paquete>
```

### pnpm
```bash
pnpm install
pnpm add <paquete>
pnpm add -D <paquete>
```

### Bun
```bash
bun install
bun add <paquete>
bun add -d <paquete>
```

### Gestión de versiones de Node
```bash
# Si hay .nvmrc
nvm use

# Si hay .node-version
nodenv local $(cat .node-version)

# Ver versión requerida en package.json
cat package.json | grep '"engines"' -A 3
```

---

## Python

### Verificar entorno virtual
```bash
# Verificar si hay venv activo
echo $VIRTUAL_ENV

# Crear venv si no existe
python3 -m venv .venv
source .venv/bin/activate  # Linux/Mac
# .venv\Scripts\activate   # Windows
```

### pip
```bash
pip install -r requirements.txt
pip install -r requirements-dev.txt  # si existe
```

### Poetry
```bash
poetry install            # instala todo (incluyendo dev)
poetry install --no-dev   # solo producción
poetry shell              # activar entorno
```

### Pipenv
```bash
pipenv install            # instala Pipfile
pipenv install --dev      # incluye dev deps
pipenv shell              # activar entorno
```

### pyproject.toml (PEP 517)
```bash
pip install -e ".[dev]"   # editable + dev extras
pip install -e .          # solo producción
```

---

## Flutter / Dart

```bash
flutter pub get           # instalar dependencias
flutter doctor            # verificar instalación completa
flutter doctor -v         # verbose, muestra todo
flutter clean             # limpiar build cache
flutter pub upgrade       # actualizar deps
```

### Verificar entorno Flutter
```bash
flutter --version
dart --version
```

---

## React Native

```bash
# Con npm
npm install
cd ios && pod install && cd ..   # solo iOS / Mac

# Con yarn
yarn install
cd ios && pod install && cd ..
```

### Expo
```bash
npx expo install          # instala deps compatibles con Expo SDK
npx expo doctor           # verifica configuración
```

---

## Go

```bash
go mod download           # descargar dependencias
go mod tidy               # limpiar go.sum
go build ./...            # compilar todo
```

---

## Java / Kotlin

### Maven
```bash
./mvnw install            # instalar deps y compilar
./mvnw install -DskipTests  # sin tests
```

### Gradle
```bash
./gradlew build           # build completo
./gradlew dependencies    # ver árbol de deps
```

---

## Rust

```bash
cargo build               # compilar
cargo build --release     # build optimizado
cargo fetch               # solo descargar deps
```

---

## Docker / Docker Compose

```bash
# Levantar todos los servicios
docker compose up -d

# Construir imágenes
docker compose build

# Ver logs
docker compose logs -f

# Verificar que Docker esté corriendo
docker info
```

---

## Comandos de arranque por framework

| Framework | Comando dev |
|---|---|
| Next.js | `npm run dev` |
| React + Vite | `npm run dev` |
| Vue + Vite | `npm run dev` |
| Nuxt.js | `npm run dev` |
| SvelteKit | `npm run dev` |
| Angular | `ng serve` |
| Remix | `npm run dev` |
| Astro | `npm run dev` |
| Django | `python manage.py runserver` |
| Flask | `flask run` o `python app.py` |
| FastAPI | `uvicorn main:app --reload` |
| Flutter | `flutter run` |
| Expo | `npx expo start` |
| Go | `go run .` |
| Spring Boot | `./mvnw spring-boot:run` |
