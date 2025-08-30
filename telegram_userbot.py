"""
⚠️ هشدار: این فایل برای استفاده آموزشی است!
استفاده از Userbot ممکن است منجر به مسدود شدن حساب شما شود.
استفاده در معرض خطر خودتان است!
"""

import os
import asyncio
import logging
from typing import Dict, List, Optional
from dataclasses import dataclass
import json

from telethon import TelegramClient, events
from telethon.tl.types import PeerUser, PeerChat, PeerChannel
import yt_dlp
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
    loop_mode: str = "off"
    volume: int = 100
    is_playing: bool = False
    auto_dj: bool = False

class TelegramUserbot:
    def __init__(self):
        # تنظیمات Userbot
        self.api_id = os.getenv('API_ID')
        self.api_hash = os.getenv('API_HASH')
        self.phone = os.getenv('PHONE')
        self.session_name = os.getenv('SESSION_NAME', 'music_userbot')
        self.app_password = os.getenv('APP_PASSWORD')  # کلمه عبور اپلیکیشن
        
        # ایجاد کلاینت بدون پروکسی
        self.client = TelegramClient(
            self.session_name, 
            self.api_id, 
            self.api_hash,
            connection_retries=10,
            retry_delay=2,
            timeout=30,
            auto_reconnect=True
        )
        
        # صف‌های موسیقی
        self.queues: Dict[int, Queue] = {}
        
        # تنظیمات yt-dlp
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
        
        # ایجاد پوشه downloads
        os.makedirs('downloads', exist_ok=True)
        
        # ثبت event handlers
        self.register_handlers()
        
    def register_handlers(self):
        """ثبت event handlers"""
        
        @self.client.on(events.NewMessage(pattern=r'^!start'))
        async def start_handler(event):
            await self.start_command(event)
            
        @self.client.on(events.NewMessage(pattern=r'^!play'))
        async def play_handler(event):
            await self.play_command(event)
            
        @self.client.on(events.NewMessage(pattern=r'^!pause'))
        async def pause_handler(event):
            await self.pause_command(event)
            
        @self.client.on(events.NewMessage(pattern=r'^!resume'))
        async def resume_handler(event):
            await self.resume_command(event)
            
        @self.client.on(events.NewMessage(pattern=r'^!stop'))
        async def stop_handler(event):
            await self.stop_command(event)
            
        @self.client.on(events.NewMessage(pattern=r'^!skip'))
        async def skip_handler(event):
            await self.skip_command(event)
            
        @self.client.on(events.NewMessage(pattern=r'^!queue'))
        async def queue_handler(event):
            await self.queue_command(event)
            
        @self.client.on(events.NewMessage(pattern=r'^!np'))
        async def np_handler(event):
            await self.now_playing_command(event)
            
        @self.client.on(events.NewMessage(pattern=r'^!loop'))
        async def loop_handler(event):
            await self.loop_command(event)
            
        @self.client.on(events.NewMessage(pattern=r'^!volume'))
        async def volume_handler(event):
            await self.volume_command(event)
            
        @self.client.on(events.NewMessage(pattern=r'^!lyrics'))
        async def lyrics_handler(event):
            await self.lyrics_command(event)
            
        @self.client.on(events.NewMessage(pattern=r'^!autodj'))
        async def autodj_handler(event):
            await self.autodj_command(event)

    async def start_command(self, event):
        """دستور شروع"""
        welcome_text = """
🎵 **ربات موسیقی Userbot** 🎵

دستورات موجود:
• `!play <لینک یا نام آهنگ>` - پخش موسیقی
• `!pause` - توقف موقت
• `!resume` - ادامه پخش
• `!stop` - توقف کامل
• `!skip` - رد کردن آهنگ
• `!queue` - نمایش صف
• `!np` - نمایش آهنگ فعلی
• `!loop [one|all|off]` - تنظیم حلقه
• `!volume <0-100>` - تنظیم صدا
• `!lyrics <نام آهنگ>` - دریافت متن آهنگ
• `!autodj` - فعال/غیرفعال کردن Auto-DJ

⚠️ **هشدار**: این Userbot برای استفاده آموزشی است!
        """
        await event.respond(welcome_text)

    async def play_command(self, event):
        """دستور پخش"""
        chat_id = event.chat_id
        
        # استخراج متن پیام
        message_text = event.message.text
        if len(message_text.split()) < 2:
            await event.respond("❌ لطفاً لینک یا نام آهنگ را وارد کنید!")
            return
            
        query = ' '.join(message_text.split()[1:])
        
        # نمایش پیام در حال بارگذاری
        loading_msg = await event.respond("🔄 در حال بارگذاری...")
        
        try:
            # دانلود آهنگ
            song = await self.download_song(query)
            if not song:
                await loading_msg.edit("❌ خطا در دانلود آهنگ!")
                return
                
            # اضافه کردن به صف
            if chat_id not in self.queues:
                self.queues[chat_id] = Queue(songs=[])
            
            self.queues[chat_id].songs.append(song)
            
            # اگر اولین آهنگ است، شروع پخش
            if len(self.queues[chat_id].songs) == 1:
                await self.start_playback(chat_id)
            
            # نمایش پیام موفقیت
            embed = self.create_song_embed(song, "✅ به صف اضافه شد")
            await loading_msg.edit(embed)
            
        except Exception as e:
            logger.error(f"خطا در پخش: {e}")
            await loading_msg.edit("❌ خطا در پخش آهنگ!")

    async def download_song(self, query: str) -> Optional[Song]:
        """دانلود آهنگ"""
        try:
            with yt_dlp.YoutubeDL(self.ydl_opts) as ydl:
                if query.startswith(('http://', 'https://')):
                    info = ydl.extract_info(query, download=True)
                else:
                    # جستجو در یوتیوب
                    search_query = f"ytsearch1:{query}"
                    info = ydl.extract_info(search_query, download=True)
                    if 'entries' in info:
                        info = info['entries'][0]
                
                file_path = f"downloads/{info['title']}.mp3"
                
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

    async def start_playback(self, chat_id: int):
        """شروع پخش"""
        if chat_id not in self.queues or not self.queues[chat_id].songs:
            return
            
        queue = self.queues[chat_id]
        queue.is_playing = True
        
        # شبیه‌سازی پخش
        await asyncio.sleep(2)
        
        # نمایش آهنگ فعلی
        current_song = queue.songs[queue.current_index]
        embed = self.create_song_embed(current_song, "🎵 در حال پخش")
        await self.client.send_message(chat_id, embed)

    def create_song_embed(self, song: Song, status: str) -> str:
        """ایجاد embed برای آهنگ"""
        duration = f"{song.duration // 60}:{song.duration % 60:02d}"
        
        embed = f"""
🎵 **{song.title}**
👤 **هنرمند:** {song.artist}
⏱️ **مدت:** {duration}
📊 **وضعیت:** {status}

🔗 [دانلود]({song.url})
        """
        return embed

    async def pause_command(self, event):
        """دستور توقف موقت"""
        chat_id = event.chat_id
        
        if chat_id in self.queues:
            self.queues[chat_id].is_playing = False
            await event.respond("⏸️ پخش متوقف شد")
        else:
            await event.respond("❌ هیچ آهنگی در حال پخش نیست!")

    async def resume_command(self, event):
        """دستور ادامه پخش"""
        chat_id = event.chat_id
        
        if chat_id in self.queues:
            self.queues[chat_id].is_playing = True
            await event.respond("▶️ پخش ادامه یافت")
        else:
            await event.respond("❌ هیچ آهنگی برای ادامه وجود ندارد!")

    async def stop_command(self, event):
        """دستور توقف کامل"""
        chat_id = event.chat_id
        
        if chat_id in self.queues:
            self.queues[chat_id] = Queue(songs=[])
            await event.respond("⏹️ پخش متوقف شد")
        else:
            await event.respond("❌ هیچ آهنگی در حال پخش نیست!")

    async def skip_command(self, event):
        """دستور رد کردن"""
        chat_id = event.chat_id
        
        if chat_id in self.queues and self.queues[chat_id].songs:
            queue = self.queues[chat_id]
            queue.current_index += 1
            
            if queue.current_index >= len(queue.songs):
                if queue.loop_mode == "all":
                    queue.current_index = 0
                else:
                    await event.respond("📭 صف تمام شد!")
                    return
            
            current_song = queue.songs[queue.current_index]
            embed = self.create_song_embed(current_song, "⏭️ آهنگ بعدی")
            await event.respond(embed)
        else:
            await event.respond("❌ هیچ آهنگی برای رد کردن وجود ندارد!")

    async def queue_command(self, event):
        """دستور نمایش صف"""
        chat_id = event.chat_id
        
        if chat_id not in self.queues or not self.queues[chat_id].songs:
            await event.respond("📭 صف خالی است!")
            return
            
        queue = self.queues[chat_id]
        queue_text = "📋 **صف آهنگ‌ها:**\n\n"
        
        for i, song in enumerate(queue.songs):
            duration = f"{song.duration // 60}:{song.duration % 60:02d}"
            if i == queue.current_index:
                queue_text += f"🎵 **{i+1}. {song.title}** ({duration}) - *در حال پخش*\n"
            else:
                queue_text += f"📄 {i+1}. {song.title} ({duration})\n"
        
        await event.respond(queue_text)

    async def now_playing_command(self, event):
        """دستور نمایش آهنگ فعلی"""
        chat_id = event.chat_id
        
        if chat_id in self.queues and self.queues[chat_id].songs:
            queue = self.queues[chat_id]
            current_song = queue.songs[queue.current_index]
            embed = self.create_song_embed(current_song, "🎵 در حال پخش")
            await event.respond(embed)
        else:
            await event.respond("❌ هیچ آهنگی در حال پخش نیست!")

    async def loop_command(self, event):
        """دستور تنظیم حلقه"""
        chat_id = event.chat_id
        
        message_text = event.message.text
        args = message_text.split()
        
        if len(args) < 2:
            await event.respond("❌ لطفاً حالت حلقه را مشخص کنید: one/all/off")
            return
            
        mode = args[1].lower()
        
        if mode not in ['one', 'all', 'off']:
            await event.respond("❌ حالت نامعتبر! از one/all/off استفاده کنید")
            return
            
        if chat_id not in self.queues:
            self.queues[chat_id] = Queue(songs=[])
            
        self.queues[chat_id].loop_mode = mode
        
        mode_text = {
            'one': '🔄 تکرار یک آهنگ',
            'all': '🔁 تکرار کل صف',
            'off': '⏹️ بدون تکرار'
        }
        
        await event.respond(f"✅ حالت حلقه: {mode_text[mode]}")

    async def volume_command(self, event):
        """دستور تنظیم صدا"""
        chat_id = event.chat_id
        
        message_text = event.message.text
        args = message_text.split()
        
        if len(args) < 2:
            await event.respond("❌ لطفاً سطح صدا (0-100) را وارد کنید!")
            return
            
        try:
            vol = int(args[1])
            if not 0 <= vol <= 100:
                await event.respond("❌ سطح صدا باید بین 0 تا 100 باشد!")
                return
                
            if chat_id not in self.queues:
                self.queues[chat_id] = Queue(songs=[])
                
            self.queues[chat_id].volume = vol
            await event.respond(f"🔊 سطح صدا: {vol}%")
            
        except ValueError:
            await event.respond("❌ لطفاً عدد معتبر وارد کنید!")

    async def lyrics_command(self, event):
        """دستور دریافت متن آهنگ"""
        message_text = event.message.text
        args = message_text.split()
        
        if len(args) < 2:
            await event.respond("❌ لطفاً نام آهنگ را وارد کنید!")
            return
            
        song_name = ' '.join(args[1:])
        
        try:
            lyrics_text = await self.get_lyrics(song_name)
            if lyrics_text:
                await event.respond(f"📝 **متن آهنگ {song_name}:**\n\n{lyrics_text[:1000]}...")
            else:
                await event.respond("❌ متن آهنگ یافت نشد!")
                
        except Exception as e:
            logger.error(f"خطا در دریافت متن آهنگ: {e}")
            await event.respond("❌ خطا در دریافت متن آهنگ!")

    async def get_lyrics(self, song_name: str) -> Optional[str]:
        """دریافت متن آهنگ از API"""
        try:
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

    async def autodj_command(self, event):
        """دستور Auto-DJ"""
        chat_id = event.chat_id
        
        if chat_id not in self.queues:
            self.queues[chat_id] = Queue(songs=[])
            
        self.queues[chat_id].auto_dj = not self.queues[chat_id].auto_dj
        
        status = "فعال" if self.queues[chat_id].auto_dj else "غیرفعال"
        await event.respond(f"🤖 Auto-DJ {status} شد!")

    async def run(self):
        """اجرای Userbot"""
        print("🚀 شروع Userbot موسیقی...")
        print("⚠️ هشدار: این Userbot برای استفاده آموزشی است!")
        
        try:
            # تلاش برای اتصال با کلمه عبور اپلیکیشن
            if self.app_password:
                await self.client.start(phone=self.phone, password=self.app_password)
                print("✅ Userbot با کلمه عبور اپلیکیشن متصل شد!")
            else:
                await self.client.start(phone=self.phone)
                print("✅ Userbot متصل شد!")
        except Exception as e:
            print(f"❌ خطا در اتصال: {e}")
            print("💡 اگر تایید دو مرحله‌ای فعال است، APP_PASSWORD را در فایل .env تنظیم کنید")
            return
        
        print("🎵 Userbot آماده دریافت دستورات است!")
        
        # نگه داشتن Userbot فعال
        await self.client.run_until_disconnected()

if __name__ == "__main__":
    # بارگذاری متغیرهای محیطی از فایل .env
    from dotenv import load_dotenv
    load_dotenv()
    
    # بررسی وجود متغیرهای محیطی
    required_env_vars = ['API_ID', 'API_HASH', 'PHONE']
    missing_vars = [var for var in required_env_vars if not os.getenv(var)]
    
    if missing_vars:
        print(f"❌ متغیرهای محیطی زیر تنظیم نشده‌اند: {', '.join(missing_vars)}")
        print("لطفاً فایل .env را بررسی کنید.")
        exit(1)
    
    userbot = TelegramUserbot()
    
    try:
        asyncio.run(userbot.run())
    except KeyboardInterrupt:
        print("\n👋 Userbot متوقف شد.")
    except Exception as e:
        print(f"❌ خطا: {e}") 