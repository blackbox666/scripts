import os
import time
import logging
from logging.handlers import RotatingFileHandler
from datetime import datetime, timedelta
from binance.client import Client
from binance.enums import SIDE_SELL, ORDER_TYPE_MARKET
from telegram.ext import Updater, CommandHandler

# Настройка логирования
log_file = 'bot_log.log'  # Имя файла лога
file_handler = RotatingFileHandler(log_file, maxBytes=1024 * 1024 * 5, backupCount=5)  # Размер файла 5 МБ, сохраняются 5 последних файлов
file_handler.setFormatter(logging.Formatter('%(asctime)s - %(levelname)s - %(message)s'))

logging.basicConfig(format='%(asctime)s - %(levelname)s - %(message)s', level=logging.INFO)
logger = logging.getLogger(__name__)
logger.addHandler(file_handler)

config = {
    'binance_api_key': os.getenv('BINANCE_API_KEY'),
    'binance_api_secret': os.getenv('BINANCE_API_SECRET'),
    'telegram_token': os.getenv('TELEGRAM_TOKEN'),
    'chat_id': os.getenv('CHAT_ID'),
    'interval_seconds': int(os.getenv('INTERVAL_SECONDS', 10)),  # Значение по умолчанию 10
    'close_position_interval_seconds': int(os.getenv('CLOSE_POSITION_INTERVAL_SECONDS', 20)),  # Значение по умолчанию 20
}

client = Client(config['binance_api_key'], config['binance_api_secret'])

# Словарь для отслеживания времени, когда была обнаружена зависшая позиция
hanged_positions_time = {}

def close_hanged_position(symbol, position_amount):
    if position_amount > 0:
        # Продать, если есть LONG позиция (позитивное количество) 
        side = 'SELL'
    else:
        # Купить, ссли есть SHORT позиция (отрицательное количество)
        side = 'BUY'

    absolute_position_amount = abs(position_amount)

    try:
        order = client.futures_create_order(
            symbol=symbol,
            side=side,
            type='MARKET',
            quantity=absolute_position_amount,
        )
        logger.info(f"Позиция {symbol} успешно закрыта: {order['status']}")
    except Exception as e:
        logger.error(f"Ошибка при автоматическом закрытии позиции {symbol}: {e}")

def get_position_for_symbol(symbol):
    for pos in client.futures_position_information(symbol=symbol):
        if pos['symbol'] == symbol:
            return float(pos['positionAmt'])
    return 0

def get_symbol_price_in_usd(symbol):
    ticker_info = client.futures_ticker(symbol=symbol)
    return float(ticker_info.get('lastPrice', 0))

def notify_telegram(message):
    updater.bot.send_message(chat_id=config['chat_id'], text=message)

def close_position_automatically(symbol):
    logger.info(f"Attempting to automatically close position for {symbol}")
    try:
        positions = client.futures_position_information()
        for pos in positions:
            if pos['symbol'] == symbol and pos['positionAmt'] != '0':
                close_hanged_position(symbol, float(pos['positionAmt']))
                return
        logger.info(f"Position for {symbol} not found or already closed.")
    except Exception as e:
        logger.error(f"Error closing position for {symbol}: {str(e)}")
        notify_telegram(f"Ошибка при попытке закрыть позицию для {symbol}. Пожалуйста, проверьте вручную.")

def close_position(update, context):
    symbol = context.args[0]
    logger.info(f"Attempting to manually close position for {symbol}")
    try:
        positions = client.futures_position_information()
        for pos in positions:
            if pos['symbol'] == symbol and pos['positionAmt'] != '0':
                close_hanged_position(symbol, float(pos['positionAmt']))
                return
        logger.info(f"Position for {symbol} not found or already closed.")
    except Exception as e:
        logger.error(f"Error closing position for {symbol}: {str(e)}")
        notify_telegram(f"Ошибка при попытке закрыть позицию для {symbol}. Пожалуйста, проверьте вручную.")

def monitor_positions():
    logger.info("Monitoring positions...")
    notify_telegram("Бот начал мониторинг...")

    while True:
        positions = client.futures_position_information()
        for pos in positions:
            symbol = pos['symbol']
            position_amount = float(pos['positionAmt'])

            if position_amount != 0:
                open_orders = client.futures_get_open_orders(symbol=symbol)
                position_value_usd = position_amount * get_symbol_price_in_usd(symbol)
                logger.info(f"{symbol} - Position: ${position_value_usd}, Orders: {len(open_orders)}")

                if not open_orders:
                    notify_telegram(f"Зависшая позиция для {symbol}: ${position_value_usd:.2f}")

                    if symbol not in hanged_positions_time:
                        hanged_positions_time[symbol] = datetime.now()
                    elif datetime.now() - hanged_positions_time[symbol] > timedelta(seconds=config['close_position_interval_seconds']):
                        close_hanged_position(symbol, position_amount)

        time.sleep(config['interval_seconds'])

def main():
    global updater
    updater = Updater(config['telegram_token'])
    dp = updater.dispatcher

    dp.add_handler(CommandHandler("close", close_position, pass_args=True))

    updater.start_polling()
    monitor_positions()

if __name__ == '__main__':
    main()
