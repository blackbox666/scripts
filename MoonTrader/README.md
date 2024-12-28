### Скрипты для запуска ядра MoonTrader в сессии tmux

Cкрипт для запуска ядра в сессии tmux, с возможностью остановки/запуска и автозапуском при перезагрузке:

```
wget -O - https://raw.githubusercontent.com/rogerbase/scripts/main/MoonTrader/mtcore_service.sh | bash <(cat) </dev/tty
```

Запуск и остановка сервиса производятся командами:

```
systemctl start mtcore
systemctl stop mtcore
```

Остановка посылает SIGINT сигнал, поэтому ядро завершается корректно и отменяет все ордеры.
