# -*- coding: utf-8 -*-
"""prettifier.py — Lua kodu için temel girintileyici (v2 düzeltildi).

v1'de parantez içeren her satırı şişiriyordu (işlemci önceliği hatası).
v2: gerçek parantez/kaşlıayraç derinliğini takip eder, blokları doğru girintiler.
"""
import re


def _effective_indent_delta(line: str) -> int:
    """Bir satırın girinti seviyesine katkısı: +1 (blok aç), -1 (blok kapat), 0."""
    # açılan ve kapanan blok anahtar kelimelerini say (yorum/string dışı basit tahmin)
    s = line.strip()
    if not s or s.startswith("--"):
        return 0
    opens = len(re.findall(r"\b(?:then|do|function|repeat)\b", s))
    opens += s.count("{") - s.count("}")
    closes = 0
    for kw in ("end", "until", "}", "else", "elseif"):
        closes += len(re.findall(r"\b" + kw + r"\b" if kw[0].isalpha() else re.escape(kw), s))
    delta = opens - closes
    # satır blok kapatıcı bir kelimeyle başlıyorsa girintiyi azalt
    starts_close = bool(re.match(r"^\s*(?:end|until|else|elseif|\})", s))
    return delta, starts_close


def prettify_lua(code: str) -> str:
    """Lua kodunu girintiler. Parantez derinliğini takip ederek şişirmeyi önler."""
    lines = code.splitlines()
    out = []
    indent = 0
    paren_depth = 0  # açılmamış ( ... devamı: girintiyi değiştirme

    for raw in lines:
        stripped = raw.strip()
        if not stripped:
            out.append("")
            continue

        delta, starts_close = _effective_indent_delta(stripped)
        # önce kapanışla girintiyi azalt
        if starts_close:
            indent = max(0, indent - 1)

        out.append("    " * indent + stripped)

        # blok artışı (parantez derinliği içinde değilse)
        if delta > 0 and paren_depth == 0:
            indent += 1
        elif delta < 0:
            indent = max(0, indent + delta)  # fazladan kapanışları telafi

        # parantez derinliği güncelle (açık çağrıların girintiyi şişirmesini engelle)
        paren_depth += raw.count("(") - raw.count(")")
        paren_depth = max(0, paren_depth)

    return "\n".join(out)
