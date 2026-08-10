#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""deobf.py — Deobf Bot motoru (v2.1 sertleştirilmiş).

Değişiklikler:
  * fetch/smart_fetch artık security.safe_fetch üzerinden SSRF korumalı.
  * Runtime (Lua) yürütme DEOBF_RUNTIME=1 ile gate'li (varsayılan kapalı).
  * recursive_deobf'un base64 çözücüsü daha az agresif (false-positive azaldı).
"""
import re
import io
import base64
import logging
from typing import Dict, Optional, Tuple

import security

logger = logging.getLogger("Deobf.Engine")
UA = security.UA


# ---------- GÜVENLİ getiriciler (security.SafeFetcher'e delege) ----------
def is_safe_url(url: str) -> bool:
    ok, _ = security.validate_url(url)
    return ok


def fetch(url: str, timeout: int = 25) -> bytes:
    """SSRF korumalı GET -> bytes."""
    data, _ = security.safe_fetch(url, timeout=timeout)
    return data


def smart_fetch(url: str, timeout: int = 25) -> Tuple[bytes, str]:
    """Akıllı GET: önce raw'a normalize eder, sonra güvenli getirir."""
    u2 = normalize_raw_url(url)
    referer = "/".join(u2.split("/")[:3]) + "/"
    return security.safe_fetch(u2, timeout=timeout, referer=referer)


def normalize_raw_url(u: str) -> str:
    u = u.strip().strip("<>")
    RAW_HOST_FIX = [
        (re.compile(r"https?://pastebin\.com/(?!raw/)(\w+)"), r"https://pastebin.com/raw/\1"),
        (re.compile(r"https?://paste\.c-net\.org/(?!raw/)(\w+)"), r"https://paste.c-net.org/raw/\1"),
        (re.compile(r"https?://gist\.github\.com/([\w-]+)/([0-9a-f]{8,})"),
         r"https://gist.githubusercontent.com/\1/\2/raw"),
        (re.compile(r"https?://github\.com/([\w.-]+)/([\w.-]+)/blob/([^/]+)/(.+)"),
         r"https://raw.githubusercontent.com/\1/\2/\3/\4"),
    ]
    for rx, rep in RAW_HOST_FIX:
        if rx.search(u):
            return rx.sub(rep, u)
    return u


# ---------- katmanlı çözücü (Core) ----------
def unhex(text: str) -> Tuple[str, int]:
    """Hex (\\xHH) ve ondalık (\\NNN) escape'leri çözer -> (metin, çözülen sayı).

    test_deobf.py ve eski arayanlar için açık API.
    """
    n = 0

    def _rep_hex(m):
        nonlocal n
        try:
            val = int(m.group(1), 16)
            if 0 <= val <= 255:
                n += 1
                return chr(val)
        except Exception:  # noqa: BLE001
            pass
        return m.group(0)

    def _rep_dec(m):
        nonlocal n
        try:
            val = int(m.group(1))
            if 0 <= val <= 255:
                n += 1
                return chr(val)
        except Exception:  # noqa: BLE001
            pass
        return m.group(0)

    out = re.sub(r"\\x([0-9a-fA-F]{2})", _rep_hex, text)
    out = re.sub(r"\\([0-9]{3})", _rep_dec, out)
    return out, n


