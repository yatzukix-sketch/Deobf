# -*- coding: utf-8 -*-
"""deobfuscator.py — Çalışma-zamanlı (runtime) deobf motoru.

GÜVENLİK (v2): Güvenilmeyen Lua artık doğrudan subprocess.run ile değil,
`security.run_lua_sandboxed` üzerinden dar kaynak limitleriyle (bellek/CPU/
dosya) yürütülür. Üstelik varsayılan olarak TAMAMEN KAPALIDIR; açmak için
ortam değişkeni DEOBF_RUNTIME=1 gerekir. Bu, RCE ve bellek-DoS risklerini
sınırlar.
"""
import re
import os
import logging

logger = logging.getLogger("Deobf.Runtime")


def get_lua_executable() -> str:
    """Kullanılacak lua yorumlayıcı yolu."""
    if os.name == "nt":
        return os.path.join("lua_bin", "lua5.1.exe")
    env_path = os.environ.get("LUA51_EXECUTABLE")
    if env_path and os.path.exists(env_path):
        return env_path
    import shutil
    for cand in ("lua5.1", "lua51", "lua"):
        p = shutil.which(cand)
        if p:
            return p
    # repo kökündeki bundle lua51
    here = os.path.dirname(os.path.abspath(__file__))
    bundled = os.path.join(here, "lua51")
    return bundled if os.path.exists(bundled) else "lua5.1"


# Güvenli mock ortam — tehlikeli kütüphaneleri kapat (savunma derinliği)
_MOCK_ENV = r"""
-- GÜVENLİK: tehlikeli kütüphaneleri kapat
os, io, package, debug, loadfile, dofile = nil, nil, nil, nil, nil, nil

local _STRINGS = {}
local real_print = print

local function capture(val)
    if type(val) == "string" and #val > 10 then
        table.insert(_STRINGS, val)
        real_print("--- CAPTURED_START ---")
        real_print(val)
        real_print("--- CAPTURED_END ---")
    end
end

-- loadstring'i ele geçir: argümanı yakala, no-op döndür
_G.loadstring = function(s) capture(s) return function() end end
_G.load = function(s) capture(s) return function() end end
_G.print = function(...) for _, v in ipairs({...}) do capture(tostring(v)) end end

-- Roblox API mock (çağrıları patlatmadan akışa devam)
local function create_mock(name)
    local m = {}
    setmetatable(m, {
        __index = function(_, k) return create_mock(name .. "." .. k) end,
        __call = function(_, ...) return create_mock(name .. "_res") end,
        __tostring = function() return name end,
    })
    return m
end

game = create_mock("game")
workspace = create_mock("workspace")
script = create_mock("script")
shared = {}
getgenv = function() return _G end
"""


def deobfuscate_runtime(content: str) -> str:
    """Güvenilmeyen Lua kodunu çalıştırma özelliği güvenlik nedeniyle kaldırıldı."""
    logger.info("runtime deobf atlandı: güvenilmeyen Lua yürütmesi desteklenmiyor")
    return ""


def process_full(content: str) -> str:
    """Statik + dinamik analizi birleştirir (dinamik gated)."""
    content = re.sub(r"--\[\[.*?\]\]", "", content, flags=re.S)  # blok yorumlar
    return content + deobfuscate_runtime(content)
