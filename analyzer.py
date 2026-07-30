# -*- coding: utf-8 -*-
"""SENSEI-AI v2.0 — kanit-disiplinli script analiz dedektifi (LLM'siz, saf stdlib).

v2 degisiklikleri (sallama onleyici):
  * Her amac tespiti ikiye ayrildi:
      - GUC (guclu kod izi): gercekten CALISAN icra satiri (orn noclip -> CanCollide=false)
      - SOZ (adi gecti): buton yazisi, baslik, rastgele string -> "kanit yok" diye isitilenir
  * Yorum satirlari (-- ...) taramadan CIKARILIR.
  * Her bulgu/tespit yanina kanit satiri (snippet + satir no) tasir.
  * Remote isimleri icin anlam sozlugu (parry->savas, buy->satin alma...).
analyze(name, text, ek_havuz="") -> karar sozlugu (amac_kesin / amac_gecen / bulgular+kanit)
"""
import re

VERS = "2.2"

# -------------------- supheli desenler (skor icin) --------------------
DESENLER = [
    (r"discord(?:app)?\.com/api/webhooks", "EXFIL", 35, "Discord webhook (log/cerez iade kanali)"),
    (r"grabify\.link|iplogger|webhook\.site|hookbin|canarytokens|pipedream\.net|requestbin", "EXFIL", 45, "IP logger / honeypot endpoint!"),
    (r"https?://\d{1,3}(?:\.\d{1,3}){3}(?::\d+)?", "EXFIL", 18, "cplak IP'ye HTTP (supheli sunucu)"),
    (r"bit\.ly|tinyurl|cutt\.ly|is\.gd|shorte\.st|bc\.vc", "EXFIL", 12, "link kisaltma (hedefi sakliyor)"),
    (r"ROBLOSECURITY|getcookie|Cookies\b", "HESAP", 60, "CEREZ/ROBLOSECURITY hirsizligi — GIRME!"),
    (r"LocalPlayer\.UserId.*HttpGet|HttpGet.*UserId", "HESAP", 20, "UserId'nin dis sunucuya sizma izi"),
    (r"PromptPurchase|PromptProductPurchase", "PARA", 25, "oyun ici satin alma penceresi aciyor"),
    (r"hookfunction|hookmetamethod", "MANIP", 25, "fonksiyon hook'u (davranis degistirme)"),
    (r"getconnections|getnamecallmethod", "MANIP", 12, "executor seviye dinleme/manipulasyon"),
    (r"getgenv\s*\(\s*\)", "MANIP", 6, "global ortam erisimi"),
    (r"gethui|CoreGui", "MANIP", 8, "korunakli CoreGui'ye saklanma"),
    (r"setfpscap|fpscap", "MANIP", 3, "FPS degistirme"),
    (r"FireServer\s*\(", "REMOTE", 4, "sunucuya remote atisi (FireServer)"),
    (r"InvokeServer\s*\(", "REMOTE", 4, "sunucudan remote cagrisi (InvokeServer)"),
    (r"LocalPlayer:Kick|:Kick\(", "YIKICI", 18, "Kick() — seni oyundan atabilir"),
    (r"TeleportService[^\\n]*Teleport", "YIKICI", 15, "baska sunucuya irtica (scam-hop?)"),
    (r"require\s*\(\s*\d{5,}", "YIKICI", 12, "require(assetid) — arka kapi zinciri olabilir"),
    (r"wearedevs\.net/obfuscator", "OBF", 10, "WRD obfuscator (katmanli sifreleme)"),
    (r"luaprot", "OBF", 15, "LuaProt lisans stub'i (kod sunucuda kilitli)"),
    (r'LPH[+|]', "OBF", 10, "XSUB/Luraph turevi paketleme"),
    (r"\\x[0-9a-fA-F]{2}\\x[0-9a-fA-F]{2}\\x[0-9a-fA-F]{2}", "OBF", 6, "hex-kacisli string yigini"),
]