def recursive_deobf(text: str, max_depth: int = 5) -> Tuple[str, int]:
    """Kodun içindeki katmanları (hex, b64, escape) derinlemesine çözer.

    Sıkılaştırma: base64 yalnızca açıkça yürütülebilir LUA içeriğine işaret
    ediyorsa (loadstring + game/function birlikte) çözülür; tek başına 'game'
    geçiyor diye meşru kod bozulmaz.
    """
    total_changes = 0
    current_text = text

    for _ in range(max_depth):
        changed = False

        # 1) hex / ondalık escape çözücü
        for pat in (r"\\x([0-9a-fA-F]{2})", r"\\([0-9]{3})"):
            matches = re.findall(pat, current_text)
            if len(matches) >= 5:
                def rep(m, _pat=pat):
                    try:
                        val = int(m.group(1), 16) if "x" in _pat else int(m.group(1))
                        return chr(val) if (32 <= val <= 126 or val in (9, 10, 13)) else m.group(0)
                    except Exception:  # noqa: BLE001
                        return m.group(0)
                new_text = re.sub(pat, rep, current_text)
                if new_text != current_text:
                    current_text = new_text
                    changed = True
                    total_changes += len(matches)

        # 2) base64 blok çözücü (sıkılaştırılmış koşul)
        b64_pat = r'["\']([A-Za-z0-9+/]{60,}={0,2})["\']'
        for match in re.findall(b64_pat, current_text):
            try:
                decoded = base64.b64decode(match, validate=True).decode("utf-8", "replace")
            except Exception:  # noqa: BLE001
                continue
            low = decoded.lower()
            # yalnızca gerçek Lua yürütme içeriği varsa değiştir
            if ("loadstring" in low and ("game" in low or "function" in low)) \
                    or ("fireserver" in low and "remotes" in low):
                current_text = current_text.replace(match, decoded)
                changed = True
                total_changes += 1

        if not changed:
            break

    return current_text, total_changes


# ---------- WRD çözücü ----------
def _lua_quote(value: str) -> str:
    """Çözülen değeri güvenli, yeniden okunabilir Lua stringine dönüştürür."""
    return '"' + value.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n') + '"'


def _lua_unescape(value: str) -> str:
    """WRD tablolarındaki Lua decimal/hex ve basit escape dizilerini çözer."""
    return _unescape_lua(value)


def _find_lua_table(text: str):
    """`local X = { ... }` tablosunu dengeli parantezlerle çıkarır; regex'e bağlı kalmaz."""
    match = re.search(r"\blocal\s+([A-Za-z_]\w*)\s*=\s*\{", text)
    if not match:
        return None
    depth, quote, escaped = 0, None, False
    start = text.find("{", match.start())
    for pos in range(start, len(text)):
        ch = text[pos]
        if quote:
            if escaped:
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == quote:
                quote = None
            continue
        if ch in ("'", '"'):
            quote = ch
        elif ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return match.group(1), text[start + 1:pos]
    return None


def _parse_lua_strings(table_body: str):
    """Tablodaki tek/çift tırnaklı string sabitleri kaynak sırasıyla okur."""
    values = []
    pattern = re.compile(r"(['\"])((?:\\.|(?!\1).)*)\1", re.S)
    for match in pattern.finditer(table_body):
        values.append(_lua_unescape(match.group(2)))
    return values


def wrd_full_deobf(text: str) -> Tuple[str, Dict]:
    """WRD string tablolarını ve sabit indeks çağrılarını statik olarak açar.

    Kod yürütmez. Bilinmeyen dinamik indeksleri olduğu gibi bırakır; böylece
    yanlış plaintext üretmek yerine okunabilir ve güvenli bir ara çıktı verir.
    """
    info = {"engine": "WRD-Static-Advanced", "replacements": 0}
    if "wearedevs.net/obfuscator" not in text:
        return text, {}

    table = _find_lua_table(text)
    if not table:
        return text, {"engine": info["engine"], "error": "string table not found"}
    table_name, table_body = table
    decoded_strings = _parse_lua_strings(table_body)
    info["table"] = table_name
    info["strings_found"] = len(decoded_strings)
    if not decoded_strings:
        return text, {"engine": info["engine"], "error": "string table empty"}

    # Doğrudan tablo erişimleri: U[12], U [ 12 ]
    def replace_table_index(match):
        idx = int(match.group(1))
        if 1 <= idx <= len(decoded_strings):
            info["replacements"] += 1
            return _lua_quote(decoded_strings[idx - 1])
        return match.group(0)

    text = re.sub(rf"\b{re.escape(table_name)}\s*\[\s*(\d+)\s*\]", replace_table_index, text)

    # WRD'nin yaygın accessor biçimleri: local F=function(i)return U[i]end
    accessor_pattern = re.compile(
        rf"\blocal\s+([A-Za-z_]\w*)\s*=\s*function\s*\(\s*([A-Za-z_]\w*)\s*\)\s*"
        rf"return\s+{re.escape(table_name)}\s*\[\s*\2\s*\]\s*end"
    )
    accessors = [m.group(1) for m in accessor_pattern.finditer(text)]
    for accessor in accessors:
        pattern = re.compile(rf"\b{re.escape(accessor)}\s*\(\s*(\d+)\s*\)")
        text = pattern.sub(replace_table_index, text)
    info["accessors_found"] = len(accessors)

    final_code, changes = recursive_deobf(text)
    info["recursive_changes"] = changes
    return final_code, info


