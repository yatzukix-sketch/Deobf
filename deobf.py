#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
deobf.py — Deobf Bot motoru (saf python, bagimliliksiz)
Kisla K-7 laboratuvarindan damitildi. drone blob yasalari dahil.
Yetenekler:
  - URL/site fetch + "raw script" avcisi (html icinden gercek .lua cikarma)
  - Obfuscator TESHISI: Luraph/LuaProt/Luarmor(superflow)/PSU/MoonSec/minify/hex/base64
  - Katman cozuculer: unhex, base64-blok, escape temizligi
  - LuaProt/Luraph XSUB blob extractor: 'LPH+' marker, z->!!, ilk 4 char at, base85 decode
  - String table dokumu + hook/remote adaylari
Cikti: (teshis_raporu:str, ciktilar:dict[str,bytes])
"""
import re, base64, binascii, urllib.request, io, html as H

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"

# ---------- FETCH ----------
def fetch(url: str, timeout: int = 25) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read()

RAW_HOST_FIX = [
    # ---- BUYUK LINK RADARI: sayfa URL'sini RAW URL'sine cevirir ----
    (re.compile(r"https?://pastebin\.com/(?!raw/)(\w+)"), r"https://pastebin.com/raw/\1"),
    (re.compile(r"https?://paste\.c-net\.org/(?!raw/)(\w+)"), r"https://paste.c-net.org/raw/\1"),
    (re.compile(r"https?://gist\.github\.com/([\w-]+)/([0-9a-f]{8,})"), r"https://gist.githubusercontent.com/\1/\2/raw"),
    (re.compile(r"https?://github\.com/([\w.-]+)/([\w.-]+)/blob/([^/]+)/(.+)"), r"https://raw.githubusercontent.com/\1/\2/\3/\4"),
    (re.compile(r"https?://gitlab\.com/(.+?)/-/blob/(.+)"), r"https://gitlab.com/\1/-/raw/\2"),
    (re.compile(r"https?://rentry\.co/([\w-]+)(?:/raw)?/?$"), r"https://rentry.co/\1/raw"),
    (re.compile(r"https?://rentry\.org/([\w-]+)(?:/raw)?/?$"), r"https://rentry.org/\1/raw"),
    (re.compile(r"https?://hastebin\.com/(?!raw/)(\w+)"), r"https://hastebin.com/raw/\1"),
    (re.compile(r"https?://pastefy\.de/([\w-]+)(?:/raw)?/?$"), r"https://pastefy.de/\1/raw"),
    (re.compile(r"https?://sourceb\.in/([\w-]+)(?:/raw)?/?$"), r"https://sourceb.in/\1/raw"),
    (re.compile(r"https?://controlc\.com/(?!raw)([0-9a-f]+)"), r"https://controlc.com/raw.php?slug=\1"),
    (re.compile(r"https?://paste\.ee/p/([\w-]+)"), r"https://paste.ee/r/\1"),
    (re.compile(r"https?://xhider\.xyz/view/(.+)"), r"https://xhider.xyz/raw/\1"),
]
def normalize_raw_url(u: str) -> str:
    u = u.strip().strip("<>")
    if u.endswith("/raw") or "/raw/" in u: return u
    for rx, rep in RAW_HOST_FIX:
        if rx.search(u): return rx.sub(rep, u)
    return u

def smart_fetch(url: str, timeout: int = 25) -> tuple[bytes, str]:
    """.get motoru: normalize -> UA+Referer'li fetch -> rapor. donen: (icerik, iznotu)"""
    notes = []
    u2 = normalize_raw_url(url)
    if u2 != url: notes.append(f"raw-yol cevirildi: {u2}")
    ref = "/".join(u2.split("/")[:3]) + "/"
    req = urllib.request.Request(u2, headers={
        "User-Agent": UA,
        "Referer": ref,
        "Accept": "*/*",
    })
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            data = r.read()
            notes.append(f"HTTP {r.status} | {r.headers.get('content-type','?')}")
            return data, " | ".join(notes)
    except Exception as e:
        # ham URL ile son sans
        if u2 != url:
            notes.append("raw-yol patladi, orijinal link deneniyor…")
            req = urllib.request.Request(url, headers={"User-Agent": UA, "Referer": ref})
            with urllib.request.urlopen(req, timeout=timeout) as r:
                data = r.read()
                notes.append(f"HTTP {r.status} (orijinal link)")
                return data, " | ".join(notes)
        raise RuntimeError(f"fetch basarisiz: {e}")

