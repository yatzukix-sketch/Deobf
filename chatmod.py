# -*- coding: utf-8 -*-
"""SENSEI-SOHBET v1.0 — .aly analizi uzerine soru-cevap motoru (kural tabanli, LLM degil).
cevap(soru, ctx) -> str | None
ctx = {"R": analyze() sozlugu|None, "name": str, "kaynak": str, "ek": str}
None donerse = anlamadim, bot uzerinden bakabilir.
"""
import re

VERS = "1.0"

OZELLIK_ESLESME = [
    (r"hitbox", "hitbox"),
    (r"noclip|duvardan", "noclip"),
    (r"\bfly\b|u[cç]mak|u[cç]abiliyor", "ucma"),
    (r"h[ıi]z|speed", "hiz"),
    (r"aim|ni[sş]an", "aimbot"),
    (r"\besp\b|wallhack|chams", "esp"),
    (r"key|anahtar", "key"),
    (r"admin", "admin"),
    (r"fps", "fps"),
    (r"farm|oto ?geli[sş]tirme|otomatik", "farm"),
    (r"pet|yumurta", "pet"),
]


def _kanitli_kontrol(ctx, anahtar_kel):
    """amac_kesin / amac_gecen icinden ilgili amaci bul"""
    R = ctx.get("R") or {}
    for etiket, kanitlar in R.get("amac_kesin", []):
        if re.search(anahtar_kel, etiket, re.I):
            sn = "; ".join(f"`{t}: {s}`" for t, s in kanitlar)
            return f"✅ **KANITLI!** {etiket}\nKanit: {sn}"
    for etiket, adet in R.get("amac_gecen", []):
        if re.search(anahtar_kel, etiket, re.I):
            return (f"🔎 Sadece adi geciyor ({adet}x). {etiket.split(' ')[0]} — calisan "
                    "kod kaniti bulamadim, kesin 'var' diyemem (buton/etiket olabilir).")
    return None


def _ara_kaynaginda(kel, ctx):
    """kaynak+cozulmus havuzda kelime gecen ilk 2 satir + adet (yorumlar isaretlenir)"""
    havuz = (ctx.get("kaynak", "") + "\n" + ctx.get("ek", "")).splitlines()
    rxp = re.compile(kel, re.I)
    uygun = [L.strip() for L in havuz if rxp.search(L) and L.strip()]
    if not uygun:
        return None
    fatihin = []
    for u in uygun[:2]:
        sn = re.sub(r"\s+", " ", u)[:80]
        if u.startswith("--"):
            sn += "  ⬅️ (YORUM satiri, icra degil!)"
        fatihin.append(sn)
    return len(uygun), fatihin


