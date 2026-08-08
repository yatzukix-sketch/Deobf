#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
deobf.py — Gelişmiş Deobf Bot Motoru v2.0
Modern WRD, LuaProt ve katmanlı obfuscation çözücü.
"""
import re, base64, binascii, urllib.request, io, html as H
import socket, ipaddress, ast, logging

logger = logging.getLogger("Deobf.Engine")
UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"

# ---------- GÜVENLİK: SSRF Koruması ----------
def is_safe_url(url: str) -> bool:
    try:
        hostname = urllib.parse.urlparse(url).hostname
        if not hostname: return False
        ip = socket.gethostbyname(hostname)
        ip_obj = ipaddress.ip_address(ip)
        return not (ip_obj.is_private or ip_obj.is_loopback or ip_obj.is_link_local or ip_obj.is_multicast)
    except: return False

def fetch(url: str, timeout: int = 25) -> bytes:
    if not is_safe_url(url): raise ValueError(f"Güvenli olmayan URL engellendi: {url}")
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=timeout) as r: return r.read()

def smart_fetch(url: str, timeout: int = 25) -> tuple[bytes, str]:
    u2 = normalize_raw_url(url)
    if not is_safe_url(u2): raise ValueError(f"Güvenli olmayan URL engellendi: {u2}")
    req = urllib.request.Request(u2, headers={"User-Agent": UA, "Referer": "/".join(u2.split("/")[:3]) + "/"})
    with urllib.request.urlopen(req, timeout=timeout) as r: return r.read(), f"HTTP {r.status}"

def normalize_raw_url(u: str) -> str:
    u = u.strip().strip("<>")
    RAW_HOST_FIX = [
        (re.compile(r"https?://pastebin\.com/(?!raw/)(\w+)"), r"https://pastebin.com/raw/\1"),
        (re.compile(r"https?://paste\.c-net\.org/(?!raw/)(\w+)"), r"https://paste.c-net.org/raw/\1"),
        (re.compile(r"https?://gist\.github\.com/([\w-]+)/([0-9a-f]{8,})"), r"https://gist.githubusercontent.com/\1/\2/raw"),
        (re.compile(r"https?://github\.com/([\w.-]+)/([\w.-]+)/blob/([^/]+)/(.+)"), r"https://raw.githubusercontent.com/\1/\2/\3/\4"),
    ]
    for rx, rep in RAW_HOST_FIX:
        if rx.search(u): return rx.sub(rep, u)
    return u

# ---------- GELİŞMİŞ KATMANLI ÇÖZÜCÜ (Core) ----------

def recursive_deobf(text: str, max_depth: int = 5) -> tuple[str, int]:
    """Kodun içindeki katmanları (hex, b64, escape) derinlemesine çözer."""
    total_changes = 0
    current_text = text
    
    for _ in range(max_depth):
        changed = False
        
        # 1. Hex Escape Çözücü (\x41 -> A)
        hex_pats = [r"\\x([0-9a-fA-F]{2})", r"\\([0-9]{3})"]
        for pat in hex_pats:
            matches = re.findall(pat, current_text)
            if len(matches) >= 5:
                def rep(m):
                    try:
                        val = int(m.group(1), 16) if "x" in pat else int(m.group(1))
                        return chr(val) if 32 <= val <= 126 or val in (9, 10, 13) else m.group(0)
                    except: return m.group(0)
                current_text = re.sub(pat, rep, current_text)
                changed = True
                total_changes += len(matches)

        # 2. Base64 Blok Çözücü
        b64_pat = r'["\']([A-Za-z0-9+/]{40,}={0,2})["\']'
        matches = re.findall(b64_pat, current_text)
        for match in matches:
            try:
                decoded = base64.b64decode(match).decode("utf-8", "replace")
                if any(k in decoded for k in ["loadstring", "game", "local", "function"]):
                    current_text = current_text.replace(match, decoded)
                    changed = True
                    total_changes += 1
            except: pass

        if not changed: break
        
    return current_text, total_changes

# ---------- WRD v1 & v2 MODERN ÇÖZÜCÜ ----------

def wrd_full_deobf(text: str) -> tuple[str, dict]:
    """WRD obfuscator'ı full plaintext hale getirir."""
    info = {"engine": "WRD-Advanced"}
    if "wearedevs.net/obfuscator" not in text: return text, {}

    # WRD'nin karmaşık string tablosunu (U tablosu) yakala
    u_match = re.search(r"local U=\{(.*?)\}local function", text, re.S)
    if not u_match: return text, {"error": "U table not found"}
    
    raw_strings = re.findall(r'"(.*?)"', u_match.group(1))
    # Escape'leri temizle
    decoded_strings = []
    for s in raw_strings:
        try:
            # \123 formatındaki escape'leri çöz
            s = re.sub(r"\\(\d{3})", lambda m: chr(int(m.group(1))), s)
            decoded_strings.append(s)
        except: decoded_strings.append(s)
    
    info["strings_found"] = len(decoded_strings)
    
    # Asıl kod bloğunu bul ve stringleri yerine koy
    # WRD genelde c(index) şeklinde çağırır
    def replace_const(m):
        try:
            idx = int(m.group(1))
            if 1 <= idx <= len(decoded_strings):
                val = decoded_strings[idx-1]
                return f'"{val}"'
        except: pass
        return m.group(0)

    # c(123) veya benzeri çağrıları yakala (bu regex obf versiyonuna göre değişebilir)
    # Genelde local c=function(n) return U[n] end şeklinde bir yapı vardır
    c_func_match = re.search(r"local (\w+)=function\(\w+\)return U\[\w+\]end", text)
    if c_func_match:
        c_name = c_func_match.group(1)
        text = re.sub(rf"{c_name}\((\d+)\)", replace_const, text)
        info["replacements"] = "Success"

    # Katmanlı temizlik yap
    final_code, changes = recursive_deobf(text)
    info["recursive_changes"] = changes
    
    return final_code, info