def extract_script_from_html(doc: str) -> str | None:
    # klasik loader siteleri: <pre>, textarea, veya "loadstring..." iceren ham blok
    m = re.search(r"<pre[^>]*>(.*?)</pre>", doc, re.S | re.I)
    if m: return H.unescape(m.group(1)).strip()
    m = re.search(r"(loadstring\s*\(.*?)\s*</", doc, re.S)
    if m: return H.unescape(m.group(1)).strip()
    if "loadstring" in doc and len(doc) < 200_000:
        return doc  # sayfa zaten ham script olabilir
    return None

# ---------- TESHIS ----------
SIGNATURES = [
    ("Luraph v14 (LPH_ prefix + VM)", [r"LPH_", r"IlIlIlI", r"lPH[A-Za-z0-9_]{2,}"]),
    ("LuaProt (LP_/LP_NOTIFY + XSUB)", [r"LP_[0-9]{6,}", r"LP_NOTIFY", r"LPH\+"]),
    ("Luarmor Superflow", [r"superflow", r"sandbox_args", r"Luarmor"]),
    ("PSU Obfuscator", [r"protected by PSU", r"PSU_\w{8,}", r"psu_obfuscator"]),
    ("MoonSec v3", [r"moonsec", r"MoonSec", r"\]\]\]\s*;?\s*local"]),
    ("Hex escape duvari (\\x..)", [r"(?:\\x[0-9a-fA-F]{2}){8,}"]),
    ("Base64 blok(cu)", [r"[A-Za-z0-9+/]{80,}={0,2}"]),
    ("Minified tek satir", [r"^.{3000,}$"]),
]
def detect(text: str) -> list[str]:
    hits = []
    for name, pats in SIGNATURES:
        for p in pats:
            if re.search(p, text, re.M):
                hits.append(name); break
    if not hits: hits.append("Bilinmiyor (temiz Lua olabilir)")
    return hits

# ---------- COZUCULER ----------

def unhex(text: str) -> tuple[str, int]:
    # \x41 -> A  (sadece string literal icindekileri korumak icin basit gecis)
    cnt = len(re.findall(r"\\x[0-9a-fA-F]{2}", text))
    if cnt < 8: return text, 0
    def rep(m):
        try: return bytes([int(m.group(1), 16)]).decode("latin-1")
        except: return m.group(0)
    return re.sub(r"\\x([0-9a-fA-F]{2})", rep, text), cnt


def unbase64_blocks(text: str) -> tuple[str, int]:
    cnt = 0
    def rep(m):
        nonlocal cnt
        s = m.group(0)
        try:
            d = base64.b64decode(s, validate=True)
            if sum(32 <= b < 127 or b in (9, 10, 13) for b in d) > len(d) * 0.85 and len(d) >= 24:
                cnt += 1
                return d.decode("utf-8", "replace")
        except Exception:
            pass
        return s
    return re.sub(r"[A-Za-z0-9+/]{80,}={0,2}", rep, text), cnt

# ---------- LuaProt/Luraph XSUB (drone'da kirilmis yasa) ----------

def find_megastring(text: str) -> str | None:
    best = None
    for m in re.finditer(r'"((?:[^"\\]|\\.){40000,})"', text):
        best = m.group(1) if best is None or len(m.group(1)) > len(best) else best
    return best


