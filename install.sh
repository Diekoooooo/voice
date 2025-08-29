#!/bin/bash

# اسکریپت نصب خودکار ربات موسیقی تلگرام
# برای Ubuntu 22.04

set -e

echo "🎵 نصب ربات موسیقی تلگرام..."
echo "=================================="

# بررسی سیستم عامل
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo "❌ این اسکریپت فقط برای Linux طراحی شده است!"
    exit 1
fi

# بررسی نسخه Ubuntu
if ! grep -q "Ubuntu 22.04" /etc/os-release; then
    echo "⚠️ این اسکریپت برای Ubuntu 22.04 تست شده است."
    echo "ادامه می‌دهید؟ (y/n)"
    read -r response
    if [[ "$response" != "y" ]]; then
        exit 1
    fi
fi

# به‌روزرسانی سیستم
echo "📦 به‌روزرسانی سیستم..."
sudo apt update && sudo apt upgrade -y

# نصب پیش‌نیازها
echo "🔧 نصب پیش‌نیازها..."
sudo apt install -y python3.10 python3.10-venv python3-pip ffmpeg git curl wget

# بررسی نصب Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 نصب نشده است!"
    exit 1
fi

echo "✅ Python3 نصب شد: $(python3 --version)"

# بررسی نصب FFmpeg
if ! command -v ffmpeg &> /dev/null; then
    echo "❌ FFmpeg نصب نشده است!"
    exit 1
fi

echo "✅ FFmpeg نصب شد: $(ffmpeg -version | head -n1)"

# ایجاد پوشه پروژه
PROJECT_DIR="$HOME/telegram-music-bot"
echo "📁 ایجاد پوشه پروژه: $PROJECT_DIR"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# کپی کردن فایل‌های پروژه (اگر در همان پوشه هستیم)
if [ -f "telegram_music_bot.py" ]; then
    echo "📋 کپی کردن فایل‌های پروژه..."
    cp telegram_music_bot.py "$PROJECT_DIR/"
    cp requirements.txt "$PROJECT_DIR/"
    cp env.example "$PROJECT_DIR/"
    cp README.md "$PROJECT_DIR/"
    cp telegram-music-bot.service "$PROJECT_DIR/"
fi

# ایجاد محیط مجازی
echo "🐍 ایجاد محیط مجازی Python..."
python3 -m venv venv
source venv/bin/activate

# نصب وابستگی‌ها
echo "📦 نصب وابستگی‌های Python..."
pip install --upgrade pip
pip install -r requirements.txt

# ایجاد فایل .env
echo "⚙️ تنظیم فایل محیط..."
if [ ! -f ".env" ]; then
    cp env.example .env
    echo "📝 فایل .env ایجاد شد. لطفاً آن را ویرایش کنید:"
    echo "nano .env"
    echo ""
    echo "توکن ربات خود را در فایل .env وارد کنید:"
    echo "BOT_TOKEN=your_telegram_bot_token_here"
fi

# تنظیم مجوزها
echo "🔐 تنظیم مجوزها..."
chmod +x install.sh
chmod 600 .env

# ایجاد پوشه downloads
mkdir -p downloads
chmod 755 downloads

# نصب سرویس systemd
echo "🖥️ نصب سرویس systemd..."
sudo cp telegram-music-bot.service /etc/systemd/system/
sudo systemctl daemon-reload

# تنظیم مسیر در فایل سرویس
CURRENT_USER=$(whoami)
sudo sed -i "s/User=ubuntu/User=$CURRENT_USER/g" /etc/systemd/system/telegram-music-bot.service
sudo sed -i "s|WorkingDirectory=/home/ubuntu/telegram-music-bot|WorkingDirectory=$PROJECT_DIR|g" /etc/systemd/system/telegram-music-bot.service
sudo sed -i "s|Environment=PATH=/home/ubuntu/telegram-music-bot/venv/bin|Environment=PATH=$PROJECT_DIR/venv/bin|g" /etc/systemd/system/telegram-music-bot.service
sudo sed -i "s|ExecStart=/home/ubuntu/telegram-music-bot/venv/bin/python|ExecStart=$PROJECT_DIR/venv/bin/python|g" /etc/systemd/system/telegram-music-bot.service

# فعال‌سازی سرویس
echo "🚀 فعال‌سازی سرویس..."
sudo systemctl enable telegram-music-bot.service

echo ""
echo "✅ نصب کامل شد!"
echo "=================================="
echo ""
echo "📋 مراحل بعدی:"
echo "1. فایل .env را ویرایش کنید و توکن ربات را وارد کنید:"
echo "   nano .env"
echo ""
echo "2. ربات را شروع کنید:"
echo "   sudo systemctl start telegram-music-bot.service"
echo ""
echo "3. وضعیت ربات را بررسی کنید:"
echo "   sudo systemctl status telegram-music-bot.service"
echo ""
echo "4. مشاهده لاگ‌ها:"
echo "   sudo journalctl -u telegram-music-bot.service -f"
echo ""
echo "5. برای دریافت توکن ربات:"
echo "   - به @BotFather در تلگرام پیام دهید"
echo "   - دستور /newbot را اجرا کنید"
echo "   - نام و username ربات را وارد کنید"
echo "   - توکن دریافتی را در فایل .env قرار دهید"
echo ""
echo "🎵 ربات موسیقی شما آماده است!" 