#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Deobf Bot v1.8 — Discord komut botu
TOKEN KESINLIKLE .env / environment'tan gelir, koda GOMMEK YASAK.
  .l <url/dosya>   -> deobf pipeline (WRD 938/938 + katman-2 haritasi)
  .aly <url/dosya> -> SENSEI-AI v2.3 kanit-disiplinli + ZINCIR takibi
  .sor <soru>      -> son analize dair soru-cevap
  .sohbet          -> kisa sureligine konusma modu (kapat: 'cik')
  .rt <url/dosya>  -> RUNTIME deobf: Prometheus mock-trace motoru
                      (kendi lua51'iyle; katman-2 plaintext avcisi!)
  .diff <a> <b>    -> iki scripti karsilastir (gizli degisiklik yakalama)
  .get <url>       -> akilli cekici
  .istatistik      -> oturum sayaclari
  .y               -> bu menu
"""
import os, io, re, time, random, difflib, traceback, subprocess, tempfile, shutil, logging
import discord
from discord.ext import commands

# Logging yapılandırması
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("bot.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("Deobf.Bot")

import deobf, analyzer, chatmod
import security, stealer_detect

OWNER_ID = security.get_owner_id()


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
STATS = {"l": 0, "get": 0, "aly": 0, "diff": 0, "sor": 0, "rt": 0}
URL_RX = re.compile(r'https?://[^\s"\'<>()]+')


# -------------------- KONTROL 3: yetki & hız sınırı --------------------
def privileged():
    """Sadece bot sahibi veya 'Sunucuyu Yönet' yetkilisi çalıştırabilir."""
    async def predicate(ctx):
        if security.owner_or_manage_guild(ctx):
            return True
        raise commands.CheckFailure(
            "⛔ Bu komut sadece bot sahibine / sunucu yöneticisine açık.")
    return commands.check(predicate)


async def _fetch_budgele(ctx, key=None) -> bool:
    """Kanal başına istek bütçesi — aşarsa uyarır ve engeller."""
    key = key or f"ch:{ctx.channel.id}"
    ok, kalan = security.fetch_budget_ok(key, limit=8, window=60)
    if not ok:
        await ctx.send("🐢 Çok hızlı! Bu kanalda 60 sn'de en fazla 8 istek. "
                       "Biraz soluklan tekrar dene.")
        return False
    return True


@bot.event
async def on_command_error(ctx, error):
    if isinstance(error, commands.CommandOnCooldown):
        await ctx.send(f"🐢 Bu komut beklemede: {error.retry_after:.0f} sn sonra "
                       f"tekrar dene (hız sınırı).", delete_after=10)
    elif isinstance(error, commands.CheckFailure):
        await ctx.send(str(error), delete_after=10)
    elif isinstance(error, commands.CommandNotFound):
        return
    else:
        logger.error(f"komut hatası: {error}")

# .aly sonrasi sohbet altyapisi
SONS = {}     # channel_id -> {"R":..., "name":..., "kaynak":..., "ek":..., "ts":...}
SOHBET = {}   # (channel_id, user_id) -> expire_ts
SOHBET_SURESI = 300  # sn, her mesajda +120 yenilenir

TIPS = [
    "💡 .aly artik kanit-disiplinli: sadece ADI GECEN ozellikler ayrilir, iddia edilmez.",
    "💡 Zincir takibi: loader linklerinin ardindaki kodu da .aly tarar — 2. linkteki webhook kacamaz.",
    "💡 Statik motor mu kirdi? `.rt` yaz — Prometheus dumper'i lua51'imizle sahnede (yine de goz ucuyla).",
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
    logger.info(f"Deobf Bot online: {bot.user}")


# -------------------- HELP (embed UI) --------------------
@bot.command(name="help", aliases=["y", "yardim", "h"])
async def help_cmd(ctx):
    e = discord.Embed(
        title="⚔️ DEOBF BOT v1.7 — komut karargahi",
        description="Kisla Akademisi'nin sahadaki eli. Prefix: `.` veya `!`\n🆕 **kanit-disiplinli analiz + sohbet + ZINCIR link takibi**",
        color=0x9B59B6,
    )
    e.add_field(name="🧪 .l <url/dosya>", value=(
        "TAM deobf pipeline: teshis + hex/b64 cozme + XSUB blob +\n"
        "WRD katman-1 (938/938 string, runtime-dogrulamali) + 1300+ inline +\n"
        "katman-2 haritasi (wrd_katman2.txt)"), inline=False)
    e.add_field(name="🕵️ .aly <url/dosya>", value=(
        "SENSEI-AI v2.3: kanit-disiplinli (sallama YOK) + **ZINCIR TAKIBI** 🔗\n"
        "Script icindeki HttpGet/loadstring linklerini bizzat ceker, onlari da tarar\n"
        "(derinlik 2, ust sinir 4 link). Loader arkasina webhook saklayan korksun 😄"), inline=False)
    e.add_field(name="💬 .sor <soru> / .sohbet", value=(
        ".aly sonrasi bota soru sor: 'güvenli mi?', 'hitbox var mı?', 'remote'lar ne yapıyor?'\n"
        "`.sohbet` = 5dk konusma modu (kapatmak icin `cik` yaz)."), inline=False)
    e.add_field(name="⚡ .rt <url/dosya>", value=(
        "RUNTIME deobf: Prometheus mock-trace motoru (kendi lua51'iyle kutudan cikar).\n"
        "Statik motorun durdurdugu WRD katman-2 sifreli stringleri plaintext'e cevirir.\n"
        "Emülasyondur — kismi rekonstruksiyon cikabilir; kaniti .aly ile teyit et!"), inline=False)
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
@commands.cooldown(4, 30, commands.BucketType.channel)
async def smart_get(ctx, url: str = None):
    if not url:
        return await ctx.send("Kullanim: `.get <url>` — script sayfasini/api linkini ver, icerigini cikarayim.")
    if not await _fetch_budgele(ctx):
        return
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
@commands.cooldown(2, 30, commands.BucketType.channel)
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
            if not await _fetch_budgele(ctx):
                return
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


# -------------------- .aly  (SENSEI-AI v2.3 + zincir) --------------------
def _aly_embed(name, text, R: dict, ek: str, zincir=None, stealer=None):
    karar_lbl, renk, karar_acik = analyzer.karar(R)
    # ---- STEALER ALARMI varsa kartı kırmızıya boya ----
    s_alarm = ""
    if stealer and stealer.get("is_stealer"):
        renk = 0xE74C3C
        karar_lbl = f"🚨 STEALER TESPİTİ! ({stealer.get('guven', 0)}% güven)"
        karar_acik = "⛔ ÇALIŞTIRMA! " + stealer.get("ozet", "")
        s_alarm = ("\n\n🚨🚨🚨 **STEALER ALARMI** — bu script hesap/şifre/çerez/cüzdan "
                   "çalıyor olabilir! Detaylar aşağıda '🦠 STEALER incelemesi' rafında.")
    if zincir and any(z["g"] >= 40 for z in zincir):
        karar_acik = karar_acik + " ⚠️ **ZINCIRDE supheli alt-link saptandi!** Bak: zincir rafı."
        renk = min(renk, 0xE67E22) if renk == 0x2ECC71 else renk
    g, h = R.get("g_skor", R["skor"]), R.get("h_skor", R["skor"])
    e = discord.Embed(title=f"🕵️ SENSEI-AI Analiz — {name[:60]}",
                      description=(f"### {karar_lbl}\n_{karar_acik}_\n"
                                   f"🛡️ hesap-guvenlik riski {analyzer.gauge(g)} **%{g}**\n"
                                   f"🎮 hile gucu {analyzer.gauge(h)} **%{h}**{s_alarm}"),
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
    # ---- STEALER inceleme rafı (her zaman gösterilir; tespit yoksa 'temiz') ----
    if stealer:
        if stealer.get("is_stealer"):
            satir = [stealer.get("ozet", "")]
            for _kat, p, acik, _kt in stealer.get("bulgular", [])[:6]:
                satir.append(f"**+{p}** {acik}")
            e.add_field(name="🦠 STEALER incelemesi — 🚨 TESPİT EDİLDİ",
                        value="\n".join(satir)[:1024], inline=False)
        elif stealer.get("bulgular"):
            satir = [f"🔎 {b[2]} (+{b[1]})" for b in stealer["bulgular"][:4]]
            satir.append(f"_Stealer sinyali zayıf (güven %{stealer.get('guven', 0)}). "
                         f"Ama kanıt ≠ garanti, obf varsa dikkat._")
            e.add_field(name="🦠 STEALER incelemesi — şüphe var ama net değil",
                        value="\n".join(satir)[:1024], inline=False)
        else:
            e.add_field(name="🦠 STEALER incelemesi — ✅ temiz",
                        value=("Çerez/token/cüzdan hırsızlığı veya sızdırma deseni "
                               "bulunamadı. (Kanıt yokluğu = garanti değil.)"),
                        inline=False)
    if zincir:
        sat = []
        for z in zincir[:6]:
            if z["karar"].startswith("❌"):
                dav = "❌"
            elif z["g"] >= 40:
                dav = "🚨"
            elif z["g"] >= 20 or z["h"] >= 70:
                dav = "🟣"
            else:
                dav = "✅"
            sat.append(f"{dav} {z['url'][:58]}\n   → {z['karar']} (🛡%{z['g']} 🎮%{z['h']})")
        e.add_field(name="🔗 ZINCIR linkleri (bizzat cekilip tarandi)", value="\n".join(sat)[:1024], inline=False)
    e.set_footer(text=f"{_rcs(Q_SONUC)} | ⚖️ huristiktir, %100 kanit degildir | 💬 soru sor: .sor  konus: .sohbet")
    return e


@bot.command(name="aly", aliases=["analiz"])
@commands.cooldown(3, 60, commands.BucketType.channel)
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
                if not await _fetch_budgele(ctx):
                    return
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
        # ---- v1.7 ZINCIR: icerideki HttpGet/loadstring linklerini de cek+tara ----
        zincir = []
        incelenen = set()
        bekleyen = analyzer.bul_zincir_linkleri(text + "\n" + ek_havuz)
        while bekleyen and len(zincir) < 8: # Zincir derinliğini 8'e çıkardım
            u = bekleyen.pop(0)
            if u in incelenen:
                continue
            incelenen.add(u)
            try:
                async with ctx.typing():
                    data, _iz = await bot.loop.run_in_executor(None, deobf.smart_fetch, u)
                if len(data) > 5 * 1024 * 1024:
                    raise ValueError("5MB ustu")
                alt = data.decode("utf-8", "replace")[:1_000_000]
                ek_alt = ""
                # Alt linkte obf varsa çözmeye çalış
                if "wearedevs.net/obfuscator" in alt or "luaprot" in alt.lower() or "LPH" in alt[:2000]:
                    try:
                        _, o2 = await bot.loop.run_in_executor(
                            None, deobf.deobf_pipeline, u[-40:], data[:1_000_000])
                        ek_alt = "\n".join(o2[a][:120000].decode("utf-8", "replace")
                                           for a in ("wrd_strings.txt", "strings.txt", "deobf.txt") if a in o2)
                    except Exception:
                        ek_alt = ""
                
                # Alt scripti analiz et
                Rz = analyzer.analyze(u.split("/")[-1][:50] or "alt-script", alt, ek_alt)
                lbl_z, _, _ = analyzer.karar(Rz)
                
                # Zincir listesine ekle
                zincir.append({"url": u, "karar": lbl_z.split("—")[0].strip(),
                               "g": Rz.get("g_skor", 0), "h": Rz.get("h_skor", 0)})
                
                # Ana analiz havuzuna ekle (böylece ana analiz alt scriptleri de görür)
                ek_havuz += f"\n-- @@ZINCIR {u}\n" + alt[:120000]
                if ek_alt:
                    ek_havuz += "\n" + ek_alt[:60000]
                
                # Alt scriptin içindeki linkleri de sıraya ekle (Recursive)
                for u2 in analyzer.bul_zincir_linkleri(alt + "\n" + ek_alt):
                    if u2 not in incelenen:
                        bekleyen.append(u2)
            except Exception as ex3:
                zincir.append({"url": u, "karar": f"❌ alinamadi ({type(ex3).__name__})", "g": 0, "h": 0})
        if zincir:
            ok_no = sum(1 for z in zincir if not z["karar"].startswith("❌"))
            ek_not = (ek_not + "\n" if ek_not else "") + \
                     f"🔗 zincir: {ok_no}/{len(zincir)} alt-link ayrica tarandi"
        R = analyzer.analyze(name, text, ek_havuz)
        # ---- STEALER incelemesi: scripti araştır, hırsız mı belirle ----
        S = stealer_detect.investigate(text, ek_havuz)
        # stealer tespit edilirse önce yüksek sesle ALARM, sonra detaylı kart
        if S.get("is_stealer"):
            await ctx.send("🚨 **@here** " + stealer_detect.alarm_metni(S)[:MAX_DISCORD_MSG])
        await ctx.send(embed=_aly_embed(name, text, R, ek_not, zincir, stealer=S))
        # sohbet icin hafizaya al (kanal basina son analiz)
        SONS[ctx.channel.id] = {"R": R, "name": name, "ts": time.time(), "zincir": zincir,
                                "kaynak": text[:80000], "ek": ek_havuz[:60000],
                                "stealer": S}
        STATS["aly"] += 1
    except Exception as ex:
        print(traceback.format_exc(limit=3))
        await ctx.send(f"💥 .aly patladi: `{type(ex).__name__}: {ex}`")


# -------------------- .rt (RUNTIME deobf - Prometheus mock-trace motoru) --------------------
_HERE = os.path.dirname(os.path.abspath(__file__))


def _prom_bul() -> str:
    """prom/ vendor klasorunu akillica bulur: once prom/ dener, yoksa repo kokune de bakar
    (kullanicilar dosyalari duz yuklemis olabilir 😄). yoksa ''."""
    for cand in (os.path.join(_HERE, "prom"), _HERE):
        if os.path.exists(os.path.join(cand, "deobfuscator.py")) and os.path.exists(os.path.join(cand, "lua51")):
            return cand
    return ""


def _prom_hazir() -> bool:
    """vendor dosyalari + lua51 varsa (ve calistirilabilir izinli) True."""
    d = _prom_bul()
    if not d:
        return False
    try:
        os.chmod(os.path.join(d, "lua51"), 0o755)  # zip/github'dan gelirse izin biti ucmus olur
    except Exception:
        pass
    return True


def _rt_kos(name: str, content: bytes) -> dict:
    """Senkron calisan runtime-deobf (Prometheus mock-trace). bot executor'da cagrilir.

    GÜVENLİK: DEOBF_RUNTIME=1 değilse hiç yürütmez. Açıksa alt süreç
    security.run_limited ile CPU/duvar-zamanı limitli çalışır.
    """
    if not security.runtime_on():
        return {"boom": False, "sure": 0.0, "rc": -1,
                "hata": "runtime deobf kapalı (DEOBF_RUNTIME=1 + OWNER_ID gerek)", "trace": ""}
    d = tempfile.mkdtemp(prefix="rt_")
    try:
        prom = _prom_bul()
        if not prom:
            return {"boom": False, "sure": 0.0, "rc": -1, "hata": "prom vendor bulunamadi", "trace": ""}
        hedef = os.path.join(d, re.sub(r"[^\w.\-]", "_", name or "hedef.lua")[:60])
        with open(hedef, "wb") as f:
            f.write(content)
        env = dict(os.environ)
        env["LUA51_EXECUTABLE"] = os.path.join(prom, "lua51")
        t0 = time.time()
        try:
            r = security.run_limited(["python3" if os.name != "nt" else "python",
                                      os.path.join(prom, "deobfuscator.py"), hedef],
                                     timeout=120, mem_mb=1024, cpu_sec=90,
                                     env=env, limit_mem=False)
        except Exception as e:
            return {"boom": False, "sure": time.time() - t0, "rc": -1,
                    "hata": f"süreç hatası: {type(e).__name__}: {e}", "trace": ""}
        sure = time.time() - t0
        out = {"sure": sure, "rc": r.returncode,
               "hata": (r.stderr or "").strip()[-260:], "trace": r.stdout or ""}
        deb, rep = hedef + ".deobf.lua", hedef + ".report.txt"
        if os.path.exists(deb):
            data = open(deb, "rb").read()
            t = data.decode("utf-8", "replace")
            # rekonstruksiyon kalitesi olcumleri
            IzBelge = {}
            for k in ("print(", "Instance.new", "GetService", "FireServer",
                      "InvokeServer", "http", "isfile(", "writefile(",
                      "readfile(", "Color3", "UDim2", "loadstring"):
                n = t.count(k)
                if n:
                    IzBelge[k] = n
            out["deobf"], out["satir"], out["izler"] = data, t.count("\n") + 1, IzBelge
        if os.path.exists(rep):
            out["report"] = open(rep, "rb").read()
        out["boom"] = "attempt to" in (r.stderr or "")
        return out
    finally:
        shutil.rmtree(d, ignore_errors=True)


@bot.command(name="rt", aliases=["runtime", "prom"])
@privileged()
@commands.cooldown(1, 120, commands.BucketType.channel)
async def rt_cmd(ctx, url: str = None):
    if not security.runtime_on():
        return await ctx.send("🔒 `.rt` runtime deobf güvenlik nedeniyle kapalı. Açmak için "
                              "sunucuda `DEOBF_RUNTIME=1` ve `OWNER_ID=<senin id>` ayarla.")
    if not _prom_hazir():
        return await ctx.send("⚠️ `prom/` vendor klasoru eksik yahut lua51 yok — GitHub repo kokune `prom/` klasorunu de yukle (deobfuscator.py, trace_to_lua.py, lua51).")
    try:
        name, content = None, None
        if ctx.message.attachments:
            att = ctx.message.attachments[0]
            if att.size > 5 * 1024 * 1024:
                return await ctx.send(f"⚠️ Dosya cok buyuk ({att.size:,}B). limit 5MB.")
            content, name = await att.read(), att.filename
        elif url:
            m = URL_RX.search(url)
            if m: url = m.group(0)
            url = deobf.normalize_raw_url(url)
            async with ctx.typing():
                raw = await bot.loop.run_in_executor(None, deobf.fetch, url)
            if len(raw) > 5 * 1024 * 1024:
                return await ctx.send("⚠️ Icerik cok buyuk.")
            content, name = raw, url.split("/")[-1] or "hedef"
        else:
            return await ctx.send("Kullanim: `.rt <url>` veya dosya ekle — RUNTIME deobf (mock-trace; katman-2 plaintext avcisi yani KALDIRAÇ 😎)")
        async with ctx.typing():
            R = await bot.loop.run_in_executor(None, _rt_kos, name, content or b"")
        # kart cikar
        if "deobf" not in R:
            e = discord.Embed(title="💥 RUNTIME deobf basaramadi", color=0xE74C3C,
                              description=(f"📄 {name[:60]}\n⏱️ {R['sure']:.1f}sn | rc {R['rc']}\n"
                                           f"son hata:\n```\n{(R['hata'] or '(kayitli hata yok)')[:700]}\n```"
                                           "\nNot: mock-env anti-emülasyonla kravga etmis olabilir — `.l` statik terse doner."))
            return await ctx.send(embed=e)
        izler = R["izler"]
        on_sira = ", ".join(f"`{k}x{v}`" for k, v in sorted(izler.items(), key=lambda x: -x[1])[:8]) or "satsiz"
        boom_not = "\n⚠️ mock-env yarıda çakıldı: çıktı tamamından eksik olabilir (yine de cozulenler gercek)" if R["boom"] else ""
        e = discord.Embed(title=f"⚡ RUNTIME deobf — {name[:50]}", color=0xE91E63,
                          description=(f"⏱️ {R['sure']:.1f}sn | cikti: **{R['satir']:,} satir** rekonstruksiyon\n"
                                       f"iz seti: {on_sira}{boom_not}\n\n"
                                       f"📎 `.deobf.lua` okunakli metin, `trace raporu` ham log (agirysa atlandı)."))
        e.set_footer(text="⚖️ Kelime uyarisi: emülasyondu, %100 sadakat garanti degil — ogrendiklerini .aly ile teyit et!")
        await ctx.send(embed=e)
        await ctx.send(file=discord.File(io.BytesIO(R["deobf"]), filename=(name[:40] or "deobf") + ".deobf.lua"))
        rep = R.get("report")
        if rep and len(rep) <= 3 * 1024 * 1024:
            await ctx.send(file=discord.File(io.BytesIO(rep), filename=(name[:40] or "trace") + ".trace.txt"))
        STATS["rt"] += 1
    except Exception as ex:
        print(traceback.format_exc(limit=3))
        await ctx.send(f"💥 .rt patladi: `{type(ex).__name__}: {ex}` (log'a yazdim)")


# -------------------- .diff (Sensei fikri!) --------------------
@bot.command(name="diff", aliases=["karsilastir"])
@commands.cooldown(2, 60, commands.BucketType.channel)
async def diff_cmd(ctx, urlA: str = None, urlB: str = None):
    if not (urlA and urlB):
        return await ctx.send("Kullanim: `.diff <link1> <link2>` — iki surumu karsilastiririm.")
    if not await _fetch_budgele(ctx, key=f"diff:{ctx.channel.id}"):
        return
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
                                   f"💬 .sor → **{STATS['sor']}** | ⚡ .rt → **{STATS['rt']}**\n"
                                   f"🗣️ aktif sohbet: **{len(SOHBET)}**"))
    e.set_footer(text=_rcs(TIPS))
    await ctx.send(embed=e)


# -------------------- SOHBET MODU (Sensei ile konus) --------------------
def _sohbet_ctx(ctx):
    bagim = SONS.get(ctx.channel.id)
    if not bagim:
        return None
    return {"R": bagim["R"], "name": bagim["name"], "zincir": bagim.get("zincir", []),
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
