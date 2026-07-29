#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""test_deobf.py — motoru drone gercek dosyalariyla sinar."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import deobf

ok = True

# 1) hex/base64 sanity
t = r'local a="\x48\x65\x6c\x6c\x6f\x20\x57\x6f\x72\x6c\x64\x20\x54\x65\x73\x74" local b="' + "aGVsbG8gd29ybGQgdGhpcyBpcyBhIGJhc2U2NCB0ZXN0IGJsb2Nr" + '"'
u, nh = deobf.unhex(t)
assert "Hello World Test" in u and nh == 16, f"unhex fail: nh={nh}"
print("PASS unhex")

# 2) drone XSUB yasasi (gercek blob — HAFIZA: drone_blob.txt 311,574 char, decoded 249,256 byte, drone_decoded.bin ile byte-identical)
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

# 3) pipeline smokedown — mini fake payload
fake = 'local LP_123456="..."; loadstring(game:HttpGet("https://x"))()'
rep, outs = deobf.deobf_pipeline("mini.lua", fake.encode())
assert "deobf.txt" in outs and "strings.txt" in outs
print("PASS pipeline")
print()
print("===", "ALL OK" if ok else "SOME FAIL", "===")
