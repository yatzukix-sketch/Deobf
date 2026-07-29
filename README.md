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
- `.l https://paste.c-net.org/XYZ` → linki fetchler, deobf eder, `deobf.txt` + `strings.txt` atar
- txt dosyasını mesaja ekle + mesaja sadece `.l` yaz → ek dosyayı işler
- `.y` → yardım

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