# ---------- ANA PİPELİNE ----------
def deobf_pipeline(name: str, content: bytes):
    text = content.decode("utf-8", "replace")
    outputs = {}
    report = ["# DEOBF ANALİZ RAPORU v2.1"]

    if "wearedevs.net/obfuscator" in text:
        text, winfo = wrd_full_deobf(text)
        report.append(f"- WRD Tespiti: {winfo.get('strings_found', 0)} sabit çözüldü.")

    # Güvenilmeyen Lua yürütmesi kaldırıldı; yalnızca statik analiz yapılır.
    report.append("- Dinamik Analiz: güvenlik nedeniyle devre dışı; yalnızca statik analiz yapıldı.")

    text, changes = recursive_deobf(text)
    if changes > 0:
        report.append(f"- Katmanlı Çözücü: {changes} adet gizli veri plaintext yapıldı.")

    import prettifier
    try:
        text = prettifier.prettify_lua(text)
        report.append("- Görselleştirme: Kod okunabilirliği için yeniden formatlandı.")
    except Exception:  # noqa: BLE001
        pass

    data, _xinfo = extract_xsub(text)
    if data:
        outputs["payload.bin"] = data
        report.append(f"- XSUB Payload: {len(data)} byte ayıklandı.")

    outputs["deobf.txt"] = text.encode()
    outputs["strings.txt"] = dump_strings(text).encode()
    return "\n".join(report), outputs


# ---------- yardımcılar ----------
def find_megastring(text: str) -> Optional[str]:
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
                while i < n and s[i] in " \t\r\n":
                    i += 1
                continue
            if nxt == "x" and i + 3 < n:
                try:
                    out.write(bytes([int(s[i + 2:i + 4], 16)]).decode("latin-1")); i += 4; continue
                except Exception:  # noqa: BLE001
                    pass
            m = re.match(r"\\(\d{1,3})", s[i:])
            if m:
                v = int(m.group(1))
                if v <= 255:
                    out.write(bytes([v]).decode("latin-1")); i += 1 + len(m.group(1)); continue
            simple = {"n": "\n", "r": "\r", "t": "\t", "\\": "\\", '"': '"',
                      "a": "\a", "b": "\b", "f": "\f", "v": "\v"}
            if nxt in simple:
                out.write(simple[nxt]); i += 2; continue
            out.write(nxt); i += 2; continue
        out.write(c); i += 1
    return out.getvalue()


def xsub_decode(blob: str) -> Optional[bytes]:
    raw = blob if not blob.startswith(("LPH+", "LPH-")) else blob[4:]
    raw = "".join(ch for ch in raw if 33 <= ord(ch) <= 126)
    raw = raw[: len(raw) - len(raw) % 5]
    if len(raw) < 100:
        return None
    out = bytearray()
    for i in range(0, len(raw), 5):
        v = 0
        for ch in raw[i:i + 5]:
            d = ord(ch) - 33
            if d > 84:
                d = 0
            v = (v * 85 + d) & 0xFFFFFFFF
        out += v.to_bytes(4, "big")
    return bytes(out)


def extract_xsub(text: str) -> Tuple[Optional[bytes], Dict]:
    info: dict = {}
    mega = find_megastring(text)
    if not mega:
        return None, info
    mega = _unescape_lua(mega)
    for mk in ("LPH+", "LPH-"):
        if mk in mega:
            idx = mega.index(mk)
            data = xsub_decode(mega[idx:])
            if data:
                return data, {"decoded": len(data)}
    return None, info


def dump_strings(text: str, top: int = 60) -> str:
    strs = re.findall(r'"([^"\\\n]{6,300})"', text) + re.findall(r"'([^'\\\n]{6,300})'", text)
    seen, out = set(), []
    for s in strs:
        if s not in seen:
            seen.add(s)
            out.append(s)
    return "\n".join(out[:top])