# ---------- ANA PİPELİNE ----------

def deobf_pipeline(name: str, content: bytes) -> tuple[str, dict[str, bytes]]:
    text = content.decode("utf-8", "replace")
    outputs = {}
    report = ["# DEOBF ANALİZ RAPORU v2.0"]
    
    # 1. Adım: WRD Spesifik Çözümleme
    if "wearedevs.net/obfuscator" in text:
        text, winfo = wrd_full_deobf(text)
        report.append(f"- WRD Tespiti: {winfo.get('strings_found', 0)} sabit çözüldü.")
    
    # 2. Adım: Dinamik Emülasyon (Runtime)
    import deobfuscator
    runtime_code = deobfuscator.deobfuscate_runtime(text)
    if runtime_code:
        text += runtime_code
        report.append("- Dinamik Analiz: Bellekten gizli kod parçaları yakalandı.")

    # 3. Adım: Genel Katmanlı Çözümleme
    text, changes = recursive_deobf(text)
    if changes > 0:
        report.append(f"- Katmanlı Çözücü: {changes} adet gizli veri plaintext yapıldı.")

    # 4. Adım: Kod Güzelleştirme
    import prettifier
    try:
        text = prettifier.prettify_lua(text)
        report.append("- Görselleştirme: Kod okunabilirliği için yeniden formatlandı.")
    except: pass

    # 5. Adım: XSUB/LuaProt Ayıklama
    from deobf import extract_xsub # Kendi içinden çağır
    data, xinfo = extract_xsub(text)
    if data:
        outputs["payload.bin"] = data
        report.append(f"- XSUB Payload: {len(data)} byte ayıklandı.")

    # Çıktıları hazırla
    outputs["deobf.txt"] = text.encode()
    
    # String tablosunu ayrıca dök
    from deobf import dump_strings
    outputs["strings.txt"] = dump_strings(text).encode()
    
    return "\n".join(report), outputs

# (Eski yardımcı fonksiyonlar aşağıda korunur)
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
    return bytes(out)

def extract_xsub(text: str) -> tuple[bytes | None, dict]:
    info = {}
    mega = find_megastring(text)
    if not mega: return None, info
    mega = _unescape_lua(mega)
    for mk in ("LPH+", "LPH-"):
        if mk in mega:
            idx = mega.index(mk)
            data = xsub_decode(mega[idx:])
            if data: return data, {"decoded": len(data)}
    return None, info

def dump_strings(text: str, top: int = 60) -> str:
    strs = re.findall(r'"([^"\\\n]{6,300})"', text) + re.findall(r"'([^'\\\n]{6,300})'", text)
    seen, out = set(), []
    for s in strs:
        if s not in seen:
            seen.add(s)
            out.append(s)
    return "\n".join(out[:top])