# -------------------- amac tespiti: GUC (idam-derece kanit) vs SOZ --------------------
# (etiket, [guclu regexler], [soz regexler])
AMAC_KURALLARI = [
    ("🔑 Key-sistemli panel",
     [r"Tamper Detected", r"Digite a key|key aqui|KeyFrame", r"FocusLost[^\n]*[Kk]ey",
      r"[Kk]ey\s*==\s*[\"'][A-Za-z0-9_\-]{8,}[\"']"],
     [r"key ?system|linkvertise", r"get the key"]),
    ("🌀 Desync / CFrame konum manipulasyonu",
     ["@desync"],
     [r"\bdesync\b"]),
    ("🥊 Hitbox genisletme",
     [r"\b(?:Head|RootPart|HumanoidRootPart)(?:\.[\w.]+)?\.Size\s*=\s*Vector3",
      r"\.Size\s*=\s*Vector3\.new\(\s*(?:[5-9]\d|\d{3})"],
     [r"hitbox", r"\breach\b"]),
    ("🧱 Noclip (duvardan gecis)",
     ["@noclip"],
     [r"noclip"]),
    ("🪽 Ucma (fly)",
     [r"BodyVelocity|VectorForce|BodyGyro|BodyThrust", r"FlyEnabled|Flying\s*=\s*true"],
     [r"\bfly\b|\bflying\b", r"fly ?hack"]),
    ("💨 Hiz hacki",
     [r"WalkSpeed\s*=\s*(?:[2-9]\d|\d{3,})", r"CFrame\s*=\s*[^%\n]*speed"],
     [r"speed ?hack|cframe speed|\bhigher speed\b"]),
    ("🎯 Aimbot / aim-assist",
     [r"mousemoverel", r"Mouse\.Hit|mouse2click", r"[Aa]im[Ll]ock\s*="],
     [r"aimbot|aim assist|triggerbot|silenthit"]),
    ("👁️ ESP / wallhack",
     [r"Drawing\.new", r"BoxHandleAdornment|SphereHandleAdornment", r"Highlight\b[^\n]*FillColor|Instance\.new\(\s*['\"]Highlight"],
     [r"\besp\b|wallhack|chams|tracer"]),
    ("🪂 Anti-dusme korumasi",
     [r"AntiQueda|anti[- ]?queda", r"antifall|anti[- ]?fall"],
     []),
    ("👑 Admin komut paneli",
     [r"infinite[\s_-]?yield", r"require\(\s*\d{5,}[^\n]*admin"],
     [r"admin commands|admin script"]),
    ("🥔 FPS artirici",
     [r"setfpscap|fpscap\(", r"Destroying:FindFirstChild\(\s*['\"]Texture"],
     [r"fps ?boost|remove textures|potato mode"]),
    ("🌾 Oto-farm / auto-click",
     [r"VirtualInputManager", r"mouse1click|fireclickdetector|fireproximityprompt"],
     [r"auto ?farm|autoclick|auto ?collect|auto ?attack"]),
    ("😴 Anti-AFK (VirtualUser)",
     [r"VirtualUser", r"CaptureController"],
     [r"antiafk|anti[- ]afk"]),
    ("⚔️ Blade Ball auto-parry kurulumu",
     [r"\bCurrentBall\b"],
     [r"blade ball|roweball"]),
    ("🥚 Pet/yumurta ozelligi",
     [r"hatch[^\n]*pet|pet[^\n]*hatch", r"egg[^\n]*opening"],
     [r"egg|hatch|\bpet\b"]),
]

ZARARSIZ_IZLER = [
    (r"ScreenGui", -4, "GUI insasi"),
    (r"TweenService", -3, "animasyon"),
    (r"Rayfield|OrionLib|Linoria|Fluent|Kavo", -8, "bilinen UI kutuphanesi"),
    (r"UserInputService", -2, "girdi kontrolu"),
    (r"players?\.localplayer", -2, "yerel oyuncu erisimi (normal)"),
]