def _unescape_lua(s: str) -> str:
    out = io.StringIO()
    i, n = 0, len(s)
    while i < n:
        c = s[i]
        if c == "\\" and i + 1 < n:
            nxt = s[i + 1]
            if nxt == "z":
                i += 2
                while i < n and s[i] in " \t\r\n": i += 1
                continue
            if nxt == "x" and i + 3 < n:
                try: out.write(bytes([int(s[i+2:i+4], 16)]).decode("latin-1")); i += 4; continue
                except: pass
            m = re.match(r"\\(\d{1,3})", s[i:])
            if m:
                v = int(m.group(1))
                if v <= 255: out.write(bytes([v]).decode("latin-1")); i += 1 + len(m.group(1)); continue
            simple = {"n": "\n", "r": "\r", "t": "\t", "\\": "\\", '"': '"', "a": "\a", "b": "\b", "f": "\f", "v": "\v"}
            if nxt in simple: out.write(simple[nxt]); i += 2; continue
            out.write(nxt); i += 2; continue
        out.write(c); i += 1
    return out.getvalue()


def xsub_decode(blob: str) -> bytes | None:
    # YASA (drone'da muhurlendi): blob 'LPH+' ile baslar -> ilk 4 char at,
    # geri kalan charlar 5'li gruplar: v = c1*85^4+c2*85^3+c3*85^2+c4*85+c5 (char-33), mod 2^32
    # grup -> 4 byte BIG-ENDIAN.
    raw = blob if not blob.startswith(("LPH+", "LPH-")) else blob[4:]
    if blob.startswith(("LPH+", "LPH-")) is False and len(blob) > 4:
        raw = blob[4:]
    raw = "".join(ch for ch in raw if 33 <= ord(ch) <= 126)
    raw = raw[: len(raw) - len(raw) % 5]
    if len(raw) < 100: return None
    out = bytearray()
    for i in range(0, len(raw), 5):
        v = 0
        for ch in raw[i:i+5]:
            d = ord(ch) - 33
            if d > 84: d = 0  # bozuk digit -> sifir (aklini koru, kirilma)
            v = (v * 85 + d) & 0xFFFFFFFF
        out += v.to_bytes(4, "big")
    if len(out) < 50: return None
    return bytes(out)


def extract_xsub(text: str) -> tuple[bytes | None, dict]:
    info = {}
    mega = find_megastring(text)
    if not mega: return None, info
    mega = _unescape_lua(mega)  # gercek payload'larda literal escape'li gelir
    marker = None
    for mk in ("LPH+", "LPH-"):  # LuaProt(+)/Luraph(-) aileleri
        if mk in mega: marker = mk; break
    info["megastring_len"] = len(mega)
    info["marker"] = marker
    if marker:
        idx = mega.index(marker)
        info["marker_index"] = idx
        # blob marker'dan baslar (escape'siz metin); _unescape uygulanmis mega kullan
        blob = mega[idx:]
        data = xsub_decode(blob)
        if data:
            info["decoded_bytes"] = len(data)
            info["magic"] = data[:16].hex()
            return data, info
    return None, info

# ---------- STRING TABLE ----------

def dump_strings(text: str, top: int = 60) -> str:
    strs = re.findall(r'"([^"\\\n]{6,300})"', text) + re.findall(r"'([^'\\\n]{6,300})'", text)
    seen, out = set(), []
    for s in strs:
        if s in seen: continue
        seen.add(s)
        if sum(32 <= ord(c) < 127 for c in s) < len(s) * 0.9 and len(s) < 60: continue
        out.append(s)
    keys = ("Remote", "Event", "FireServer", "InvokeServer", "RequestAsync", "HttpGet", "hook", "getgenv", "gethui", "Instance", "loadstring")
    hits = [s for s in out if any(k.lower() in s.lower() for k in keys)]
    lines = ["# STRING TABLE DOKUMU", f"toplam benzersiz aday: {len(out)}", f"hook/remote adaylari: {len(hits)}", "", "## HOOK/REMOTE ADAYLARI"]
    lines += (f"- {h[:160]}" for h in hits[:40])
    lines.append("")
    lines.append("## ILK STRINGS")
    lines += (f"- {s[:160]}" for s in out[:top])
    return "\n".join(lines)

# ---------- LuaProt V2 CHAIN-FOLLOW (2. sahnenin izini surer) ----------

