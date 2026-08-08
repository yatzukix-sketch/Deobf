# -*- coding: utf-8 -*-
"""stealer_detect.py — Stealer / credential-hırsızı inceleme motoru.

Amacı: .aly analizinde scripti "reverse/araştırma" mantığıyla tarayıp, bir
STEALER (hesap/şifre/çerez/token/cüzdan hırsızı) olup olmadığını belirlemek ve
tespit edilirse üst katmana KIRMIZI ALARM olarak bildirmek.

investigate(text, ek_havuz="") -> dict {
  is_stealer: bool,
  guven: 0-100,               # stealer olduğuna güven
  kategoriler: [...],         # hangi tür hırsızlık
  hedefler: [...],            # neyi çalıyor
  sizdirma: [...],            # veriyi nereye gönderiyor
  bulgular: [(kat, puan, açıklama, kanıt), ...],
  marka: str | None,          # bilinen stealer markası yakalandıysa
  ozet: str,
}

Stdlib dışı bağımlılık yok; analyzer ile beraber çalışır.
"""
import re

VERS = "1.0"

# ---- bilinen stealer markaları (en yüksek güven) ----
STEALER_MARKALARI = [
    (r"\bvidar\b", "Vidar Stealer"),
    (r"\bredline\b|red ?line", "RedLine Stealer"),
    (r"\braccoon\b|raccoon ?stealer", "Raccoon Stealer"),
    (r"\blumma\b|lumma ?c2", "Lumma Stealer"),
    (r"\batomic ?stealer\b|atomic ?(osx)?", "Atomic macOS Stealer"),
    (r"\bazorult\b", "AZORult"),
    (r"\bmetastealer\b|meta ?stealer", "MetaStealer"),
    (r"\bmars ?stealer\b", "Mars Stealer"),
    (r"\brise ?pro\b", "RisePro Stealer"),
    (r"\bstealc\b", "StealC"),
    (r"\bphobos\b|lockbit|conti\b", "Fidye yazılımı (ransomware) imzası"),
]

# ---- neyi çaldığı (hedefler) ----
HEDEF_DESENLERI = [
    # Roblox (bu botun uzmanlık alanı — en sık karşılaşılan)
    (r"ROBLOSECURITY|\.ROBLOSECURITY", "roblox", 65,
     "Roblox .ROBLOSECURITY çerezi — HESAP ÇALMA"),
    (r"getcookiehandler|getCookieHandler|getcookie\(|getCookie\(", "roblox", 55,
     "Roblox çerez okuyucu fonksiyon"),
    (r"RequestAsync|httpService|HttpService.*cookies?|setrequester|set_https?",
     "roblox", 25, "Roblox HTTP ile çerez/token sızdırma"),
    (r"game:HttpGet.*ROBLOSECURITY|cookie.*HttpPost", "roblox", 60,
     "Çerezi uzak sunucuya postlama"),
    # Discord token
    (r"[MN][A-Za-z\d]{23}\.[\w\-]{6}\.[\w\-]{27}", "discord", 60,
     "Discord token deseni (gerçek token formatı!)"),
    (r"leveldb|\.ldb|\.log\b.*Local State|Local Extension Settings", "discord", 45,
     "Discord/Chrome yerel veritabanı — token çalma klasik yolu"),
    (r"discord( local)?\\?(?:Local State|Network\\Cookies)", "discord", 50,
     "Discord uygulama çerez/local state yolu"),
    # Tarayıcı şifreleri
    (r"Login Data|Login Data(?!.*\\).*", "browser", 45,
     "Chrome/Edge şifre veritabanı (Login Data)"),
    (r"\bCookies\b|Network[/\\]Cookies|User Data[/\\]Default", "browser", 40,
     "Tarayıcı çerez/oturum verisi"),
    (r"key3\.db|key4\.db|logins\.json|signons\.sqlite|places\.sqlite", "browser", 45,
     "Firefox şifre/oturum veritabanı"),
    (r"Local State|v10|v11\b.*decrypt|DPAPI|CryptUnprotectData", "browser", 30,
     "Şifre çözme (DPAPI/v10) — tarayıcı şifre kilidini açma"),
    # Kripto cüzdanlar
    (r"wallet\.dat|seed[- ]?phrase|mnemonic|bip39", "crypto", 55,
     "Kripto cüzdan/seed phrase hedefi"),
    (r"MetaMask|Exodus|Electrum|atomic\b.*wallet|TronLink|Phantom|Solflare",
     "crypto", 50, "Kripto cüzdan uzantısı/uygulaması yolu"),
    # Keylogger / ekran / pano
    (r"GetAsyncKeyState|keylog|SetWindowsHookEx|WH_KEYBOARD", "keylogger", 40,
     "Tuş kaydı (keylogger)"),
    (r"clipboard|GetClipboardData|SetClipboardData|OpenClipboard", "keylogger", 30,
     "Pano izleme (kopyalanan şifreleri çalma)"),
    (r"BitBlt|screenshot|CaptureScreen|CreateCompatibleBitmap", "keylogger", 25,
     "Ekran görüntüsü yakalama"),
    # SSH/FTP/oturum dosyaları
    (r"\.ssh[/\\]id_rsa|known_hosts|\.aws[/\\]credentials|\.npmrc|\.gitconfig",
     "session", 45, "SSH/AWS/git oturum dosyaları"),
    # Oyun hesapları
    (r"steam[/\\]config|loginusers\.vdf|Epic|Riot|Battle\.net", "game-account", 30,
     "Oyun hesabı oturum dosyaları"),
]

