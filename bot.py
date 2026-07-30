#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Deobf Bot — Discord komut botu (.l prefix)
TOKEN KESINLIKLE .env / environment'tan gelir, koda GOMMEK YASAK.
  .l <url>              -> siteyi/pastes/raw linkini fetchle, deobf et, deobf.txt at
  .l (+ txt ek dosya)   -> ek dosyayi indir, deobf et
  .y                    -> yardim
"""
import os, io, re, traceback
import discord
from discord.ext import commands

import deobf


def _load_dotenv(path=".env"):
    """Mini .env okuyucu (ek kutuphane yok): KEY=VALUE satirlari env'e yuklenir."""
    try:
        with open(path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                k, v = line.split("=", 1)
                os.environ.setdefault(k.strip(), v.strip().strip('"').strip("'"))
    except FileNotFoundError:
        pass

_load_dotenv()

TOKEN = os.environ.get("DISCORD_TOKEN")
if not TOKEN:
    raise SystemExit("DISCORD_TOKEN env degiskeni yok! .env dosyasina koy.")

intents = discord.Intents.default()
intents.message_content = True
bot = commands.Bot(command_prefix=[".", "!"], intents=intents, help_command=None)

MAX_FETCH = 15 * 1024 * 1024   # 15MB guvenlik limiti
MAX_DISCORD_MSG = 1800


async def _send_outputs(ctx, report: str, outputs: dict[str, bytes]):
    if len(report) > MAX_DISCORD_MSG:
        report = report[:MAX_DISCORD_MSG] + "\n…(kisaltildi)"
    await ctx.send(f"```\n{report}\n```")
    for name, data in outputs.items():
        if len(data) > 8 * 1024 * 1024:
            await ctx.send(f"⚠️ `{name}` 8MB ustu ({len(data):,}B), atıyorum: Sensei'ye yolla.")
            continue
        await ctx.send(file=discord.File(io.BytesIO(data), filename=name))


@bot.event
async def on_ready():
    print(f"[+] Deobf Bot online: {bot.user}")


HELP_TEXT = (
    "```\n"
    "=========== DEOBF BOT v1.3 ===========\n"
    ".l <script/link> -> DEOBF | WRD: 938/938 string (dogrulanmis) + 1300+ sabit inline + hizali kod\n"
    "Prefix: .  ve  !  (ikisi de calisir)\n"
    "\n"
    ".help               -> bu menu (komutlar + amaclari)\n"
    ".l <url>            -> script linkini fetchle + TAM deobf\n"
    "                       (teshis + hex/b64 coz + XSUB blob + strings)\n"
    ".l (txt/lua ekle)   -> ek dosyayi deobf et\n"
    ".get <url>          -> AKILLI CEKICI: raw-yol radari + tarayici maskesi\n"
    "                       ile scripti soker; HTML ise icerdeki kodu koparir,\n"
    "                       onizleme + ham dosya atar (deobf YOK)\n"
    "\n"
    "RADAR (otomatik raw'a cevrilen hostlar):\n"
    "  pastebin, paste.c-net, gist, github blob, gitlab, rentry,\n"
    "  hastebin, pastefy, sourcebin, controlc, paste.ee, xhider\n"
    "\n"
    "Cikti: deobf.txt + strings.txt (+ payload.bin varsa)\n"
    "Not: agir Luraph/LuaProt VM cozumu Sensei tarafindan yapilir.\n"
    "```"
)

@bot.command(name="help", aliases=["y", "yardim", "h"])
async def help_cmd(ctx):
    await ctx.send(HELP_TEXT)


@bot.command(name="get")
async def smart_get(ctx, url: str = None):
    if not url:
        return await ctx.send("Kullanim: `.get <url>` — script sayfasini/api linkini ver, icerigini cikarayim.")
    m = re.search(r"https?://[^\s\"'<>)]+", url)  # loadstring sarmalini sok
    if m: url = m.group(0)
    try:
        async with ctx.typing():
            data, iz = await bot.loop.run_in_executor(None, deobf.smart_fetch, url)
        if len(data) > 8 * 1024 * 1024:
            return await ctx.send(f"⚠️ Icerik 8MB ustu ({len(data):,}B).")
        text = data.decode("utf-8", "replace")
        # HTML ise icerdeki kodu kopar
        if "<html" in text[:2000].lower() or "<!doc" in text[:2000].lower():
            ex = deobf.extract_script_from_html(text)
            if ex:
                text, veri = ex, "HTML icinden script blogu sokuldu"
            else:
                veri = "HTML ama script blogu bulunamadi, sayfa oldugu gibi verildi"
        else:
            veri = "ham icerik"
        preview = text[:1000].replace("`", "'")
        fname = (url.split("/")[-1] or "script").split("?")[0][:40] or "script"
        if "." not in fname: fname += ".txt"
        await ctx.send(
            f"```\n🎯 .get SONUC\niz: {iz}\nmod: {veri}\nboyut: {len(text):,} char\n\n— ONIZLEME —\n{preview}\n```"
        )
        await ctx.send(file=discord.File(io.BytesIO(text.encode()), filename=fname))
    except Exception as e:
        await ctx.send(f"💥 .get patladi: `{type(e).__name__}: {e}`")


@bot.command(name="l")
async def load_and_deobf(ctx, url: str = None):
    try:
        name, content = None, None
        if ctx.message.attachments:
            att = ctx.message.attachments[0]
            if att.size > MAX_FETCH:
                return await ctx.send(f"⚠️ Dosya cok buyuk ({att.size:,}B). limit {MAX_FETCH//1024//1024}MB.")
            content = await att.read()
            name = att.filename
        elif url:
            m = re.search(r"https?://[^\s\"'<>)]+", url)  # loadstring(game:HttpGet("URL"))() sarmalini sok
            if m: url = m.group(0)
            url = deobf.normalize_raw_url(url)
            async with ctx.typing():
                raw = await bot.loop.run_in_executor(None, deobf.fetch, url)
            if len(raw) > MAX_FETCH:
                return await ctx.send("⚠️ Icerik cok buyuk, kirptim degil — yollamiyorum.")
            content, name = raw, url.split("/")[-1] or "target"
        else:
            return await ctx.send("Kullanim: `.l <url>` veya txt dosyasi ekle. `.y` = yardim")

        async with ctx.typing():
            report, outputs = await bot.loop.run_in_executor(None, deobf.deobf_pipeline, name, content)
        await _send_outputs(ctx, report, outputs)
    except Exception as e:
        tb = traceback.format_exc(limit=3)
        print(tb)
        await ctx.send(f"💥 patladik: `{type(e).__name__}: {e}` (log'a yazdim)")


if __name__ == "__main__":
    bot.run(TOKEN)
