#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
deobf.py — Deobf Bot motoru (iyileştirilmiş sürüm)
"""
import re, base64, binascii, urllib.request, io, html as H
import socket, ipaddress, ast, logging

# Logging yapılandırması
logger = logging.getLogger("Deobf.Engine")

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"

# ---------- GÜVENLİK: SSRF Koruması ----------
def is_safe_url(url: str) -> bool:
    """URL'nin yerel ağda olup olmadığını kontrol eder (SSRF koruması)."""
    try:
        hostname = urllib.parse.urlparse(url).hostname
        if not hostname:
            return False
        ip = socket.gethostbyname(hostname)
        ip_obj = ipaddress.ip_address(ip)
        return not (ip_obj.is_private or ip_obj.is_loopback or ip_obj.is_link_local or ip_obj.is_multicast)
    except Exception as e:
        logger.error(f"URL güvenlik kontrolü hatası: {e}")
        return False

# ---------- FETCH ----------
def fetch(url: str, timeout: int = 25) -> bytes:
    if not is_safe_url(url):
        raise ValueError(f"Güvenli olmayan URL engellendi: {url}")
    
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read()

RAW_HOST_FIX = [
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
    notes = []
    u2 = normalize_raw_url(url)
    if u2 != url: notes.append(f"raw-yol cevirildi: {u2}")
    
    if not is_safe_url(u2):
        raise ValueError(f"Güvenli olmayan URL engellendi: {u2}")

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
        if u2 != url and is_safe_url(url):
            notes.append("raw-yol patladi, orijinal link deneniyor…")
            req = urllib.request.Request(url, headers={"User-Agent": UA, "Referer": ref})
            with urllib.request.urlopen(req, timeout=timeout) as r:
                data = r.read()
                notes.append(f"HTTP {r.status} (orijinal link)")
                return data, " | ".join(notes)
        raise RuntimeError(f"fetch basarisiz: {e}")

def extract_script_from_html(doc: str) -> str | None:
    m = re.search(r"<pre[^>]*>(.*?)</pre>", doc, re.S | re.I)
    if m: return H.unescape(m.group(1)).strip()
    m = re.search(r"(loadstring\s*\(.*?)\s*</", doc, re.S)
    if m: return H.unescape(m.group(1)).strip()
    if "loadstring" in doc and len(doc) < 200_000:
        return doc
    return None

# ---------- TESHIS ----------
SIGNATURES = [
    ("WeAreDevs (WRD) obfuscator", [r"wearedevs\.net/obfuscator"]),
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
            if d > 84: d = 0
            v = (v * 85 + d) & 0xFFFFFFFF
        out += v.to_bytes(4, "big")
    if len(out) < 50: return None
    return bytes(out)

def extract_xsub(text: str) -> tuple[bytes | None, dict]:
    info = {}
    mega = find_megastring(text)
    if not mega: return None, info
    mega = _unescape_lua(mega)
    marker = None
    for mk in ("LPH+", "LPH-"):
        if mk in mega: marker = mk; break
    info["megastring_len"] = len(mega)
    info["marker"] = marker
    if marker:
        idx = mega.index(marker)
        info["marker_index"] = idx
        blob = mega[idx:]
        data = xsub_decode(blob)
        if data:
            info["decoded_bytes"] = len(data)
            info["magic"] = data[:16].hex()
            return data, info
    return None, info

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

def follow_luaprot_stub(text: str) -> tuple[str | None, str | None]:
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

# ---------- GÜVENLİK: Güvenli Eval ----------
def _wrd_ev(e: str):
    e = e.strip()
    if re.fullmatch(r'[-\d\s()+]+', e):
        try:
            # ast.literal_eval sadece temel veri tiplerini destekler, güvenlidir.
            # Ancak matematiksel ifadeler (örn: 1+2) için basit bir parser daha iyidir.
            # Burada sadece basit sayısal ifadeler beklendiği için güvenli bir şekilde işliyoruz.
            return int(ast.literal_eval(e))
        except Exception:
            # literal_eval matematiksel işlemleri doğrudan yapmaz, manuel işlem gerekebilir.
            try:
                # Sadece güvenli karakterler varsa eval'e çok kısıtlı bir ortamda izin verilebilir.
                return int(eval(e, {"__builtins__": None}, {}))
            except:
                return None
    return None

def wrd_v1(text: str) -> tuple[dict, dict[str, bytes]]:
    info: dict = {}
    if "wearedevs.net/obfuscator" not in text:
        return info, {}

    def _unesc(s: str) -> str:
        return re.sub(r"\\(\d{3})", lambda m: chr(int(m.group(1))), s)

    t0 = text.find("local U={")
    t1 = text.find("}local function", t0)
    if t0 < 0 or t1 < 0:
        return {"hata": "U tablosu yok"}, {}
    raw = [_unesc(m) for m in re.findall(r'"((?:\\\d{3}|[^"\\])*)"', text[t0:t1])]
    info["u_tablosu"] = len(raw)

    U = list(raw)
    swaps: list = []
    mw = re.search(r"for\s+\w+\s*,\s*\w+\s+in\s+ipairs\s*\(\s*\{\{", text)
    if mw:
        for g in re.findall(r"\{([^{}]+)\}", text[mw.start():mw.start() + 300])[:3]:
            p = re.split(r"[;,]", g)
            a = _wrd_ev(p[0]); b = _wrd_ev(p[1]) if len(p) > 1 else None
            if a is not None and b is not None:
                swaps.append((a, b))
    for a, b in swaps:
        while a < b:
            U[a - 1], U[b - 1] = U[b - 1], U[a - 1]
            a += 1; b -= 1
    info["swap"] = len(swaps)

    s0 = text.find("local S={")
    if s0 < 0:
        return {"hata": "S blogu yok"}, {}
    sblk = text[text.find("{", s0) + 1:text.find("}", s0)]
    S2: dict[str, int] = {}
    for m in re.finditer(r'(?:([A-Za-z])|\["\\(\d{3})"\])\s*=\s*([^,;}]+)', sblk):
        key = m.group(1) if m.group(1) else chr(int(m.group(2)))
        v = _wrd_ev(m.group(3))
        if v is not None and 0 <= v < 64:
            S2[key] = v
    info["s_haritasi"] = len(S2)
    if len(S2) < 60:
        return info, {}

    def b64d(s: str) -> bytes:
        d = 0; b = 0; out = bytearray(); i = 0; n = len(s)
        while i < n:
            ch = s[i]
            if ch in S2:
                d += S2[ch] << (6 * (3 - b)); b += 1
                if b == 4:
                    out += bytes([(d >> 16) & 255, (d >> 8) & 255, d & 255])
                    d = 0; b = 0
            elif ch == "=":
                out.append((d >> 16) & 255)
                if i + 1 >= n or s[i + 1] != "=":
                    out.append((d >> 8) & 255)
                break
            i += 1
        return bytes(out)

    decoded = [b64d(u) for u in U]

    def is_txt(x: bytes) -> bool:
        if not x: return False
        try:
            t = x.decode("utf-8")
            return all(ch.isprintable() or ch in "\n\r\t" for ch in t)
        except: return False

    info["txt_string"] = sum(1 for d in decoded if is_txt(d))
    info["bin_veri"] = len(decoded) - info["txt_string"]

    def lit(d: bytes) -> str:
        if is_txt(d):
            t = d.decode("utf-8").replace("\\", "\\\\").replace('"', '\\"')
            t = t.replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t")
            return '"' + t + '"'
        return '"' + "".join(f"\\{b:03d}" for b in d) + '"'

    out_lines = [f"local decoded = {{"]
    for i, d in enumerate(decoded, 1):
        out_lines.append(f"  [{i}] = {lit(d)},")
    out_lines.append("}")
    
    deobf_code = "\n".join(out_lines)
    return info, {"wrd_strings.txt": "\n".join(lit(d) for d in decoded).encode(), "deobf.txt": deobf_code.encode()}

def deobf_pipeline(name: str, content: bytes) -> tuple[str, dict[str, bytes]]:
    text = content.decode("utf-8", "replace")
    outputs = {}
    report = []
    
    hits = detect(text)
    report.append(f"Teshis: {', '.join(hits)}")
    
    # WRD v1
    if "WeAreDevs (WRD) obfuscator" in hits:
        info, wrd_out = wrd_v1(text)
        outputs.update(wrd_out)
        report.append(f"WRD v1: {info.get('u_tablosu', 0)} string, {info.get('txt_string', 0)} metin")

    # XSUB
    data, xinfo = extract_xsub(text)
    if data:
        outputs["payload.bin"] = data
        report.append(f"XSUB: {xinfo.get('decoded_bytes', 0)} byte ayiklandi")

    # Strings
    outputs["strings.txt"] = dump_strings(text).encode()
    
    return "\n".join(report), outputs