# ---- veriyi nereye sızdırdığı (sizdirma kanalları) ----
SIZDIRMA_KANALLARI = [
    (r"discord(?:app)?\.com/api/webhooks", "Discord webhook (en sık stealer kanalı)"),
    (r"api\.telegram\.org/bot\d+:[\w\-]+", "Telegram bot API"),
    (r"\bftp://|\bftps://|21\b.*ftp", "FTP sunucusu"),
    (r"\bsmtp(?:s)?://|SmtpClient|sendmail", "SMTP (e-posta ile sızdırma)"),
    (r"grabify\.link|iplogger|webhook\.site|canarytokens|pipedream\.net|requestbin\.com|0x0\.st",
     "Log/honeypot endpoint"),
    (r"pastebin\.com/api|hastebin|rentry\.co/api|ghostbin|dpaste", "Paste API (veri saklama)"),
    (r"https?://\d{1,3}(?:\.\d{1,3}){3}", "Çıplak IP'ye HTTP (sabit sunucu, kuşkulu)"),
    (r"bit\.ly|tinyurl|cutt\.ly|is\.gd|shorte\.st", "Link kısaltma (hedefi gizleme)"),
]

# ---- stealer davranış kalıpları (ek güven puanı) ----
DAVRIS_DESENLERI = [
    (r"(zip|rar|7z).*Login Data|(zip|rar).*wallet|compress.*steal", "toplama",
     20, "Çalıntı veriyi arşivleyip toplama"),
    (r"Startup|Run\\\\|HKCU.*Run|schtasks|AppData.*Roaming.*\.exe", "kalıcılık",
     20, "Kalıcılık kurma (yeniden başlıkta tetiklenme)"),
    (r"IsDebuggerPresent|vmware|virtualbox|sandboxie|anti[-]?debug|System32.*wbem",
     "anti-analiz", 15, "Anti-analiz (sandfly olarak yakalanmaktan kaçma)"),
    (r"kill.*self|del .*/f|self[- ]?delete|erase.*\.exe", "iz-silme",
     15, "Kendini silme (izleri yok etme)"),
    (r"Base64.*token|encrypt.*steal|XOR.*cookie", "gizleme",
     12, "Çalıntı veriyi kodlayıp gizleme"),
]

KAOLUMLU_KELIMELER = ("loader", "deobf", "analyze", "analyzer", "benign", "demo",
                      "örnek", "test", "dummy", "placeholder")


def _yorumsuz(text: str) -> str:
    """Yorumları (Lua --) atarak skoru şişirmeyi engelle."""
    out = []
    for L in text.splitlines():
        L = re.sub(r"--\[\[.*?\]\]", " ", L)
        L = re.sub(r"--.*$", "", L)
        out.append(L)
    return "\n".join(out)


def _kanit(havuz: str, rx: str, n: int = 2, uz: int = 80) -> list[str]:
    out, rxp = [], re.compile(rx, re.I)
    for L in havuz.splitlines():
        if L.strip() and rxp.search(L):
            sn = re.sub(r"\s+", " ", L.strip())
            if len(sn) > uz:
                sn = sn[:uz - 3] + "..."
            out.append(sn)
            if len(out) >= n:
                break
    return out