def cevap(soru: str, ctx: dict) -> str:
    q = soru.lower().strip(" ?!.")
    R = ctx.get("R")
    name = ctx.get("name", "bu script")

    # ---- medeni hal: selamlasma / kimlik / tesekkur ----
    if re.fullmatch(r"(selam|slm|sa|merhaba|mrb|hey|naber|nasilsin|iyi misin)[!. ]*", q):
        return ("Selam cirak! Ben Sensei. 🥋 Soruyu sor da baslayalim: "
                "`güvenli mi?`, `ne yapıyor?`, `hitbox var mı?` gibi...")
    if re.search(r"kimsin|sen ne|ad[ıi]n ne|ozelliklerin|ne yapabiliyor", q):
        return ("Ben Sensei'nin analiz kadrosundaki sohbet birimiyim 🤖 "
                ".aly analizini okuyup derinleştiriyorum — remote, url, amac, risk... "
                "Gucum kural tabanli (robot degil, NATO hafiyesi degil 😄). "
                "Surekli analiz icin `.sohbet` ac, soru-cevap icin `.sor <soru>`.")
    if re.search(r"te[sş]ekk|sa[ğg]ol|eyvallah|tesekkur", q):
        return "Rica ederim cirak. KISKANMA: kanıtsız scripte asla guvenme. ⚔️"

    if not R:
        return ("Bu kanalda henuz .aly analizi yok; once `.aly <url/dosya>` calistir, "
                "sonra bana danis. (Genel sorular `selam`, `kimsin` vs.)")

    band_lbl, _, tavsiye = __import__("analyzer").BAND_BILGI[R["band"]]

    # ---- guvenlik karari ----
    if re.search(r"g[üu]venli|safe|vir[üu]s|rat|trojan|ban|kork|kullanay[ıi]m|[cç]al[ıi][sş]t[ıi]ray[ıi]m|zarar|risk", q):
        n_kesin = len(R["amac_kesin"])
        ust = R["bulgular"][:3]
        satirlar = [f"`+{p}` {a}" for p, _k, a, _kt in ust]
        extra = ""
        if "obfuscator" in R["tur"].lower() or "LuaProt" in R["tur"]:
            extra = ("\n⚠️ Tur obf'lu; cozemedigimiz kisim olabilir — temiz dese bile "
                     "garanti yok, main hesapta deneme!")
        return (f"{band_lbl} (skor **%{R['skor']}**)\n_{tavsiye}_\n"
                + ("\nEn agir sinyaller:\n" + "\n".join(satirlar) if satirlar else
                   "\nAgir bir sinyal gormedim (ama bak kanit ≠ garanti).")
                + (f"\nKanıtlı özellik: {n_kesin} adet — `ne yapıyor?` diye sor." if n_kesin else "")
                + extra)

    # ---- tirnak icinde isim verildiyse: dogrudan kaynaginda ara ----
    tirnak = re.search(r'["\']([\w .\-]{3,40})["\']', soru)
    if tirnak:
        k = tirnak.group(1)
        bulgu = _ara_kaynaginda(re.escape(k), ctx)
        if bulgu:
            n, sat = bulgu
            return (f"🔍 `{k}` için tam metin taramasi: **{n} satirda** geciyor. Ornekler:\n"
                    + "\n".join(f"`{s}`" for s in sat))
        return f"🕵️ `{k}` icin metinde hic iz yok (ismini yanlis yazmis olabilirsin)."

    # ---- remote'lar (amac sorusundan ONCE: "remoteler ne yapıyor?" buraya dusmeli) ----
    if re.search(r"remote|uzaktan|fireserver|invoke|ne gonderiyor|sunucuya ne", q):
        if not R["uzaklar"]:
            satir = "Remote izi yok (WaitForChild/FindFirstChild/Remotes/arg taramasi)"
        else:
            satir = "\n".join(
                f"`{u['isim']}` ×{u['adet']}" + (f" — {u['ipucu']}" if u["ipucu"] else "")
                for u in R["uzaklar"][:8])
        f, iv = R["fires"], R["invs"]
        return f"📡 **Remote envanteri:**\n{satir}\nFireServer ×{f} | InvokeServer ×{iv}"[:900]

    # ---- url / webhook ----
    if re.search(r"url|link|webhook|site|http|discord", q):
        if not R["urller"]:
            return "🌐 Dis iletisim: hic url bulunamadi (temiz isaret) ✅"
        return "🌐 **Bulunan url'ler:**\n" + "\n".join(R["urller"][:8]) + \
               "\n🚨 = webhook suphesi, ⚠️ = sifresiz http"

    # ---- obfuscator ----
    if re.search(r"obfus|[sş]ifre|katman|koruma|luaprot|wrd|hangi", q):
        parts = [f"🏷️ tur: **`{R['tur']}`**"]
        ozet = ", ".join(a for _p, k, a, _kt in R["bulgular"] if k == "OBF") or "belirgin iz yok"
        parts.append(f"📦 obf sinyalleri: {ozet}")
        parts.append("Sifreyi kırmak icin: `.l <aynı link>` — tam pipeline.")
        return "\n".join(parts)

    # ---- amac / ne yapiyor ----
    if re.search(r"ne yap[ıi]yor|amac[ıi]|i[sş]lev|[öo]zellik|ne i[sş]e|icinde ne var|mantig", q):
        uk = []
        for e, kt in R["amac_kesin"]:
            uk.append(f"### {e}")
            uk += [f"  → kanit `{t}: {s}`" for t, s in kt]
        gcn = [f"{e} (sadece adi geciyor x{n}, kanit yok)" for e, n in R["amac_gecen"]]
        ust = "Tespit yok (belki de duz/stub script)." if not (uk or gcn) else ""
        metin = "\n".join(uk[:8] + (["\n🔎 " + g for g in gcn[:4]] if gcn else []))
        return (f"🎯 **{name} — ne yapıyor?**\n{metin}\n{ust or '—'}"
                "(-- ben kanita baglarim, 'sallamam' 😄)")[:900]

    # ---- ozellik sorusu (hitbox var mi?) ----
    for rx, anahtar in OZELLIK_ESLESME:
        if re.search(rx, q):
            got = _kanitli_kontrol(ctx, anahtar)
            if got:
                return got
            bulgu = _ara_kaynaginda(rx, ctx)
            if bulgu:
                n, sat = bulgu
                return (f"Hiç amac tespitimde bu kelime kanitli/konusulmamis ama metinde "
                        f"{n} satirda geciyor, ilk ornekler:\n" +
                        "\n".join(f"`{s}`" for s in sat) +
                        "\n(Detay istersen .l ile tam deobf yap)")
            return (f"{name} icinde '{q.split()[0]}' dair ne kanit ne de isaret buldum. "
                    "Garanti demiyorum ama beni gecemediysen temiz sayilirsin 😄")

    # ---- servisler ----
    if re.search(r"servis|service", q):
        s = ", ".join(R["servisler"]) or "tespit yok"
        return f"⚙️ GetService kullanimi: {s}"

    # ---- boyut ----
    if re.search(r"ka[cç] sat[ıi]r|boyut|kilo|meter", q):
        return (f"📏 {name}: **{R['satir']} satir**, tur `{R['tur']}`. "
                f"Kucuk boy kotu huy demek degil, buyuk boy da temiz demek degil 😄")

    # ---- neden bu skor ----
    if re.search(r"neden|niye|nas[ıi]l karar|skor|band", q):
        ust = R["bulgular"][:4]
        sat = "\n".join(f"`+{p}` {a}" for p, _k, a, _kt in ust) or "sinyal yok"
        return (f"Skor **%{R['skor']}** (band {R['band']}/3). En agir sinyaller:\n{sat}\n"
                "Olcu: riskli desenler agirlikli, UI kutuphanesi gordukce skor duser. "
                "Tam analiz istersen `ne yapıyor?` diye sor.")

    # ---- kesin analiz sorusu degilse: kaynaginda ara ----
    kel = re.search(r"['\"]([\w .\-]{3,40})['\"]", soru) or \
          re.search(r"\b([A-Za-z_][A-Za-z0-9_\.]{4,40})\b", soru)
    if kel:
        k = kel.group(1)
        bulgu = _ara_kaynaginda(re.escape(k), ctx)
        if bulgu:
            n, sat = bulgu
            return (f"🔍 `{k}` için kaynak taramasi: **{n} satirda** geciyor. Ornekler:\n"
                    + "\n".join(f"`{s}`" for s in sat))

    # ---- hicbiri: ozet + yonlendir ----
    return ("Hmm, bunu tam yakalayamadim 🥴 Su sorulardan dene:\n"
            "• `güvenli mi?` • `ne yapıyor?` • `hitbox var mı?` • `fly var mı?`\n"
            "• `remote'lar ne yapıyor?` • `webhook var mı?` • `hangi obfuscator?`\n"
            "Ya da tirnak icinde bir isim ver: `\"ParryEvent\" ne?`")
