# 🚀 راهنمای تنظیم Userbot موسیقی تلگرام

## ⚠️ هشدار مهم
**Userbot برای استفاده آموزشی است و ممکن است منجر به مسدود شدن حساب شما شود!**

## 📋 پیش‌نیازها

### 1. دریافت API ID و API Hash
1. به [my.telegram.org](https://my.telegram.org) بروید
2. با شماره تلفن تلگرام خود وارد شوید
3. کد تایید ارسال شده را وارد کنید
4. روی "API development tools" کلیک کنید
5. فرم زیر را پر کنید:
   - **App title**: Music Bot
   - **Short name**: musicbot
   - **Platform**: Desktop
   - **Description**: Music bot for educational purposes
6. **api_id** و **api_hash** را کپی کنید

### 2. بررسی تایید دو مرحله‌ای
- در تلگرام: **Settings** → **Privacy and Security** → **Two-Step Verification**
- اگر فعال است، روی **App Passwords** کلیک کنید
- یک کلمه عبور جدید برای اپلیکیشن ایجاد کنید

## ⚙️ تنظیم فایل .env

1. فایل `env.example` را کپی کنید:
```bash
cp env.example .env
```

2. فایل `.env` را ویرایش کنید:
```bash
nano .env
```

3. اطلاعات خود را وارد کنید:
```env
# API ID (عدد)
API_ID=12345678

# API Hash (رشته)
API_HASH=abcdef1234567890abcdef1234567890

# شماره تلفن (با کد کشور)
PHONE=+989123456789

# نام فایل session
SESSION_NAME=music_userbot

# کلمه عبور اپلیکیشن (اگر تایید دو مرحله‌ای فعال است)
APP_PASSWORD=your_app_password_here

# تنظیمات اختیاری
DEBUG=false
LOG_LEVEL=INFO
```

## 🐍 نصب وابستگی‌ها

```bash
# ایجاد محیط مجازی
python3 -m venv venv
source venv/bin/activate

# نصب وابستگی‌ها
pip install -r requirements.txt
```

## 🚀 اجرای Userbot

```bash
# فعال‌سازی محیط مجازی
source venv/bin/activate

# اجرای Userbot
python telegram_userbot.py
```

## 📱 استفاده از Userbot

بعد از اجرا، Userbot در چت‌های خود پیام‌های زیر را پاسخ می‌دهد:

- `!start` - شروع و نمایش دستورات
- `!play <نام آهنگ>` - پخش موسیقی
- `!pause` - توقف موقت
- `!resume` - ادامه پخش
- `!stop` - توقف کامل
- `!skip` - رد کردن آهنگ
- `!queue` - نمایش صف
- `!np` - نمایش آهنگ فعلی
- `!loop [one|all|off]` - تنظیم حلقه
- `!volume <0-100>` - تنظیم صدا
- `!lyrics <نام آهنگ>` - دریافت متن آهنگ
- `!autodj` - فعال/غیرفعال کردن Auto-DJ

## 🔧 عیب‌یابی

### خطای "Phone number invalid"
- شماره تلفن را با کد کشور وارد کنید (+989123456789)

### خطای "API_ID/API_HASH invalid"
- API ID و API Hash را از my.telegram.org دریافت کنید

### خطای "Two-steps verification is enabled"
- کلمه عبور اپلیکیشن را در فایل .env تنظیم کنید

### خطای "Session expired"
- فایل session را حذف کنید و دوباره اجرا کنید

## 📁 ساختار فایل‌ها

```
voice/
├── telegram_userbot.py    # فایل اصلی Userbot
├── requirements.txt       # وابستگی‌های Python
├── env.example           # نمونه فایل محیط
├── SETUP_GUIDE.md        # این راهنما
├── .env                  # فایل تنظیمات (بعد از ایجاد)
├── downloads/            # پوشه دانلود آهنگ‌ها
└── *.session            # فایل‌های session تلگرام
```

## 🆘 پشتیبانی

اگر مشکلی دارید:
1. لاگ‌های خطا را بررسی کنید
2. فایل `.env` را بررسی کنید
3. API ID و API Hash را دوباره بررسی کنید
4. اگر تایید دو مرحله‌ای فعال است، کلمه عبور اپلیکیشن را تنظیم کنید

---

**نکته**: این Userbot فقط برای استفاده آموزشی طراحی شده است. لطفاً قوانین تلگرام را رعایت کنید.
