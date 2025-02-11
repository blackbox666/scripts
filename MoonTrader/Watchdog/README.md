# Запуск нескольких watchdog в Docker-контейнерах

## Описание
Данный скрипт предназначен для запуска нескольких watchdog-инстансов MTCore в изолированных Docker-контейнерах. С его помощью можно запустить множество watchdog на одном сервере для разных профилей, не утруждая себя предварительной настройкой каждого профиля и запуском их в отдельных tmux-сессиях.

Если у вас нет навыков работы с консолью, то для скачивания/закачивания профилей проще всего воспользоваться программой WinSCP:
https://www.dmosk.ru/programs_work.php?object=winscp.

## Функционал скрипта

1. Автоматическая установка Docker (если не установлен)
2. Подготовка профилей:
    - Обновление IP-адресов в client.conf
    - Удаление лишних файлов
3. Проверка состояния Docker-контейнеров:
    - Проверка работающих контейнеров
    - Автоматический перезапуск остановленных
    - Создание новых при необходимости
4. Параметры:
    - `DELAY`: задержка между запуском контейнеров (по умолчанию 120 секунд)
    - `IMAGE_NAME`: имя Docker-образа (по умолчанию "mtcore-wd")

### ⚠️ Важно
- Имена папок профилей должны совпадать с названиями профилей в скрипте
- IP-адрес watchdog-сервера должен быть добавлен во все API-ключи
- Для watchdog-сервера должны быть разрешены подключения к ядрам по порту 4242
- Желательно использовать VPS минимум с 2 vCPU и 2 GB оперативной памяти.

## Подготовка

### 1. Структура рабочей директории:
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

### 2. Создание окружения

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
3. Разместите профили в директории `profiles`.
4. В скрипте `start_watchdog.sh` определите названия профилей и IP-адреса ядер:
```bash
declare -A PROFILES=(
    ["profile1"]="18.176.43.181"
    ["profile2"]="18.176.43.182"
    ["profile3"]="18.176.43.183"
    ["profile4"]="18.176.43.184"
    ["profile5"]="18.176.43.185"
)
```

## Запуск

1. Сделать скрипт исполняемым:
```bash
chmod +x start_watchdog.sh
```

2. Запустить:
```bash
./start_watchdog.sh
```

Скрипт начнет последовательно запускать контейнеры с задержкой `DELAY` (по умолчанию 120 секунд) между каждым профилем, чтобы мгновенно не улететь в бан. Когда все контейнеры будут запущены, вы увидите сообщение `All containers processed` в консоли.

## Мониторинг

Вывести список запущенных контейнеров:

```bash
docker ps
```

Теперь можно попробовать остановить основное ядро и посмотреть логи конкретного контейнера в реальном времени:

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
