#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Deobf Bot v1.6 — Discord komut botu
TOKEN KESINLIKLE .env / environment'tan gelir, koda GOMMEK YASAK.
  .l <url/dosya>   -> deobf pipeline (WRD 938/938 + katman-2 haritasi)
  .aly <url/dosya> -> SENSEI-AI v2 kanit-disiplinli analiz (sallama YOK)
  .sor <soru>      -> son analize dair soru-cevap
  .sohbet          -> kisa sureligine konusma modu (kapat: 'cik')
  .diff <a> <b>    -> iki scripti karsilastir (gizli degisiklik yakalama)
  .get <url>       -> akilli cekici
  .istatistik      -> oturum sayaclari
  .y               -> bu menu
"""
import os, io, re, time, random, difflib, traceback
import discord
from discord.ext import commands

import deobf, analyzer, chatmod


def _load_dotenv(path=".env"):
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

MAX_FETCH = 15 * 1024 * 1024
MAX_DISCORD_MSG = 1800
START_TS = time.monotonic()
STATS = {"l": 0, "get": 0, "aly": 0, "diff": 0, "sor": 0}
URL_RX = re.compile(r'https?://[^\s"\'<>()]+')

# .aly sonrasi sohbet altyapisi
SONS = {}     # channel_id -> {"R":..., "name":..., "kaynak":..., "ek":..., "ts":...}
SOHBET = {}   # (channel_id, user_id) -> expire_ts
SOHBET_SURESI = 300  # sn, her mesajda +120 yenilenir

TIPS = [
    "💡 .aly artik kanit-disiplinli: sadece ADI GECEN ozellikler ayrilir, iddia edilmez.",
    "💡 .diff ile guncellenen hub'dan WEBHOOK cikarsa, onceki surumune don!",
    "💡 LuaProt = lisans duvari; asil kod uzak sunucuda, izini GOLGE surer.",
    "💡 WRD katman-2 haritasi = wrd_katman2.txt (876 site).",
    "💡 pastebin linki yerine dosyayi surukle-birak: ayni hiz.", 
    "💡 .get raw-yol radarindan 12 host tanir.",
]

Q_SONUC = [
    "Sensei: 'analiz dedigin boyle olur cigerim.'",
    "Cirak: 'hocam bu script beni cagirdi sanki...'",
    "GOLGE: sessizce izini suruyor... 🕶️",
    "Kisla standardi: once suphe, sonra guven.",
    "Sensei cikmazi: kanitsiz deobf olmaz.",
]


async def _send_outputs(ctx, report: str, outputs: dict):
    if len(report) > MAX_DISCORD_MSG:
        report = report[:MAX_DISCORD_MSG] + "\n…(kisaltildi)"
    await ctx.send(f"```\n{report}\n```")
    for name, data in outputs.items():
        if len(data) > 8 * 1024 * 1024:
            await ctx.send(f"⚠️ `{name}` 8MB ustu ({len(data):,}B), atıyorum: Sensei'ye yolla.")
            continue
        await ctx.send(file=discord.File(io.BytesIO(data), filename=name))


def _rcs(lst):
    return random.choice(lst)


@bot.event
async def on_ready():
    print(f"[+] Deobf Bot online: {bot.user}")


# -------------------- HELP (embed UI) --------------------
@bot.command(name="help", aliases=["y", "yardim", "h"])
async def help_cmd(ctx):
    e = discord.Embed(
        title="⚔️ DEOBF BOT v1.6 — komut karargahi",
        description="Kisla Akademisi'nin sahadaki eli. Prefix: `.` veya `!`\n🆕 **kanit-disiplinli analiz + analiz uzerinden sohbet**",
        color=0x9B59B6,
    )
    e.add_field(name="🧪 .l <url/dosya>", value=(
        "TAM deobf pipeline: teshis + hex/b64 cozme + XSUB blob +\n"
        "WRD katman-1 (938/938 string, runtime-dogrulamali) + 1300+ inline +\n"
        "katman-2 haritasi (wrd_katman2.txt)"), inline=False)
    e.add_field(name="🕵️ .aly <url/dosya>", value=(
        "SENSEI-AI v2 kanit-disiplinli analiz: ozellik tespiti artik KANIT gerektirir.\n"
        "Kelime gorup 'noclip var!' demiyoruz — calisan kod izini gosteriyoruz.\n"
        "Kesin olmayanlar 'adi gecenler' rafinda, boynumuz kildan ince 😄"), inline=False)
    e.add_field(name="💬 .sor <soru> / .sohbet", value=(
        ".aly sonrasi bota soru sor: 'güvenli mi?', 'hitbox var mı?', 'remote'lar ne yapıyor?'\n"
        "`.sohbet` = 5dk konusma modu (kapatmak icin `cik` yaz)."), inline=False)
    e.add_field(name="🆚 .diff <link1> <link2>", value=(
        "Iki script surumunu karsilastirir: benzerlik % + eklenen riskli desenler.\n"
        "Hub guncellendi diye arkaniza webcam loglayici kacirmalarina son."), inline=False)
    e.add_field(name="🎯 .get <url>", value=(
        "Akilli cekici: 12-host raw radar + tarayici maskesi, HTML icinden\n"
        "scripti soker, onizleme + ham dosya atar (deobf YOK)"), inline=False)
    e.add_field(name="📊 .istatistik", value="oturum sayaclari (kac .l, .aly, .diff...)", inline=True)
    e.add_field(name="📎 not", value="dosya surukle-birak da calisir (.l/.aly: ilk ek dosyayi alir)", inline=True)
    e.add_field(name="🌍 Radar hostlari", value=(
        "pastebin, paste.c-net, gist, github blob, gitlab, rentry,\n"
        "hastebin, pastefy, sourcebin, controlc, paste.ee, xhider"), inline=False)
    e.set_footer(text=_rcs(TIPS))
    await ctx.send(embed=e)


# -------------------- .get (ayni, ufak makyaj) --------------------
@bot.command(name="get")
async def smart_get(ctx, url: str = None):
    if not url:
        return await ctx.send("Kullanim: `.get <url>` — script sayfasini/api linkini ver, icerigini cikarayim.")
    m = URL_RX.search(url)
    if m: url = m.group(0)
    try:
        async with ctx.typing():
            data, iz = await bot.loop.run_in_executor(None, deobf.smart_fetch, url)
        if len(data) > 8 * 1024 * 1024:
            return await ctx.send(f"⚠️ Icerik 8MB ustu ({len(data):,}B).")
        text = data.decode("utf-8", "replace")
        if "<html" in text[:2000].lower() or "<!doc" in text[:2000].lower():
            ex = deobf.extract_script_from_html(text)
            if ex:
                text, veri = ex, "HTML icinden script blogu sokuldu"
            else:
                veri = "HTML ama script blogu bulunamadi, sayfa oldugu gibi verildi"
        else:
            veri = "ham icerik"
        preview = text[:900].replace("`", "'")
        fname = (url.split("/")[-1] or "script").split("?")[0][:40] or "script"
        if "." not in fname: fname += ".txt"
        e = discord.Embed(title="🎯 .get SONUC", color=0x3498DB,
                          description=f"```\nboyut: {len(text):,} char | mod: {veri}\niz: {iz}\n```")
        e.add_field(name="— ONIZLEME —", value=f"```lua\n{preview}\n```"[:1024], inline=False)
        await ctx.send(embed=e)
        await ctx.send(file=discord.File(io.BytesIO(text.encode()), filename=fname))
        STATS["get"] += 1
    except Exception as e2:
        await ctx.send(f"💥 .get patladi: `{type(e2).__name__}: {e2}`")


# -------------------- .l (pipeline) --------------------
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
            m = URL_RX.search(url)
            if m: url = m.group(0)
            url = deobf.normalize_raw_url(url)
            async with ctx.typing():
                raw = await bot.loop.run_in_executor(None, deobf.fetch, url)
            if len(raw) > MAX_FETCH:
                return await ctx.send("⚠️ Icerik cok buyuk.")
            content, name = raw, url.split("/")[-1] or "target"
        else:
            return await ctx.send("Kullanim: `.l <url>` veya txt dosyasi ekle. `.y` = yardim")
        async with ctx.typing():
            report, outputs = await bot.loop.run_in_executor(None, deobf.deobf_pipeline, name, content)
        await _send_outputs(ctx, report, outputs)
        STATS["l"] += 1
    except Exception as ex:
        print(traceback.format_exc(limit=3))
        await ctx.send(f"💥 patladik: `{type(ex).__name__}: {ex}` (log'a yazdim)")


# -------------------- .aly  (SENSEI-AI v2) --------------------
def _aly_embed(name, text, R: dict, ek: str):
    baslik, renk, sahis = analyzer.BAND_BILGI[R["band"]]
    e = discord.Embed(title=f"🕵️ SENSEI-AI Analiz — {name[:60]}",
                      description=f"### {baslik}\n{analyzer.gauge(R['skor'])}  **%{R['skor']} risk skoru**\n_{sahis}_",
                      color=renk)
    # KANITLI tespitler: ustune yemin ederiz :)
    if R["amac_kesin"]:
        satirlar = []
        for etiket, kanitlar in R["amac_kesin"][:6]:
            satirlar.append(f"**{etiket}**")
            for tag, sn in kanitlar:
                satirlar.append(f"└ `{tag}: {sn}`")
        e.add_field(name="✅ KANITLI tespitler (calisan kod izi var)",
                    value="\n".join(satirlar)[:1024], inline=False)
    # sadece adi gecenler: sallama rafimizd, kesinlik iddiasi YOK
    if R["amac_gecen"]:
        sat = [f"🔎 {etiket} (×{n} adı geciyor)" for etiket, n in R["amac_gecen"][:8]]
        e.add_field(name="❓ sadece ADI GECEN — kanit bulamadim, kesin demek degil",
                    value="\n".join(sat)[:1024], inline=False)
    if not R["amac_kesin"] and not R["amac_gecen"]:
        e.add_field(name="🎯 ne yapıyor", value="\n".join(R["amac"])[:1024] or "—", inline=False)
    bilgi = (f"🏷️ tur: `{R['tur']}`\n📏 {len(text):,} byte, {text.count(chr(10))+1} satir\n"
             f"⚙️ servisler: {', '.join(R['servisler'][:8]) or '—'}")
    if ek: bilgi += f"\n{ek}"
    e.add_field(name="ℹ️ bilgi", value=bilgi[:1024], inline=False)
    if R["bulgular"]:
        satirlar = []
        for p, k2, a, kts in R["bulgular"][:6]:
            satirlar.append(f"**+{p}** {a}")
            for tag, sn in kts[:1]:
                satirlar.append(f"└ `{tag}: {sn[:80]}`")
        e.add_field(name="⚠️ supheli desenler (kanitli)", value="\n".join(satirlar)[:1024], inline=False)
    if R["uzaklar"]:
        sat = [f"`{u['isim']}` ×{u['adet']}" + (f" — {u['ipucu']}" if u['ipucu'] else "")
               for u in R["uzaklar"][:8]]
        sat.append(f"FireServer ×{R['fires']} | InvokeServer ×{R['invs']}")
        e.add_field(name="📡 remote izleri (+ amac tahmini)", value="\n".join(sat)[:1024], inline=False)
    if R["urller"]:
        e.add_field(name="🌐 dis iletisim", value="\n".join(R["urller"][:6])[:1024], inline=False)
    e.set_footer(text=f"{_rcs(Q_SONUC)} | ⚖️ huristiktir, %100 kanit degildir | 💬 soru sor: .sor  konus: .sohbet")
    return e


@bot.command(name="aly", aliases=["analiz"])
async def aly_cmd(ctx, url: str = None):
    try:
        name, content = None, None
        if ctx.message.attachments:
            att = ctx.message.attachments[0]
            if att.size > MAX_FETCH:
                return await ctx.send(f"⚠️ Dosya cok buyuk ({att.size:,}B).")
            content, name = await att.read(), att.filename
        elif url:
            m = URL_RX.search(url)
            if m: url = m.group(0)
            if url.startswith("http"):
                url = deobf.normalize_raw_url(url)
                async with ctx.typing():
                    raw = await bot.loop.run_in_executor(None, deobf.fetch, url)
                content, name = raw, url.split("/")[-1] or "hedef"
            else:
                content, name = url.encode(), "inline-kod"
        else:
            return await ctx.send("Kullanim: `.aly <url>` veya dosya ekle veya `.aly <kod>`")
        text = content.decode("utf-8", "replace")
        ek_not, ek_havuz = "", ""
        # obf ise once v1.4 cozucu: decoded stringler de analiz havuzuna
        if "wearedevs.net/obfuscator" in text or "luaprot" in text.lower() or "LPH" in text[:2000]:
            try:
                async with ctx.typing():
                    _, outputs = await bot.loop.run_in_executor(None, deobf.deobf_pipeline, name, content)
                parcalar = []
                for ad in ("wrd_strings.txt", "strings.txt", "deobf.txt"):
                    if ad in outputs:
                        lim = 60000 if ad == "deobf.txt" else 200000
                        parcalar.append(outputs[ad][:lim].decode("utf-8", "replace"))
                ek_havuz = "\n".join(parcalar)
                ek_not = "🧬 obfuscator cozuldu, decoded metin tarandi"
            except Exception:
                ek_not = "⚠️ obf cozucu patladi, sadece ham metin tarandi"
        R = analyzer.analyze(name, text, ek_havuz)
        await ctx.send(embed=_aly_embed(name, text, R, ek_not))
        # sohbet icin hafizaya al (kanal basina son analiz)
        SONS[ctx.channel.id] = {"R": R, "name": name, "ts": time.time(),
                                "kaynak": text[:80000], "ek": ek_havuz[:60000]}
        STATS["aly"] += 1
    except Exception as ex:
        print(traceback.format_exc(limit=3))
        await ctx.send(f"💥 .aly patladi: `{type(ex).__name__}: {ex}`")


# -------------------- .diff (Sensei fikri!) --------------------
@bot.command(name="diff", aliases=["karsilastir"])
async def diff_cmd(ctx, urlA: str = None, urlB: str = None):
    if not (urlA and urlB):
        return await ctx.send("Kullanim: `.diff <link1> <link2>` — iki surumu karsilastiririm.")
    try:
        async with ctx.typing():
            dA, _ = await bot.loop.run_in_executor(None, deobf.smart_fetch, urlA)
            dB, _ = await bot.loop.run_in_executor(None, deobf.smart_fetch, urlB)
        tA = dA.decode("utf-8", "replace")
        tB = dB.decode("utf-8", "replace")
        oran = difflib.SequenceMatcher(None, tA, tB).ratio() * 100
        sm = difflib.SequenceMatcher(None, tA.splitlines(), tB.splitlines())
        eklenen = sum(i2 - i1 for _, i1, _, i2, _ in sm.get_opcodes())
        yeni_satirlar = []
        for tag, a1, a2, b1, b2 in sm.get_opcodes():
            if tag in ("insert", "replace"):
                yeni_satirlar += tB.splitlines()[b1:b2][:800]
        yeni_metin = "\n".join(yeni_satirlar)
        R = analyzer.analyze("eklenen-kisim", yeni_metin) if yeni_satirlar else None
        renk = 0x2ECC71 if oran >= 97 else (0xF1C40F if oran >= 85 else 0xE67E22)
        e = discord.Embed(title="🆚 DIFF RAPORU — iki surum savas alani",
                          description=(f"📊 benzerlik: **%{oran:.1f}**\n"
                                       f"A: {len(tA):,}B | B: {len(tB):,}B\n"
                                       f"degisen satir: ~{eklenen}"), color=renk)
        if R and R["bulgular"]:
            e.add_field(name="🚨 B'de BELIREN yeni riskler",
                        value="\n".join(f"**+{p}** {a}" for p, k2, a, _kt in R["bulgular"][:6])[:1024], inline=False)
        elif yeni_satirlar:
            e.add_field(name="✅ yeni kisimlarda riskli desen yok",
                        value="eklenen kisim zararsiz gorunuyor (ama obf barindiriyorsa .aly onerilir)", inline=False)
        esk_url = set(re.findall(r"https?://[^\s\"'<>\)\]]+", tA))
        yen_url = set(re.findall(r"https?://[^\s\"'<>\)\]]+", tB)) - esk_url
        if yen_url:
            e.add_field(name="🌐 B'de YENI url'ler", value="\n".join(sorted(yen_url)[:6])[:1024], inline=False)
        e.set_footer(text="Sensei fikri: 'guncelleme almadan once .diff, helal gecesi .aly.'")
        await ctx.send(embed=e)
        STATS["diff"] += 1
    except Exception as ex:
        await ctx.send(f"💥 .diff patladi: `{type(ex).__name__}: {ex}`")


# -------------------- .istatistik --------------------
@bot.command(name="istatistik", aliases=["stat", "stats"])
async def stat_cmd(ctx):
    up = int(time.monotonic() - START_TS)
    dk, sn = up // 60, up % 60
    e = discord.Embed(title="📊 DEOBF BOT — oturum karnesi", color=0x1ABC9C,
                      description=(f"⏱️ ayakta: **{dk}dk {sn}sn**\n"
                                   f"🧪 .l → **{STATS['l']}** | 🕵️ .aly → **{STATS['aly']}**\n"
                                   f"🆚 .diff → **{STATS['diff']}** | 🎯 .get → **{STATS['get']}**\n"
                                   f"💬 .sor → **{STATS['sor']}** | 🗣️ aktif sohbet: **{len(SOHBET)}**"))
    e.set_footer(text=_rcs(TIPS))
    await ctx.send(embed=e)


# -------------------- SOHBET MODU (Sensei ile konus) --------------------
def _sohbet_ctx(ctx):
    bagim = SONS.get(ctx.channel.id)
    if not bagim:
        return None
    return {"R": bagim["R"], "name": bagim["name"],
            "kaynak": bagim["kaynak"], "ek": bagim["ek"]}


@bot.event
async def on_message(message):
    if message.author.bot:
        return
    # komutsa normal aksin (.l, .aly, .sor ...)
    ctx = await bot.get_context(message)
    if ctx.valid:
        return await bot.process_commands(message)
    # konusma modu acik mi?
    if not message.guild:  # DM'lerde sadece komutlar
        return
    anahtarli = None
    for (chid, uid), son in list(SOHBET.items()):
        if message.channel.id == chid and message.author.id == uid:
            anahtarli = (chid, uid)
            if son < time.time():
                del SOHBET[anahtarli]
                await message.reply("🗣️ Sohbet suresi doldu; tekrar acmak icin `.sohbet`.")
                return
    if not anahtarli:
        return
    # sohbet icerigi
    icerik = message.content.strip()
    if not icerik:
        return
    if icerik.lower() in ("cik", "çık", "dur", "yeter", "kapat", "stop"):
        del SOHBET[anahtarli]
        return await message.reply("🗣️ Sohbet kapatildi. Dagda erismek istersen `.sohbet` yaz! 😄")
    sonu = _sohbet_ctx(message)
    yanıt = chatmod.cevap(icerik, sonu) if sonu else chatmod.cevap(icerik, {"R": None})
    SOHBET[anahtarli] = time.time() + 120  # yenile
    if len(yanıt) > MAX_DISCORD_MSG:
        yanıt = yanıt[:MAX_DISCORD_MSG] + "…"
    await message.reply(yanıt)
    STATS["sor"] += 1


@bot.command(name="sor", aliases=["s", "soru"])
async def sor_cmd(ctx, *, soru: str = None):
    if not soru:
        return await ctx.send("Kullanim: `.sor <soru>` — ornek: `.sor bu scriptte noclip var mi?`\n"
                              "Ya da `.sohbet` ile konusma modu ac.")
    sonu = _sohbet_ctx(ctx)
    if not sonu:
        return await ctx.send("🗣️ Bu kanalda henuz bir .aly analizi yok. Once `.aly <url/dosya>` at, sonra danis!")
    try:
        yanıt = chatmod.cevap(soru, sonu)
        if len(yanıt) > MAX_DISCORD_MSG:
            yanıt = yanıt[:MAX_DISCORD_MSG] + "…"
        await ctx.reply(yanıt)
        STATS["sor"] += 1
    except Exception as ex:
        await ctx.send(f"💥 .sor patladi: `{type(ex).__name__}: {ex}`")


@bot.command(name="sohbet", aliases=["chat", "c", "konus"])
async def sohbet_cmd(ctx):
    anahtarli = (ctx.channel.id, ctx.author.id)
    if anahtarli in SOHBET:
        del SOHBET[anahtarli]
        return await ctx.send("🗣️ Sohbet modu kapatildi. Sorduklarin aklinde kalsin! 😄")
    if ctx.channel.id not in SONS:
        return await ctx.send("🗣️ Once `.aly <url/dosya>` calistir ki hakkinda konusacagimiz bir analiz olsun!")
    SOHBET[anahtarli] = time.time() + SOHBET_SURESI
    e = discord.Embed(title="🗣️ SOHBET MODU ACILDI", color=0xE91E63,
                      description=("Bundan sonra bu kanalda yazdigin NORMAL mesajlara "
                                   "(komut olmayan) Sensei cevap verir.\n\n"
                                   "Ornekler: `güvenli mi?` • `hitbox var mı?` • `remote'lar ne yapıyor?`\n"
                                   "• `webhook var mı?` • `\"ParryEvent\" ne?`\n\n"
                                   f"Otomatik kapanis: **{SOHBET_SURESI//60} dk** sonra (aktifken her mesaj +2dk ekler).\n"
                                   "Kapatmak icin: `cik` veya `.sohbet`."))
    e.set_footer(text="Not: ben kural tabaniyim, internete bagli AI degilim — abartma beni 😄")
    await ctx.send(embed=e)


if __name__ == "__main__":
    bot.run(TOKEN)
