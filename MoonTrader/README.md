### Установка MoonTrader

Версия без iptables (для провайдеров со нативным firewall)

```
wget -O - https://raw.githubusercontent.com/rogerbase/scripts/main/MoonTrader/mt_install_nofw.sh | bash <(cat) </dev/tty
```

Версия с iptables (открыты порты 22, 1194)

```
wget -O - https://raw.githubusercontent.com/rogerbase/scripts/main/MoonTrader/mt_install.sh | bash <(cat) </dev/tty
```

### Скрипты для запуска ядра MoonTrader в сессии tmux

Cкрипт для запуска ядра в сессии tmux, с возможностью остановки/запуска и автозапуском при перезагрузке. Установка одной командой:

```
wget -O - https://raw.githubusercontent.com/rogerbase/scripts/main/MoonTrader/mtcore_service.sh | bash <(cat) </dev/tty
```

Запуск и остановка сервиса производятся командами:

```
systemctl start mtcore
systemctl stop mtcore
```

Остановка посылает SIGINT сигнал, поэтому ядро завершается корректно и отменяет все ордеры.
