# Базовый образ для сборки
FROM golang:1.21-alpine AS builder

# Установка зависимостей и инструментов
RUN apk add --no-cache git ca-certificates

# Рабочая директория
WORKDIR /src

# Копируем файлы модулей для кэширования
COPY go.mod go.sum ./
RUN go mod download

# Копируем исходный код
COPY . .

# Собираем приложение
# -ldflags="-s -w" - убираем debug информацию для уменьшения размера
# CGO_ENABLED=0 - отключаем CGO для полностью статического бинарника
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /app ./cmd/main.go

# Финальный образ (минимальный)
FROM scratch

# Копируем SSL сертификаты
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Копируем собранное приложение
COPY --from=builder /app /app

# Указываем точку входа
ENTRYPOINT ["/app"]