# uzaktan kumanda adindan amac tahmini
REMOTE_IPUCU = [
    (r"parry|block|deflect|reflect", "🗡️ savas blok (blade ball tarzi)"),
    (r"combat|attack|swing|punch|melee|slash|hit", "🗡️ saldiri/dovus"),
    (r"gun|shoot|fire|reload|ammo|aim|bullet", "🔫 silah/nisansal"),
    (r"buy|purchase|shop|market|sell|checkout", "🛒 satin alma/satis"),
    (r"save|data|load|profile|stats", "💾 veri kaydi"),
    (r"trade|gift", "🔄 takas"),
    (r"redeem|code", "🎁 kod sistemi"),
    (r"report|moder|ban|kick|admin", "🛡️ moderasyon/admin"),
    (r"teleport|place|join|queue", "🚀 teleport/sunucu"),
    (r"pet|hatch|egg", "🥚 pet sistemi"),
    (r"dash|sprint|roll|dodge|slide", "💨 hareket"),
    (r"damage|health|heal|regen", "❤️ can/hasar"),
    (r"coin|cash|money|gold|gem", "💰 odul/para"),
    (r"chat|message|notification", "💬 bildirim"),
]


# -------------------- yardimcilar --------------------
def _yorumsuz(text: str):
    """Satir satir: -- ve --[[ satir-ici blok yorumlari atar. (kod + stringler kalir)"""
    ret = []
    for i, L in enumerate(text.splitlines(), 1):
        L = re.sub(r"--\[\[.*?\]\]", " ", L)
        L = re.sub(r"--.*$", "", L)
        ret.append((i, L))
    return ret


def _kanit(lines, rx, n=2, uz=90):
    """ilk n farkli satirdan kisaltilmis kanit snippet'i"""
    out = []
    rxp = re.compile(rx, re.I)
    for tag, L in lines:
        if L.strip() and rxp.search(L):
            sn = re.sub(r"\s+", " ", L.strip())
            if len(sn) > uz:
                sn = sn[:uz - 3] + "..."
            out.append((tag, sn))
            if len(out) >= n:
                break
    return out


def _say_lines(lines, rx, cap=30):
    rxp = re.compile(rx, re.I)
    return sum(1 for _, L in lines[:6000] if rxp.search(L)) if lines else 0


# -------------------- ozel dedektorler: baglam gerektiren tespitler --------------------
OZEL_DEDEKT = {}


def _penkere_hit(kod, idx, rx, back=10, ahead=3):
    lo = max(0, idx - back)
    hi = min(len(kod), idx + ahead + 1)
    return re.search(rx, "\n".join(L for _, L in kod[lo:hi]), re.I) is not None


def _noclip_kanit(kod):
    """CanCollide=false -> gercek noclip ise kanittir.
    Yeni yaratilan dummy parcalarin property blogunu ele (Instance.new penceresi),
    karakter/oyuncu baglami iste."""
    out = []
    for idx, (i, L) in enumerate(kod):
        if not re.search(r"CanCollide\s*=\s*[Ff]alse", L):
            continue
        if _penkere_hit(kod, idx, r"Instance\.new", back=12):
            continue  # yeni yaratilan dummy parca; noclip degil
        if not _penkere_hit(kod, idx, r"Character|GetDescendants|DescendantAdded|Humanoid|Players"):
            continue  # baglam yoksa kanit sayilmaz
        sn = re.sub(r"\s+", " ", L.strip())[:90]
        out.append(("kod L%d" % i, sn))
        if len(out) >= 2:
            break
    return out


OZEL_DEDEKT["@noclip"] = _noclip_kanit


def _desync_kanit(kod):
    """game __index hook'u + desync izi birlikteyse CFrame desync/anti-hit."""
    hook = ds = None
    for i, L in kod:
        if hook is None and re.search(r"hookmetamethod\s*\(\s*\w+\s*,\s*[\"']__index[\"']", L):
            hook = ("kod L%d" % i, re.sub(r"\s+", " ", L.strip())[:90])
        if ds is None and re.search(r"desync", L, re.I):
            ds = ("kod L%d" % i, re.sub(r"\s+", " ", L.strip())[:90])
    return [hook, ds] if (hook and ds) else []


