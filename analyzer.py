# -*- coding: utf-8 -*-
"""SENSEI-AI v1.5 — kurall tabanli script analiz dedektifi (LLM'siz, saf stdlib).
analyze(name, text, ek_havuz=None) -> karar sozlugu.
Obf'lu input icin CAGIRAN taraf decoded metni ek_havuz olarak vermeli
(bot v1.4 motorunun ciktilari) — boylece sifreli scriptler de okunur."""

import re

VERS = "1.5"

# (regex, kategori, puan, aciklama)
DESENLER = [
    # --- VERI KACIRMA / LOGGER ---
    (r"discord(?:app)?\.com/api/webhooks", "EXFIL", 35, "Discord webhook (log/cerez iade kanali)"),
    (r"(?:grabify\.link|iplogger\.|iplogger\.com|webhook\.site|hookbin|canarytokens|pipedream\.net|requestbin)", "EXFIL", 45, "IP logger / honeypot endpoint!"),
    (r"https?://\d{1,3}(?:\.\d{1,3}){3}(?::\d+)?", "EXFIL", 18, "cplak IP'ye HTTP (supheli sunucu)"),
    (r"bit\.ly|tinyurl|cutt\.ly|is\.gd|shorte\.st|bc\.vc|linkvertise", "EXFIL", 12, "link kisaltma (hedefi sakliyor)"),
    # --- HESAP / CEREZ HIRSIZLIGI ---
    (r"ROBLOSECURITY|getcookie|Cookies", "HESAP", 60, "CEREZ/ROBLOSECURITY hirsizligi — GIRME!"),
    (r"LocalPlayer\.UserId.*http|http.*UserId", "HESAP", 20, "UserId'nin dis sunucuya sizma izi"),
    # --- SATIN ALMA TUZAGI ---
    (r"PromptPurchase|PromptProductPurchase|MarketplaceService.*Prompt", "PARA", 25, "oyun ici satin alma penceresi aciyor"),
    # --- KALICILIK / MANIPULASYON ---
    (r"hookfunction|hookmetamethod", "MANIP", 25, "fonksiyon hook'u (davranis degistirme)"),
    (r"getconnections|getnamecallmethod", "MANIP", 12, "executor seviye dinleme/manipulasyon"),
    (r"getgenv\s*\(", "MANIP", 6, "global ortam erisimi"),
    (r"gethui|CoreGui", "MANIP", 8, "korunakli CoreGui'ye saklanma"),
    (r"setfpscap|fpscap", "MANIP", 3, "FPS degistirme"),
    # --- REMOTE / SUNUCU ETKILESIMI ---
    (r"FireServer\s*\(", "REMOTE", 4, "sunucuya remote atisy (FireServer)"),
    (r"InvokeServer\s*\(", "REMOTE", 4, "sunucudan remote cagrisi (InvokeServer)"),
    (r"Unreliable", "REMOTE", 2, "guvencesiz remote kanali"),
    # --- YIKICI / YAN ETKI ---
    (r"LocalPlayer:Kick|:Kick\(", "YIKICI", 18, "Kick() — seni oyundan atabilir"),
    (r"TeleportService.*Teleport", "YIKICI", 15, "baska sunucuya irtica (scam-hop?)"),
    (r"require\s*\(\s*\d{5,}", "YIKICI", 12, "require(assetid) — arka kapi zinciri olabilir"),
    (r"game:GetService\(['\"]TeleportService", "YIKICI", 8, "TeleportService kullanimi"),
    # --- OBF / PAKETLEME ---
    (r"wearedevs\.net/obfuscator", "OBF", 10, "WRD obfuscator (katmanli sifreleme)"),
    (r"luaprot\.net|LuaProt", "OBF", 15, "LuaProt lisans stub'i (kod sunucuda kilitli)"),
    (r'LPH[+|]', "OBF", 10, "XSUB/Luraph turevi paketleme"),
    (r"\\x[0-9a-fA-F]{2}\\x[0-9a-fA-F]{2}\\x[0-9a-fA-F]{2}", "OBF", 6, "hex-kaçışlı string yigini"),
]

# amac kurallari: (regex, cikti)  — ilk basklarin onceligi var
AMAC_KURALLARI = [
    (r"Tamper Detected|Digite a key|key aqui|get the key|key system|KeyFrame", "🔑 Key-sistemli panel (linkvertise key duvarki)"),
    (r"aimbot|aim lock|triggerbot|silenthit", "🎯 Aimbot / aim-assist"),
    (r"\besp\b|wallhack|chams|tracer", "👁️ ESP / wallhack"),
    (r"noclip", "🧱 Noclip (duvardan gecis)"),
    (r"\bfly\b|cframe speed|speedhack", "🪽 Ucmak/hiz hacki"),
    (r"AntiQueda|anti[- ]?fall|antifall", "🪂 Anti-dusme korumasi"),
    (r"infinite yield|cmarketplace admin|admin commands", "👑 Admin komut paneli"),
    (r"fps ?boost|remove textures|potato", "🥔 FPS artirici"),
    (r"auto ?farm|autoclick|auto ?collect", "🌾 Oto-farm / auto-click"),
    (r"hitbox|reach", "🥊 Hitbox genisletme"),
    (r"trail|pet|egg|hatch", "🥚 Pet/yumurta oyunu ozelligi"),
]

