# MoonTrader Docker

## Установка и настройка

### 1. Подготовка системы
```bash
# Установка Docker (если не установлен)
curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh
apt update && apt install -y docker-compose

# Создание рабочей директории
mkdir -p /root/moontrader-docker && cd /root/moontrader-docker

# Загрузка конфигурационных файлов
wget https://raw.githubusercontent.com/rogerbase/scripts/refs/heads/main/MoonTrader/Docker/Dockerfile
wget https://raw.githubusercontent.com/rogerbase/scripts/refs/heads/main/MoonTrader/Docker/docker-compose.yaml
```

### 2. Сборка и запуск

```bash
# Сборка образа
docker compose build

# Запуск сервиса
docker compose up -d
```
### 3. Основные команды

```bash
# Остановка сервиса (с отменой ордеров)
docker compose down

# Просмотр логов
docker logs -f -n 100 moontrader-mtcore

# Подключение к консоли (Выход: Ctrl+P, Ctrl+Q)
docker attach moontrader-mtcore
```