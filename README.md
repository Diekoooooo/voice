# ربات موسیقی تلگرام 🎵

یک ربات موسیقی کامل برای تلگرام با قابلیت پخش آهنگ از یوتیوب، SoundCloud و سایر پلتفرم‌ها.

## ویژگی‌ها ✨

- 🎵 پخش موسیقی از یوتیوب، SoundCloud و سایر پلتفرم‌ها
- 📋 مدیریت صف آهنگ‌ها
- 🔄 حالت‌های حلقه (تکرار یک آهنگ، کل صف، بدون تکرار)
- 🔊 تنظیم صدا
- 📝 دریافت متن آهنگ
- 🤖 Auto-DJ (پخش خودکار آهنگ‌های مرتبط)
- 🎛️ کنترل کامل پخش (توقف، ادامه، رد کردن)
- 💬 پشتیبانی از چندین گروه/کانال

## دستورات موجود 📝

| دستور | توضیح |
|-------|-------|
| `/start` | شروع ربات و نمایش دستورات |
| `/play <لینک یا نام آهنگ>` | پخش موسیقی |
| `/pause` | توقف موقت |
| `/resume` | ادامه پخش |
| `/stop` | توقف کامل |
| `/skip` | رد کردن آهنگ |
| `/queue` | نمایش صف |
| `/np` | نمایش آهنگ فعلی |
| `/loop [one\|all\|off]` | تنظیم حلقه |
| `/volume <0-100>` | تنظیم صدا |
| `/lyrics <نام آهنگ>` | دریافت متن آهنگ |
| `/autodj` | فعال/غیرفعال کردن Auto-DJ |

## نصب و راه‌اندازی 🚀

### پیش‌نیازها

- Python 3.8+
- FFmpeg
- pip

### مراحل نصب

#### 1. نصب Python و FFmpeg در Ubuntu 22.04

```bash
# به‌روزرسانی سیستم
sudo apt update && sudo apt upgrade -y

# نصب Python 3.10
sudo apt install python3.10 python3.10-venv python3-pip -y

# نصب FFmpeg
sudo apt install ffmpeg -y

# بررسی نسخه‌ها
python3 --version
ffmpeg -version
```

#### 2. کلون کردن پروژه

```bash
git clone <repository-url>
cd telegram-music-bot
```

#### 3. ایجاد محیط مجازی

```bash
python3 -m venv venv
source venv/bin/activate
```

#### 4. نصب وابستگی‌ها

```bash
pip install -r requirements.txt
```

#### 5. تنظیم ربات

```bash
# کپی کردن فایل نمونه
cp env.example .env

# ویرایش فایل .env
nano .env
```

فایل `.env` را ویرایش کنید و توکن ربات خود را وارد کنید:

```env
BOT_TOKEN=your_telegram_bot_token_here
PREFIX=!
DEBUG=false
LOG_LEVEL=INFO
```

#### 6. دریافت توکن ربات

1. به [@BotFather](https://t.me/BotFather) در تلگرام پیام دهید
2. دستور `/newbot` را اجرا کنید
3. نام ربات و username را وارد کنید
4. توکن دریافتی را در فایل `.env` قرار دهید

#### 7. اجرای ربات

```bash
python telegram_music_bot.py
```

## راه‌اندازی به عنوان سرویس سیستم 🖥️

### ایجاد فایل سرویس systemd

```bash
sudo nano /etc/systemd/system/telegram-music-bot.service
```

محتوای فایل:

```ini
[Unit]
Description=Telegram Music Bot
After=network.target

[Service]
Type=simple
User=your_username
WorkingDirectory=/path/to/telegram-music-bot
Environment=PATH=/path/to/telegram-music-bot/venv/bin
ExecStart=/path/to/telegram-music-bot/venv/bin/python telegram_music_bot.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### فعال‌سازی و شروع سرویس

```bash
# فعال‌سازی سرویس
sudo systemctl enable telegram-music-bot.service

# شروع سرویس
sudo systemctl start telegram-music-bot.service

# بررسی وضعیت
sudo systemctl status telegram-music-bot.service

# مشاهده لاگ‌ها
sudo journalctl -u telegram-music-bot.service -f
```

## ساختار پروژه 📁

```
telegram-music-bot/
├── telegram_music_bot.py    # فایل اصلی ربات
├── requirements.txt         # وابستگی‌های Python
├── env.example             # نمونه فایل محیط
├── README.md              # مستندات
├── downloads/             # پوشه دانلود آهنگ‌ها
└── venv/                  # محیط مجازی Python
```

## تنظیمات پیشرفته ⚙️

### تنظیم کیفیت صدا

در فایل `telegram_music_bot.py`، بخش `ydl_opts` را ویرایش کنید:

```python
'preferredquality': '192',  # کیفیت صدا (128, 192, 320)
```

### تنظیم فرمت فایل

```python
'preferredcodec': 'mp3',  # فرمت فایل (mp3, m4a, ogg)
```

### تنظیم مسیر دانلود

```python
'outtmpl': 'downloads/%(title)s.%(ext)s',  # مسیر و نام فایل
```

## عیب‌یابی 🔧

### مشکلات رایج

1. **خطای FFmpeg**: مطمئن شوید FFmpeg نصب شده است
2. **خطای توکن**: توکن ربات را بررسی کنید
3. **خطای دانلود**: اتصال اینترنت را بررسی کنید
4. **خطای مجوز**: مجوزهای فایل را بررسی کنید

### لاگ‌ها

```bash
# مشاهده لاگ‌های ربات
tail -f bot.log

# مشاهده لاگ‌های سرویس
sudo journalctl -u telegram-music-bot.service -f
```

## مشارکت 🤝

برای مشارکت در پروژه:

1. Fork کنید
2. Branch جدید ایجاد کنید
3. تغییرات را commit کنید
4. Pull Request ارسال کنید

## مجوز 📄

این پروژه تحت مجوز MIT منتشر شده است.

## پشتیبانی 💬

برای پشتیبانی و سوالات:
- GitHub Issues
- Email: your-email@example.com

---

**نکته**: این ربات برای استفاده آموزشی و شخصی طراحی شده است. لطفاً قوانین کپی‌رایت را رعایت کنید. 