def investigate(text: str, ek_havuz: str = "") -> dict:
    """Scripti stealer açısından derinlemesine araştırır."""
    kaynak = _yorumsuz(text) + ("\n" + (ek_havuz or ""))
    low = kaynak.lower()

    R = {
        "is_stealer": False, "guven": 0, "kategoriler": [], "hedefler": [],
        "sizdirma": [], "bulgular": [], "marka": None,
        "ozet": "", "vers": VERS,
    }

    puan = 0
    kat_puan: dict[str, int] = {}

    # 1) bilinen marka (en yüksek sinyal)
    for rx, isim in STEALER_MARKALARI:
        if re.search(rx, kaynak, re.I):
            R["marka"] = isim
            puan += 50
            kat_puan["marka"] = kat_puan.get("marka", 0) + 50
            kt = _kanit(kaynak, rx, 1)
            R["bulgular"].append(("🏷️ marka", 50, f"Tanınan stealer imzası: {isim}", kt))
            R["kategoriler"].append("bilinen-stealer")
            break

    # 2) hedefler (neyi çalıyor)
    for rx, kat, p, acik in HEDEF_DESENLERI:
        if re.search(rx, kaynak, re.I):
            puan += p
            kat_puan[kat] = kat_puan.get(kat, 0) + p
            kt = _kanit(kaynak, rx, 2)
            R["bulgular"].append((f"🎯 {kat}", p, acik, kt))
            if kat not in R["hedefler"]:
                R["hedefler"].append(kat)

    # 3) sizdirma kanalları (nereye gönderiyor)
    for rx, acik in SIZDIRMA_KANALLARI:
        if re.search(rx, kaynak, re.I):
            puan += 22
            kt = _kanit(kaynak, rx, 1)
            R["bulgular"].append(("📡 sizdirma", 22, acik, kt))
            R["sizdirma"].append(acik.split(" (")[0])
            kat_puan["sizdirma"] = kat_puan.get("sizdirma", 0) + 22

    # 4) davranış kalıpları
    for rx, kat, p, acik in DAVRIS_DESENLERI:
        if re.search(rx, kaynak, re.I):
            puan += p
            kt = _kanit(kaynak, rx, 1)
            R["bulgular"].append((f"🧬 {kat}", p, acik, kt))

    R["bulgular"].sort(key=lambda x: -x[1])

    # güven skorunu sıfırla: açıkça zararsız demo kelimeleri varsa düşür
    if any(k in low for k in KAOLUMLU_KELIMELER):
        puan = int(puan * 0.6)

    R["guven"] = max(0, min(100, puan))

    # stealer kararı: ya marka yakalandı ya da bir hedef + bir sizdirma kanalı birlikte var
    hedef_var = bool(R["hedefler"])
    sizdirma_var = bool(R["sizdirma"])
    R["is_stealer"] = bool(
        R["marka"] or (hedef_var and sizdirma_var) or R["guven"] >= 60
    )

    # insan-okur özet
    parca = []
    if R["marka"]:
        parca.append(f"🏷️ Bilinen stealer: {R['marka']}")
    if R["hedefler"]:
        etiket = {"roblox": "🟦 Roblox çerezi/hesabı", "discord": "💬 Discord tokeni",
                  "browser": "🌐 Tarayıcı şifreleri", "crypto": "💰 Kripto cüzdan",
                  "keylogger": "⌨️ Tuş/pano kaydı", "session": "🔐 SSH/AWS oturumu",
                  "game-account": "🎮 Oyun hesabı"}
        hedef_metin = ", ".join(etiket.get(h, h) for h in R["hedefler"])
        parca.append(f"🎯 ÇALIYOR: {hedef_metin}")
    if R["sizdirma"]:
        parca.append("📡 SIZDIRMA: " + ", ".join(R["sizdirma"][:3]))
    if not parca:
        parca.append("Stealer/toksalıcı desen bulunamadı.")
    R["ozet"] = " • ".join(parca)
    return R


def alarm_metni(R: dict) -> str:
    """Stealer ise kullanıcıya gösterilecek kısa alarm metni."""
    if not R["is_stealer"]:
        return ""
    sat = [f"🚨🚨🚨 STEALER TESPİT EDİLDİ! (güven %{R['guven']}) 🚨🚨🚨",
           R["ozet"],
           "⛔ KESİNLİKLE ÇALIŞTIRMA — hesap/şifre/cüzdan kaybı riski!",
           "🔍 Kanıtlar:"]
    for kat, p, acik, kt in R["bulgular"][:5]:
        sat.append(f"  {kat} (+{p}) {acik}")
        if kt:
            sat.append(f"      └ `{kt[0]}`")
    return "\n".join(sat)