OZEL_DEDEKT["@desync"] = _desync_kanit


# -------------------- ana fonksiyon --------------------
def analyze(name: str, text: str, ek_havuz: str = "") -> dict:
    havuz = text + ("\n" + ek_havuz if ek_havuz else "")
    low = havuz.lower()

    R: dict = {
        "skor": 0, "bulgular": [], "uzaklar": [], "urller": [],
        "servisler": [], "amac": [], "amac_kesin": [], "amac_gecen": [],
        "notlar": [], "tur": "duz lua", "vers": VERS,
    }

    turler = []
    if "wearedevs.net/obfuscator" in havuz:
        turler.append("WRD v1 obfuscator")
    if "luaprot" in low:
        turler.append("LuaProt lisans stub")
    if "LPH" in text[:2000] or "Luraph" in text[:2000]:
        turler.append("XSUB/Luraph turevi")
    satirs = text.count("\n") + 1
    if satirs <= 3 and len(text) > 5000:
        turler.append("minifiye (tek satir)")
    R["tur"] = " + ".join(turler) if turler else "duz lua"
    R["satir"] = satirs

    # kanit havuzlari: yorumsuz kod satirlari + (varsa) cozulmus string satirlari
    kod = _yorumsuz(text)
    dize = [("dize", L) for L in ek_havuz.splitlines()] if ek_havuz else []
    havuz_lines = [("kod L%d" % i, L) for i, L in kod] + dize

    # --- skor: desenler YORUMSUZ havuzda, her biri kanitla ---
    toplam = 0
    kat_toplam: dict = {}
    for rx, kat, puan, acik in DESENLER:
        lines = re.findall_rx = None
        hits = [L for _, L in havuz_lines if re.search(rx, L, re.I if kat != "OBF" else 0)]
        if not hits:
            continue
        n = len(hits)
        cap = puan + min(n - 1, 6) * (2 if puan >= 10 else 1)
        toplam += cap
        kts = _kanit(havuz_lines, rx, 2)
        et = f"{acik} (x{n})" if n > 1 else acik
        R["bulgular"].append((cap, kat, et, kts))
        kat_toplam[kat] = kat_toplam.get(kat, 0) + cap
    R["bulgular"].sort(key=lambda x: -x[0])

    for rx, puan, acik in ZARARSIZ_IZLER:
        if re.search(rx, havuz, re.I):
            toplam += puan
            R["notlar"].append(f"↩️ {acik} ({puan})")

    # --- amac: GUC vs SOZ ayrimi ---
    for etiket, gucler, sozler in AMAC_KURALLARI:
        kanitlar = []
        for grx in gucler:
            dfn = OZEL_DEDEKT.get(grx)
            if dfn:
                kanitlar += dfn(kod)
            else:
                kanitlar += _kanit(havuz_lines, grx, 2)
        if kanitlar:
            R["amac_kesin"].append((etiket, kanitlar[:2]))
            continue
        adet = 0
        for srx in sozler:
            adet += _say_lines(havuz_lines, srx)
        if adet:
            R["amac_gecen"].append((etiket, adet))
    R["amac"] = ([e for e, _ in R["amac_kesin"]]
                 + [f"{e} (? — {n}x)" for e, n in R["amac_gecen"]])
    if not R["amac"]:
        if re.search(r"ScreenGui", havuz):
            R["amac"].append("🖼️ GUI hub'u (panel kuruyor)")
        elif "loadstring" in havuz and satirs < 10:
            R["amac"].append("📦 sadece yukleyici/stub")
        else:
            R["amac"].append("❓ belirsiz amac (kucuk/yardimci kod?)")

    # --- url ler (yorum dahil tam havuz; sayfanin baglantisi da bilgidir) ---
    for u in sorted(set(re.findall(r"https?://[^\s\"'<>\)\]]+", havuz)))[:8]:
        kisa = re.sub(r"https?://", "", u)[:90]
        dav = "🚨" if "webhook" in u else ("💬" if "gg/" in u else ("⚠️" if "http://" in u else "🌐"))
        R["urller"].append(f"{dav} {kisa}")

    # --- remote envanteri + anlam sozlugu ---
    rem = {}
    for m in re.finditer(r'(?:WaitForChild|FindFirstChild)\(\s*["\']([A-Za-z0-9_ .\-]{2,40})["\']', havuz):
        w = m.group(1).strip()
        if len(w) >= 3:
            rem[w] = rem.get(w, 0) + 1
    for m in re.finditer(r"Remotes[.:]([A-Za-z0-9_]+)", havuz):
        rem[m.group(1)] = rem.get(m.group(1), 0) + 1
    for m in re.finditer(r'(?:FireServer|InvokeServer)\(\s*["\']([A-Za-z0-9_ .\-]{2,30})["\']', havuz):
        w = m.group(1).strip()
        rem[w + " (arg)"] = rem.get(w + " (arg)", 0) + 1
    def _ipucu(isim):
        base = isim.replace(" (arg)", "")
        for rx, anlam in REMOTE_IPUCU:
            if re.search(rx, base, re.I):
                return anlam
        return None
    for k2, v2 in sorted(rem.items(), key=lambda x: -x[1])[:9]:
        R["uzaklar"].append({"isim": k2, "adet": v2, "ipucu": _ipucu(k2)})

    fires = len(re.findall(r"FireServer\s*\(", havuz))
    invs = len(re.findall(r"InvokeServer\s*\(", havuz))
    R["fires"], R["invs"] = fires, invs

    for m in sorted(set(re.findall(r'GetService\(\s*["\']([A-Za-z0-9]+)["\']', havuz)))[:10]:
        R["servisler"].append(m)

    R["skor"] = max(0, min(100, toplam))
    R["band"] = 3 if R["skor"] >= 80 else 2 if R["skor"] >= 50 else 1 if R["skor"] >= 20 else 0

    # --- iki eksen: hesap-guvenlik riski (g) vs hile gucu (h) ---
    GUV = {"EXFIL", "HESAP", "PARA"}
    R["g_skor"] = max(0, min(100, sum(v for k, v in kat_toplam.items() if k in GUV)))
    R["h_skor"] = max(0, min(100, sum(v for k, v in kat_toplam.items() if k not in GUV)))
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


