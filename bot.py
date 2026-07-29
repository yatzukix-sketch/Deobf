#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Deobf Bot — Discord komut botu (.l prefix)
TOKEN KESINLIKLE .env / environment'tan gelir, koda GOMMEK YASAK.
  .l <url>              -> siteyi/pastes/raw linkini fetchle, deobf et, deobf.txt at
  .l (+ txt ek dosya)   -> ek dosyayi indir, deobf et
  .y                    -> yardim
"""
import os, io, traceback
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
bot = commands.Bot(command_prefix=".", intents=intents, help_command=None)

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


@bot.command(name="y")
async def yardim(ctx):
    await ctx.send(
        "```\nDeobf Bot v1.0\n"
        ".l <url>        -> linkteki raw scripti fetchle + deobf et\n"
        ".l (txt ekle)   -> ek dosyayi deobf et\n"
        "Cikti: deobf.txt + strings.txt (+ payload.bin varsa)\n"
        "Not: agir Luraph/LuaProt VM cozumu Sensei tarafindan yapilir.\n```"
    )


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
