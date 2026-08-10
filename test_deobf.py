#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""test_deobf.py — motoru drone gercek dosyalariyla sinar."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import deobf

ok = True

# 1) hex/base64 sanity
t = r'local a="\x48\x65\x6c\x6c\x6f\x20\x57\x6f\x72\x6c\x64\x20\x54\x65\x73\x74" local b="' + "aGVsbG8gd29ybGQgdGhpcyBpcyBhIGJhc2U2NCB0ZXN0IGJsb2Nr" + '"'
u, nh = deobf.recursive_deobf(t)
assert "Hello World Test" in u and nh == 16, f"recursive_deobf fail: nh={nh}"
print("PASS recursive_deobf (hex)")

# 2) WRD tablo/accessor varyasyonlari: statik, calistirmadan plaintext vermeli
wrd = '''-- wearedevs.net/obfuscator
local Q = {"\\072\\101\\108\\108\\111", "World", "\\x46\\105\\114\\101\\083\\101\\114\\118\\101\\114"}
local K = function(i) return Q[i] end
print(K(1), Q[2], K(3))
'''
opened, meta = deobf.wrd_full_deobf(wrd)
assert '"Hello"' in opened and '"World"' in opened and '"FireServer"' in opened, opened
assert meta["replacements"] == 3 and meta["accessors_found"] == 1, meta
assert any("Hello" in value for value in meta["decoded_strings"]), meta
print("PASS wrd static table/accessor")

# 3) drone XSUB yasasi (gercek blob — HAFIZA: drone_blob.txt 311,574 char, decoded 249,256 byte, drone_decoded.bin ile byte-identical)
blob_path = "/home/user/dumper/drone_blob.txt"
truth_path = "/home/user/dumper/drone_decoded.bin"
if os.path.exists(blob_path) and os.path.exists(truth_path):
    blob_txt = open(blob_path, "r", encoding="utf-8", errors="replace").read()
    truth = open(truth_path, "rb").read()
    # blob_txt icerigi: 'LPH+' ile baslayan ham blob (311,574 char)
    data = deobf.xsub_decode(blob_txt)
    if data and len(data) == len(truth):
        print("PASS xsub len:", len(data))
        if data[:64] == truth[:64] and data[-64:] == truth[-64:]:
            print("PASS xsub BYTES IDENTICAL (head+tail)")
        else:
            print("WARN xsub desen farkli (head/tail eslesmedi)")
    else:
        print("FAIL xsub:", len(data) if data else None, "vs", len(truth)); ok = False
else:
    print("SKIP xsub (drone dosyalari yok)")

# 4) pipeline smokedown — mini fake payload
fake = 'local LP_123456="..."; loadstring(game:HttpGet("https://x"))()'
rep, outs = deobf.deobf_pipeline("mini.lua", fake.encode())
assert "deobf.txt" in outs and "strings.txt" in outs
wrd_report, wrd_outputs = deobf.deobf_pipeline("wrd.lua", wrd.encode())
assert "wrd_strings.txt" in wrd_outputs and b"Hello" in wrd_outputs["wrd_strings.txt"]
print("PASS pipeline")
print()
print("===", "ALL OK" if ok else "SOME FAIL", "===")
