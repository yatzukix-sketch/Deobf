# 🤖 DEOBF BOT — Kurulum & Hosting

## 🔐 0. TOKEN GÜVENLİĞİ (ÖNCE BUNU OKU)
- Chate yapıştırılan token **YANDI** → Discord Developer Portal → Bot → **Reset Token** ile YENİSİNİ AL.
- Yeni token asla koda yazılmaz. `.env` dosyasına konur:
  ```
  DISCORD_TOKEN=yeni_token_buraya
  ```
- `.env`'yi kimseyle paylaşma, git'e koyma.

## ⚙️ 1. Kurulum (host'ta 1 kez)
```bash
pip install -r requirements.txt
export DISCORD_TOKEN="yeni_token"   # veya .env kullan (python-dotenv ekleyebilirsin)
python bot.py
```
Konsolda `[+] Deobf Bot online: ...` görünce hazır.

## 🎮 2. Kullanım (Discord'da)
Önek `.` veya `!` (ikisi de çalışır).

| Komut | Açıklama |
|---|---|
| `.l <url/dosya>` | Linki fetchle, deobf et → `deobf.txt` + `strings.txt` |
| `.aly <url/dosya>` | SENSEI-AI v2.3 kanıt-disiplinli güvenlik/davranış analizi + zincir link takibi (`.analiz`) |
| `.sor <soru>` | Son `.aly` analizi hakkında soru-cevap (`.s`, `.soru`) |
| `.sohbet` | Kısa süreli konuşma modu; kapatmak için `cik` yaz (`.chat`, `.c`, `.konus`) |
| `.rt <url/dosya>` | RUNTIME deobf — Prometheus mock-trace motoru (`.runtime`, `.prom`) |
| `.diff <a> <b>` | İki scripti karşılaştır (`.karsilastir`) |
| `.get <url>` | Akıllı URL çekici (raw dönüşümlerle) |
| `.istatistik` | Oturum sayaçları (`.stat`, `.stats`) |
| `.y` | Yardım menüsü (`.yardim`, `.h`) |

Not: `.l` tek başına + ekli txt dosyası → ekteki dosyayı işler.

## 🏠 3. 7/24 HOSTING SEÇENEKLERİ (ücretsiz)
| Host | Not |
|---|---|
| **Railway** | en kolay; repo bağla, env'e token'ı koy, bitti (aylık kredi limitli) |
| **Render** | free web service + keep-alive ping gerekir (uyur) |
| **Fly.io** | free allowance; küçük VM, iyi çalışır |
| **Replit** | tarayıcıdan kur; always-on ücretli olabilir, secret'a token koy |

⚠️ Bu bot **Arena sandbox'tan 7/24 ÇALIŞMAZ** (process'ler tur arası ölür). Yukarıdakilerden birini seç.

## 🧠 4. Ne yapar (dürüst sürüm)
- ✅ Teshis: Luraph/LuaProt/Luarmor/PSU/MoonSec/minify/hex/base64
- ✅ Katman çözer: hex escape, base64 bloklar
- ✅ **LuaProt XSUB blob söker + base85 decode** eder → `payload.bin` (drone projesinde kanıtlı yasa)
- ✅ String table + hook/remote adayları → `strings.txt`
- ⚠️ Ağır VM çözümü (custom Luraph v14 handler'ları) insan işidir — o durumda çıktıları Sensei'ye getir, akademi metoduna devam.

## 🧩 5. WRD notu
"WRD support" ile ne kastettiğini netleştir: WRD API key'in varsa ileride `.wrd` komutu ile executor tarafı entegre edilebilir — anahtarı chate DEĞİL, sonra `.env`'ye.
