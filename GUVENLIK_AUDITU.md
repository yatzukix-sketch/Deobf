# 🔐 Deobf Bot — Güvenlik & Hata Denetimi

Tarih: 2026-08-08 · İncelenen dosyalar: `bot.py, analyzer.py, deobf.py, deobfuscator.py, chatmod.py, trace_to_lua.py, prettifier.py`

> Genel: Token env'den geliyor (✅ doğru), syntax temiz, tasarım güzel. Ama **güvenlik tarafında 2 ciddi açık** var.

---

## 🔴 KRİTİK

### 1. Güvensiz Lua kodu çalıştırma → Uzaktan Kod Çalıştırma (RCE) + Bellek DoS
**Yer:** `deobfuscator.py → deobfuscate_runtime()` (ve `deobf.py → deobf_pipeline()` bunu çağırır; `bot.py → .l, .aly, .rt` hepsi buna düşer)

Bot, kullanıcının gönderdiği **güvenilmeyen Lua scriptini** `lua51` ile çalıştırıyor. "Sandbox" sadece `os, io, package, debug = nil` yapıyor — bu **yeterli değil**:

- **Bellek sınırı yok** → tek bir kötü niyetli script dev string/tablo üretip sunucuyu **OOM ile çökertir** (10 sn timeout sadece CPU'yu yakalar, belleği değil). Bot Heroku worker'ı = işlem ölür.
- **Lua 5.1 sandbox kaçışları biliniyor** (`coroutine`, `string.dump` ile bytecode üretimi, `getfenv`/`setfenv` ile ortam gezme). Sandbox kırılırsa **botun çalıştığı makinede kod çalıştırma (RCE)** = tam sunucu ele geçirme.
- Tetikleyen herkes: `.l`, `.aly`, `.rt` komutlarına herhangi bir URL/dosya veren **her kullanıcı** (DM dahil).

**Çözüm:**
- Üretimde runtime/Lua çalıştırmayı **tamamen kapat**. Statik çözümleyici (`recursive_deobf`, `wrd_full_deobf`) çoğu işi zaten yapıyor. `deobfuscate_runtime` çağrısını `deobf_pipeline`'dan çıkar veya env bayrağıyla devre dışı bırak.
- Mutlaka çalışacaksa: subprocess'e `ulimit -v` (bellek) + `timeout` + ağsız namespace (docker `--network= none`) içinde çalıştır. Lua 5.1 sandbox'una güvenme.

### 2. Komut yetkilendirmesi yok → İstismar amplifikatörü
**Yer:** `bot.py` (tüm komutlar)

Hiçbir komutta `@commands.is_owner()`, rol/sunucu kısıtı veya **rate-limit** yok. Sonuç:
- Herhangi biri `.get/.l/.aly/.rt <url>` ile **botu proxy gibi kullanıp** kendi adına istek attırabilir (aşağıdaki SSRF ile birleşince iç ağ taraması).
- `.aly` zincir takibi 8 alt-link çekip her birini analiz eder + obf ise Lua çalıştırır → **amplifikasyon/DoS**.

**Çözüm:**
- Hassas komutları `.rt`/`.l`'yi `@commands.is_owner()` veya belirli role kapat.
- Kanal başına cooldown ekle: `@commands.cooldown(2, 30, commands.BucketType.channel)`.
- Zincir derinliğini (8) üretimde 2-3'e indir.

---

## 🟠 YÜKSEK

### 3. SSRF koruması yarım — DNS rebinding + yönlendirme bypass'ı
**Yer:** `deobf.py → is_safe_url()`

`is_safe_url` önce DNS çözüp IP'yi kontrol ediyor, sonra `urlopen` **tekrar DNS çözüyor**. Arada kötü niyetli DNS sunucusu cevabı değiştirebilir (**DNS rebinding**) → `127.0.0.1`, `169.254.169.254` (bulut metadata'sı — token çalma!) veya iç ağa erişim.

Ayrıca:
- `urlopen` **varsayılan olarak yönlendirmeleri (3xx) takip eder** → "güvenli" URL iç IP'ye 302 atıp `is_safe_url`'i atlatır.
- Her `fetch`'te DNS lookup → yavaş DNS ile **DoS**.

**Çözüm:**
- `HTTPRedirectHandler`'ı devre dışı bırak (`urllib.request.build_opener(NoRedirect)`), yönlendirmeyi manuel + tekrar `is_safe_url`'den geçir.
- Socket düzeyinde bağlanılan IP'yi kontrol et (custom `HTTPConnection` ile IP'ye bağlan, host header ver) — tek çözüm = tek DNS çözümü.
- Metadata IP'lerini (`169.254.169.254`) kara listeye al.

---

## 🟡 ORTA — Hatalar

### 4. `analyzer.py` satır 288 — `re` modülünü kirleten çöp satır
```python
for rx, kat, puan, acik in DESENLER:
    lines = re.findall_rx = None   # ❌ re.findall_rx diye sahte attribute yaratır, lines kullanılmıyor
```
Sonuç bozmasa da `re` modülüne çöp attribute ekliyor ve bariz hatalı. **Sil** (`lines = re.findall_rx = None` → kaldır).

### 5. `prettifier.py` — girinti mantığı bozuk
```python
if any(line.endswith(t) for t in open_tokens) or "(" in line and not ")" in line:
```
İşlemci önceliği yüzünden bu, "(" içeren ama aynı satırda ")" olmayan **her satırı** girintiler → çok satırlı fonksiyon çağrılarında çığırından çıkan girinti. Parantez derinliği takibi gerekir, bu basit string kontrolü yetmez. Gerçek Lua'da çıktıyı bozar.

### 6. `trace_to_lua.py` — ölü/bozuk kod
`remaining_ops` `operations.index(op)` (ilk eşleşmeyi döner, duplicate'lerde hatalı) ile hesaplanıyor **ama hiç kullanılmıyor**. Sil ya da düzelt.

### 7. `deobf.py → recursive_deobf` base64 çözücü agresif
40+ karakterlik her base64 görünümlü string, "game/loadstring/local/function" içeren bir şey decode ederse **yerine koyuluyor** → meşru kodu bozabilir (false positive). Eşikleri sıkılaştır, "replace" yerine yoruma al.

---

## 🟢 DÜŞÜK / Hijyen

### 8. `.gitignore` yok → `__pycache__/*.pyc` ve `bot.log` commit'leniyor
Repo'da derlenmiş bytecode ve log commit'lenmiş. `bot.log` ileride hassas veri biriktirebilir. `.gitignore` ekle:
```
__pycache__/
*.pyc
bot.log
.env
```

### 9. Özel `.env` çözücü kırılgan (`bot.py _load_dotenv`)
`python-dotenv` kullanmak yerine elle parse ediliyor. Boşluklu/alıntılı değerlerde kırılır. `pip install python-dotenv` → `load_dotenv()`.

---

## ✅ Hızlı Öncelik Sırası
1. **Lua çalıştırmayı kapat** (`deobfuscator_runtime` çağrısını devre dışı bırak) — en kritik.
2. Komutlara **yetki + cooldown** ekle.
3. SSRF'yi **yönlendirme kapatma + metadata kara liste** ile sağlamlaştır.
4. `analyzer.py` çöp satırı sil, `.gitignore` ekle.
5. `prettifier.py` girintiyi düzelt.

_Bunlardan herhangi birini hemen yapmamı istersen söyle, kodu düzelteyim._ 🛠️
