# Запуск нескольких Watchdog в Docker-контейнерах

## Что делает скрипт

1. Устанавливает Docker, если не установлен.
2. Очищает профили от ненужных файлов.
3. Обновляет IP адреса в client.conf
4. Управляет Docker контейнерами:
    - Пропускает запущенные
    - Перезапускает остановленные
    - Создает новые при отсутствии
5. Параметры
    - `DELAY`: задержка между запуском контейнеров (по умолчанию 120 секунд)
    - `IMAGE_NAME`: имя Docker образа (по умолчанию "mtcore-wd")

## Подготовка окружения

### Структура рабочей директории:
```bash
/root/watchdog_docker/
├── profiles/
│   ├── profile1/
│   │   └── client.conf
│   ├── profile2/
│   │   └── client.conf
│   └── ...
└── Dockerfile
└── start_watchdog.sh
```
### Создание окружения

1. Создайте рабочую директорию:
```bash
mkdir -p /root/watchdog_docker/profiles
cd /root/watchdog_docker
```
2. Скачайте необходимые файлы:
```bash
wget https://raw.githubusercontent.com/rogerbase/scripts/refs/heads/main/MoonTrader/Watchdog/Dockerfile
wget https://raw.githubusercontent.com/rogerbase/scripts/refs/heads/main/MoonTrader/Watchdog/start_watchdog.sh
```
3. Скачайте все необходимые профили и поместите их в директорию `profiles`
4. В скрипте `start_watchdog.sh` определите названия профилей и IP адреса ядер:
```bash
declare -A PROFILES=(
    ["profile1"]="18.176.43.181"
    ["profile2"]="18.176.43.182"
    ["profile3"]="18.176.43.183"
    ["profile4"]="18.176.43.184"
    ["profile5"]="18.176.43.185"
)
```
❗Убедитесь, что имена папок профилей совпадают с названиями профилей в скрипте!

## Запуск Watchdog-контейнеров

### Запуск скрипта

1. Сделать скрипт исполняемым:
```bash
chmod +x start_watchdog.sh
```

2. Запустить:
```bash
./start_watchdog.sh
```

Скрипт начнет последовательно запускать контейнеры с задержкой `DELAY` (по умолчанию 120 секунд) между каждым профилем, чтобы мгновенно не улететь в бан. Когда все контейнеры будут запущены, вы увидите сообщение `All containers processed` в консоли.

### Мониторинг

Список всех запущенных контейнеров:

```bash
docker ps
```

Теперь можно попробовать убить основное ядро и посмотреть логи конкретного контейнера в реальном времени:

```bash
docker logs -f -n 50 wd-profile1
```

Если все было настроено правильно, то watchdog увидит отключение ядра и попытается отменить ордеры и закрыть позиции:

```
2025-02-11 13:03:04.263|1739278984263|DEBUG|7|50|WatchDogSession(134).OnDisconnect|[profile1] WD disconnected|
2025-02-11 13:03:04.263|1739278984263|DEBUG|7|50|WatchDogSession(155).OnReconnectFail|[profile1] WD reconnect failed|
2025-02-11 13:03:04.263|1739278984263|DEBUG|7|50|WatchDogSession(162).OnReconnectFail|[profile1] WD Cancelling all orders...|
2025-02-11 13:03:04.263|1739278984263|DEBUG|7|50|WatchDogSession(166).OnReconnectFail|[profile1] WD Closing all positions...|
2025-02-11 13:03:04.263|1739278984263|INFO|7|50|WatchDogUdpManager(104).OnDisconnect|Reconnecting... (5) [1]|
```