def follow_luaprot_stub(text: str) -> tuple[str | None, str | None]:
    """LuaProt V2 stub -> (stage2_url, notu). Kapali lisans kapisini da raporlar."""
    if "luaprot.net/api/v2/loader/get" not in text: return None, None
    sid = re.search(r'local f,c,v="(\d{6,})"', text)
    if not sid: return None, None
    GATES = ("Hwid", "blacklist", "not found", "denied", "key", "license", "Kick")
    for n in ["eu-1", "us-1", "eu-2"]:
        u = f"https://{n}.luaprot.net/api/v2/loader/get?key=x&scriptId={sid.group(1)}"
        try:
            d = fetch(u, timeout=20)
            body = d[:600].decode("utf-8", "replace")
            if len(d) > 3000 and not any(g in body for g in GATES):
                return u, "stage-2 payload yakalandi"
            m = re.search(r"\[=\[(.+?)\]=\]", body)
            reason = m.group(1) if m else body[:80]
            if "loader failed" in body.lower():
                continue
            return u, f"LISANS KAPISI (stage-2 kapali): {reason}"
        except Exception:
            continue
    return None, "stage-2 node'larina ulasilamadi"

# ---------- ANA PIPELINE ----------

def deobf_pipeline(name: str, content: bytes, _depth: int = 0) -> tuple[str, dict[str, bytes]]:
    out: dict[str, bytes] = {}
    try:
        text = content.decode("utf-8")
    except UnicodeDecodeError:
        text = content.decode("latin-1", "replace")
    rep = [f"🔬 DEOBF RAPORU — {name}", f"boyut: {len(content):,} byte"]
    if "<html" in text[:2000].lower() or "<!doc" in text[:2000].lower():
        rep.append("⚠️ Icerik HTML gorunuyor — script blogu ayrildi.")
        ex = extract_script_from_html(text)
        if ex: text = ex; rep.append(f"✅ script blogu cekildi ({len(text):,} char)")
        else: rep.append("❌ sayfadan ham script cikaramadim")
    # LuaProt V2 stub -> stage-2 takip (loader'in kendi public akisi)
    if _depth == 0:
        nxt, notu = follow_luaprot_stub(text)
        if nxt and notu and "yakalandi" in notu:
            rep.append(f"⛓️ LuaProt V2 stub yakalandi — STAGE-2 izi suruluyor:\n   {nxt}")
            try:
                d2 = fetch(nxt, timeout=30)
                rep.append(f"📥 stage-2 indi: {len(d2):,} byte — zincir devam ediyor")
                rep2, out2 = deobf_pipeline("stage2-" + name, d2, _depth=1)
                merged: dict[str, bytes] = {"stage1_" + "deobf.txt": text.encode()}
                merged.update(out2)
                rep.append(rep2)
                return "\n".join(rep), merged
            except Exception as e:
                rep.append(f"⚠️ stage-2 cekilemedi: {e}")
        elif notu:
            rep.append(f"⛓️ LuaProt V2 stub tespit edildi → 🔒 {notu}")
            rep.append("   (lisans/HWID kapisi disaridan acilmaz; stub analizi asagida)")
    hits = detect(text)
    rep.append("🏷️ teshis: " + " | ".join(hits))
    cur = text
    cur, nh = unhex(cur)
    if nh: rep.append(f"🧬 hex escape cozuldu: {nh:,} adet")
    cur, nb = unbase64_blocks(cur)
    if nb: rep.append(f"🧬 base64 blok cozuldu: {nb} adet")
    data, xinfo = extract_xsub(text)
    if data:
        rep.append(f"🎯 XSUB blob ASILDI: {xinfo.get('decoded_bytes'):,} byte (marker {xinfo.get('marker')} @ {xinfo.get('marker_index')}, magic {xinfo.get('magic')})")
        out["payload.bin"] = data
    out["strings.txt"] = dump_strings(cur).encode()
    out["deobf.txt"] = cur.encode()
    if not data and not nh and not nb and "Bilinmiyor" not in hits[0]:
        rep.append("ℹ️ Decoder kancasi tutmadi — tam VM cozumu icin Sensei el analizi gerekir (dump dosyalari yine eklendi).")
    rep.append("✅ bitti — ciktilar: deobf.txt" + (", payload.bin" if data else "") + ", strings.txt")
    return "\n".join(rep), out
