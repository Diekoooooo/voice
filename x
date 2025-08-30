import os
import asyncio
import logging
from typing import Dict, List, Optional
from dataclasses import dataclass
from datetime import datetime
import json

import telegram
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import Application, CommandHandler, MessageHandler, CallbackQueryHandler, filters, ContextTypes
import yt_dlp
import requests
from mutagen.mp3 import MP3
import aiohttp
import aiofiles

# تنظیمات لاگینگ
logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO
)
logger = logging.getLogger(__name__)

@dataclass
class Song:
    title: str
    artist: str
    duration: int
    url: str
    file_path: str
    thumbnail: str = ""

@dataclass
class Queue:
    songs: List[Song]
    current_index: int = 0
    loop_mode: str = "off"  # off, one, all
    volume: int = 100
    is_playing: bool = False
    auto_dj: bool = False

class TelegramMusicBot:
    def __init__(self):
        self.token = os.getenv('BOT_TOKEN')
        self.prefix = os.getenv('PREFIX', '!')
        self.queues: Dict[int, Queue] = {}
        self.ydl_opts = {
            'format': 'bestaudio/best',
            'postprocessors': [{
                'key': 'FFmpegExtractAudio',
                'preferredcodec': 'mp3',
                'preferredquality': '192',
            }],
            'outtmpl': 'downloads/%(title)s.%(ext)s',
            'noplaylist': True,
        }
        
        # ایجاد پوشه downloads اگر وجود ندارد
        os.makedirs('downloads', exist_ok=True)
        
    async def start(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """دستور شروع ربات"""
        welcome_text = """
🎵 **ربات موسیقی تلگرام** 🎵

دستورات موجود:
• `/play <لینک یا نام آهنگ>` - پخش موسیقی
• `/pause` - توقف موقت
• `/resume` - ادامه پخش
• `/stop` - توقف کامل
• `/skip` - رد کردن آهنگ
• `/queue` - نمایش صف
• `/np` - نمایش آهنگ فعلی
• `/loop [one|all|off]` - تنظیم حلقه
• `/volume <0-100>` - تنظیم صدا
• `/lyrics <نام آهنگ>` - دریافت متن آهنگ
• `/autodj` - فعال/غیرفعال کردن Auto-DJ

لطفاً یک آهنگ را با دستور `/play` شروع کنید!
        """
        await update.message.reply_text(welcome_text, parse_mode='Markdown')

    async def play(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """پخش موسیقی"""
        chat_id = update.effective_chat.id
        
        if not context.args:
            await update.message.reply_text("❌ لطفاً لینک یا نام آهنگ را وارد کنید!")
            return
            
        query = ' '.join(context.args)
        
        # نمایش پیام در حال بارگذاری
        loading_msg = await update.message.reply_text("🔄 در حال بارگذاری...")
        
        try:
            # دانلود آهنگ
            song = await self.download_song(query)
            if not song:
                await loading_msg.edit_text("❌ خطا در دانلود آهنگ!")
                return
                
            # اضافه کردن به صف
            if chat_id not in self.queues:
                self.queues[chat_id] = Queue(songs=[])
            
            self.queues[chat_id].songs.append(song)
            
            # اگر اولین آهنگ است، شروع پخش
            if len(self.queues[chat_id].songs) == 1:
                await self.start_playback(chat_id, context)
            
            # نمایش پیام موفقیت
            embed = self.create_song_embed(song, "✅ به صف اضافه شد")
            await loading_msg.edit_text(embed, parse_mode='Markdown')
            
        except Exception as e:
            logger.error(f"خطا در پخش: {e}")
            await loading_msg.edit_text("❌ خطا در پخش آهنگ!")

    async def download_song(self, query: str) -> Optional[Song]:
        """دانلود آهنگ از یوتیوب یا سایر پلتفرم‌ها"""
        try:
            with yt_dlp.YoutubeDL(self.ydl_opts) as ydl:
                # اگر لینک است
                if query.startswith(('http://', 'https://')):
                    info = ydl.extract_info(query, download=True)
                else:
                    # جستجو در یوتیوب
                    search_query = f"ytsearch1:{query}"
                    info = ydl.extract_info(search_query, download=True)
                    if 'entries' in info:
                        info = info['entries'][0]
                
                # ایجاد مسیر فایل
                file_path = f"downloads/{info['title']}.mp3"
                
                # دریافت اطلاعات آهنگ
                song = Song(
                    title=info.get('title', 'Unknown'),
                    artist=info.get('uploader', 'Unknown'),
                    duration=info.get('duration', 0),
                    url=info.get('webpage_url', ''),
                    file_path=file_path,
                    thumbnail=info.get('thumbnail', '')
                )
                
                return song
                
        except Exception as e:
            logger.error(f"خطا در دانلود: {e}")
            return None

    async def start_playback(self, chat_id: int, context: ContextTypes.DEFAULT_TYPE):
        """شروع پخش موسیقی"""
        if chat_id not in self.queues or not self.queues[chat_id].songs:
            return
            
        queue = self.queues[chat_id]
        queue.is_playing = True
        
        # شبیه‌سازی پخش (در واقعیت باید از کتابخانه‌های صوتی استفاده کنید)
        await asyncio.sleep(2)
        
        # نمایش آهنگ فعلی
        current_song = queue.songs[queue.current_index]
        embed = self.create_song_embed(current_song, "🎵 در حال پخش")
        await context.bot.send_message(chat_id, embed, parse_mode='Markdown')

    def create_song_embed(self, song: Song, status: str) -> str:
        """ایجاد پیام embed برای آهنگ"""
        duration = f"{song.duration // 60}:{song.duration % 60:02d}"
        
        embed = f"""
🎵 **{song.title}**
👤 **هنرمند:** {song.artist}
⏱️ **مدت:** {duration}
📊 **وضعیت:** {status}

🔗 [دانلود]({song.url})
        """
        return embed

    async def pause(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """توقف موقت"""
        chat_id = update.effective_chat.id
        
        if chat_id in self.queues:
            self.queues[chat_id].is_playing = False
            await update.message.reply_text("⏸️ پخش متوقف شد")
        else:
            await update.message.reply_text("❌ هیچ آهنگی در حال پخش نیست!")

    async def resume(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """ادامه پخش"""
        chat_id = update.effective_chat.id
        
        if chat_id in self.queues:
            self.queues[chat_id].is_playing = True
            await update.message.reply_text("▶️ پخش ادامه یافت")
        else:
            await update.message.reply_text("❌ هیچ آهنگی برای ادامه وجود ندارد!")

    async def stop(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """توقف کامل"""
        chat_id = update.effective_chat.id
        
        if chat_id in self.queues:
            self.queues[chat_id] = Queue(songs=[])
            await update.message.reply_text("⏹️ پخش متوقف شد")
        else:
            await update.message.reply_text("❌ هیچ آهنگی در حال پخش نیست!")

    async def skip(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """رد کردن آهنگ"""
        chat_id = update.effective_chat.id
        
        if chat_id in self.queues and self.queues[chat_id].songs:
            queue = self.queues[chat_id]
            queue.current_index += 1
            
            if queue.current_index >= len(queue.songs):
                if queue.loop_mode == "all":
                    queue.current_index = 0
                else:
                    await update.message.reply_text("📭 صف تمام شد!")
                    return
            
            current_song = queue.songs[queue.current_index]
            embed = self.create_song_embed(current_song, "⏭️ آهنگ بعدی")
            await update.message.reply_text(embed, parse_mode='Markdown')
        else:
            await update.message.reply_text("❌ هیچ آهنگی برای رد کردن وجود ندارد!")

    async def queue_command(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """نمایش صف"""
        chat_id = update.effective_chat.id
        
        if chat_id not in self.queues or not self.queues[chat_id].songs:
            await update.message.reply_text("📭 صف خالی است!")
            return
            
        queue = self.queues[chat_id]
        queue_text = "📋 **صف آهنگ‌ها:**\n\n"
        
        for i, song in enumerate(queue.songs):
            duration = f"{song.duration // 60}:{song.duration % 60:02d}"
            if i == queue.current_index:
                queue_text += f"🎵 **{i+1}. {song.title}** ({duration}) - *در حال پخش*\n"
            else:
                queue_text += f"📄 {i+1}. {song.title} ({duration})\n"
        
        await update.message.reply_text(queue_text, parse_mode='Markdown')

    async def now_playing(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """نمایش آهنگ فعلی"""
        chat_id = update.effective_chat.id
        
        if chat_id in self.queues and self.queues[chat_id].songs:
            queue = self.queues[chat_id]
            current_song = queue.songs[queue.current_index]
            embed = self.create_song_embed(current_song, "🎵 در حال پخش")
            await update.message.reply_text(embed, parse_mode='Markdown')
        else:
            await update.message.reply_text("❌ هیچ آهنگی در حال پخش نیست!")

    async def loop(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """تنظیم حلقه"""
        chat_id = update.effective_chat.id
        
        if not context.args:
            await update.message.reply_text("❌ لطفاً حالت حلقه را مشخص کنید: one/all/off")
            return
            
        mode = context.args[0].lower()
        
        if mode not in ['one', 'all', 'off']:
            await update.message.reply_text("❌ حالت نامعتبر! از one/all/off استفاده کنید")
            return
            
        if chat_id not in self.queues:
            self.queues[chat_id] = Queue(songs=[])
            
        self.queues[chat_id].loop_mode = mode
        
        mode_text = {
            'one': '🔄 تکرار یک آهنگ',
            'all': '🔁 تکرار کل صف',
            'off': '⏹️ بدون تکرار'
        }
        
        await update.message.reply_text(f"✅ حالت حلقه: {mode_text[mode]}")

    async def volume(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """تنظیم صدا"""
        chat_id = update.effective_chat.id
        
        if not context.args:
            await update.message.reply_text("❌ لطفاً سطح صدا (0-100) را وارد کنید!")
            return
            
        try:
            vol = int(context.args[0])
            if not 0 <= vol <= 100:
                await update.message.reply_text("❌ سطح صدا باید بین 0 تا 100 باشد!")
                return
                
            if chat_id not in self.queues:
                self.queues[chat_id] = Queue(songs=[])
                
            self.queues[chat_id].volume = vol
            await update.message.reply_text(f"🔊 سطح صدا: {vol}%")
            
        except ValueError:
            await update.message.reply_text("❌ لطفاً عدد معتبر وارد کنید!")

    async def lyrics(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """دریافت متن آهنگ"""
        if not context.args:
            await update.message.reply_text("❌ لطفاً نام آهنگ را وارد کنید!")
            return
            
        song_name = ' '.join(context.args)
        
        try:
            # استفاده از API برای دریافت متن آهنگ
            lyrics_text = await self.get_lyrics(song_name)
            if lyrics_text:
                await update.message.reply_text(f"📝 **متن آهنگ {song_name}:**\n\n{lyrics_text[:1000]}...")
            else:
                await update.message.reply_text("❌ متن آهنگ یافت نشد!")
                
        except Exception as e:
            logger.error(f"خطا در دریافت متن آهنگ: {e}")
            await update.message.reply_text("❌ خطا در دریافت متن آهنگ!")

    async def get_lyrics(self, song_name: str) -> Optional[str]:
        """دریافت متن آهنگ از API"""
        try:
            # اینجا می‌توانید از API های مختلف استفاده کنید
            # مثال ساده:
            url = f"https://api.lyrics.ovh/v1/{song_name}"
            async with aiohttp.ClientSession() as session:
                async with session.get(url) as response:
                    if response.status == 200:
                        data = await response.json()
                        return data.get('lyrics', '')
            return None
        except Exception as e:
            logger.error(f"خطا در دریافت متن آهنگ: {e}")
            return None

    async def autodj(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """فعال/غیرفعال کردن Auto-DJ"""
        chat_id = update.effective_chat.id
        
        if chat_id not in self.queues:
            self.queues[chat_id] = Queue(songs=[])
            
        self.queues[chat_id].auto_dj = not self.queues[chat_id].auto_dj
        
        status = "فعال" if self.queues[chat_id].auto_dj else "غیرفعال"
        await update.message.reply_text(f"🤖 Auto-DJ {status} شد!")

    async def auto_dj_playback(self, chat_id: int, context: ContextTypes.DEFAULT_TYPE):
        """پخش خودکار آهنگ‌های مرتبط"""
        if chat_id not in self.queues or not self.queues[chat_id].auto_dj:
            return
            
        # اینجا می‌توانید منطق پیشنهاد آهنگ‌های مرتبط را پیاده‌سازی کنید
        # مثال: استفاده از API های پیشنهاد موسیقی
        pass

    def run(self):
        """اجرای ربات"""
        application = Application.builder().token(self.token).build()
        
        # اضافه کردن handlers
        application.add_handler(CommandHandler("start", self.start))
        application.add_handler(CommandHandler("play", self.play))
        application.add_handler(CommandHandler("pause", self.pause))
        application.add_handler(CommandHandler("resume", self.resume))
        application.add_handler(CommandHandler("stop", self.stop))
        application.add_handler(CommandHandler("skip", self.skip))
        application.add_handler(CommandHandler("queue", self.queue_command))
        application.add_handler(CommandHandler("np", self.now_playing))
        application.add_handler(CommandHandler("loop", self.loop))
        application.add_handler(CommandHandler("volume", self.volume))
        application.add_handler(CommandHandler("lyrics", self.lyrics))
        application.add_handler(CommandHandler("autodj", self.autodj))
        
        # شروع ربات
        application.run_polling()

if __name__ == "__main__":
    bot = TelegramMusicBot()
    bot.run() 