ZARARSIZ_IZLER = [
    (r"ScreenGui", -4, "GUI insasi"),
    (r"TweenService", -3, "animasyon"),
    (r"Rayfield|OrionLib|Linoria|Fluent|Kavo", -8, "bilinen UI kutuphanesi"),
    (r"UserInputService", -2, "girdi kontrolu"),
    (r"players?\.localplayer", -2, "yerel oyuncu erisimi (normal)"),
]

def analyze(name: str, text: str, ek_havuz: str = "") -> dict:
    """Huristic analiz. ek_havuz: varsa decoded stringler (obf cozumu)."""
    havuz = text + "\n" + ek_havuz
    low = havuz.lower()
    R: dict = {
        "skor": 0, "bulgular": [], "uzaklar": [], "urller": [],
        "servisler": [], "amac": [], "notlar": [], "tur": "duz lua",
    }

    turler = []
    if "wearedevs.net/obfuscator" in havuz: turler.append("WRD v1 obfuscator")
    if "luaprot" in low: turler.append("LuaProt lisans stub")
    if "LPH" in text[:2000] or "Luraph" in text[:2000]: turler.append("XSUB/Luraph turevi")
    satirs = text.count("\n") + 1
    if satirs <= 3 and len(text) > 5000: turler.append("minifiye (tek satir)")
    if not turler: turler.append("duz lua")
    R["tur"] = " + ".join(turler)

    toplam = 0
    for rx, kat, puan, acik in DESENLER:
        hits = re.findall(rx, havuz, re.I if kat not in ("OBF",) else 0)
        if not hits:
            continue
        n = len(hits)
        cap = puan + min(n - 1, 6) * (2 if puan >= 10 else 1)
        toplam += cap
        et = f"{acik} (x{n})" if n > 1 else acik
        R["bulgular"].append((cap, kat, et))
    R["bulgular"].sort(key=lambda x: -x[0])

    ind = 0
    for rx, puan, acik in ZARARSIZ_IZLER:
        if re.search(rx, havuz, re.I):
            ind += puan
            R["notlar"].append(f"↩️ {acik} ({puan})")
    toplam += ind

    for rx, cikti in AMAC_KURALLARI:
        if re.search(rx, havuz, re.I):
            R["amac"].append(cikti)
        if len(R["amac"]) >= 3:
            break
    if not R["amac"]:
        if "ScreenGui" in havuz: R["amac"].append("🖼️ GUI hub'u (panel kuruyor)")
        elif "loadstring" in havuz and satirs < 10: R["amac"].append("📦 sadece yukleyici/stub")
        else: R["amac"].append("❓ belirsiz amaç (kucuk/yardimci kod?)")

    for u in sorted(set(re.findall(r"https?://[^\s\"'<>\)\]]+", havuz)))[:8]:
        kisa = re.sub(r"https?://", "", u)[:90]
        dav = "🚨" if ("webhook" in u or "gg/" in u) else ("⚠️" if "http://" in u else "🌐")
        R["urller"].append(f"{dav} {kisa}")

    rem = {}
    for m in re.finditer(r'(?:WaitForChild|FindFirstChild)\(\s*["\']([A-Za-z0-9_ .\-]{2,40})["\']', havuz):
        w = m.group(1)
        if len(w) >= 3:
            rem[w] = rem.get(w, 0) + 1
    for m in re.finditer(r"Remotes[.:]([A-Za-z0-9_]+)", havuz):
        rem[m.group(1)] = rem.get(m.group(1), 0) + 1
    for k, v in sorted(rem.items(), key=lambda x: -x[1])[:8]:
        R["uzaklar"].append(f"`{k}` ×{v}")
    fires = len(re.findall(r"FireServer\s*\(", havuz))
    invs = len(re.findall(r"InvokeServer\s*\(", havuz))
    if fires or invs:
        R["uzaklar"].append(f"FireServer ×{fires} | InvokeServer ×{invs}")

    for m in sorted(set(re.findall(r'GetService\(\s*["\']([A-Za-z0-9]+)["\']', havuz)))[:10]:
        R["servisler"].append(m)

    R["skor"] = max(0, min(100, toplam))
    if R["skor"] >= 80:   R["band"] = 3
    elif R["skor"] >= 50: R["band"] = 2
    elif R["skor"] >= 20: R["band"] = 1
    else:                 R["band"] = 0
    return R

BAND_BILGI = [
    ("🟢 GUVENLI — temiz gorunuyor", 0x2ECC71, "Sensei cikmazi yok, yine de goz ucuyla bak."),
    ("🟡 SUPHELI — gri bolge", 0xF1C40F, "Calistirmadan once ne yaptigini bir kurcala."),
    ("🟠 RISKLI — dikkat!", 0xE67E22, "Ciddi sinyaller var. Alternatifini bul ya da Sensei'ye danis."),
    ("🔴 TEHLIKELI — uzak dur!", 0xE74C3C, "Hesabini/verini kacirmayi hedefliyor olabilir. Calistirma!"),
]

def gauge(skor: int, n: int = 10) -> str:
    dolu = round(skor / 100 * n)
    return "▰" * dolu + "▱" * (n - dolu)