GUV_SINIF = {"EXFIL", "HESAP", "PARA"}


def karar(R: dict):
    """iki eksenli karar: hirsizlik/guvenlik (g) vs hile gucu (h) -> (baslik, renk, aciklama)"""
    g = R.get("g_skor", R.get("skor", 0))
    h = R.get("h_skor", R.get("skor", 0))
    if g >= 80:
        return ("🔴 TEHLİKELİ — hesap/veri riski yüksek!", 0xE74C3C,
                "Hirsizlik/sizinti desenleri agir. Calistirma, alternatife bak!")
    if g >= 40:
        return ("🟠 RİSKLİ — sızıntı sinyali var", 0xE67E22,
                "Dis iletisim/hesap sinifli desenler mevcut. Goz kirpmadan incele.")
    if h >= 70:
        return ("🟣 GÜÇLÜ HİLE — ban riski yüksek; hırsızlık izi YOK", 0x9B59B6,
                "Executor-manipulasyon araclari (hook/desync vb.) dolu ama veri kacirma deseni bulunamadi. "
                "Tehlike degilse de Roblox ban riski ciddi — main hesapta dusunerek.")
    if h >= 40:
        return ("🟡 ORTA GÜÇ — temkinli gez", 0xF1C40F,
                "Bazi manipulasyon desenleri var; hirsizlik sinifinda temiz gorunuyor.")
    return ("🟢 GÖRÜNÜRDE SAKİN", 0x2ECC71,
            "Ne hirsizlik ne de guc manipulasyonu sinyali. Yine de goz ucuyla kontrol.")
