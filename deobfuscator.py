import re, sys, subprocess, time, os, glob, math, tempfile, shutil, logging

logger = logging.getLogger("Deobf.Runtime")

def get_lua_executable():
    if os.name == "nt": return os.path.join("lua_bin", "lua5.1.exe")
    env_path = os.environ.get("LUA51_EXECUTABLE")
    if env_path: return env_path
    for candidate in ("lua5.1", "lua51", "lua"):
        path = shutil.which(candidate)
        if path: return path
    return "lua5.1"

def deobfuscate_runtime(content: str) -> str:
    """Scripti emüle ederek içindeki çözülmüş stringleri yakalar."""
    # Güvenli Mock Ortamı
    mock_env = r"""
-- GÜVENLİK: Tehlikeli fonksiyonları tamamen kapat
os, io, package, debug = nil, nil, nil, nil
dofile, loadfile = nil, nil

local _STRINGS = {}
local real_print = print
local real_type = type

-- Akıllı Yakalayıcı: loadstring ve benzeri çağrıları izle
local function capture(val)
    if real_type(val) == "string" and #val > 10 then
        table.insert(_STRINGS, val)
        real_print("--- CAPTURED_START ---")
        real_print(val)
        real_print("--- CAPTURED_END ---")
    end
end

_G.loadstring = function(s) capture(s) return function() end end
_G.print = function(...) for _,v in ipairs({...}) do capture(tostring(v)) end end

-- Roblox API Mock
local function create_mock(name)
    local m = {}
    setmetatable(m, {
        __index = function(_, k) return create_mock(name .. "." .. k) end,
        __call = function(_, ...) return create_mock(name .. "_res") end,
        __tostring = function() return name end
    })
    return m
end

game = create_mock("game")
workspace = create_mock("workspace")
script = create_mock("script")
shared = {}
getgenv = function() return _G end

-- Hedef Script Buraya Gelecek
"""
    
    # Scripti mock ortamıyla birleştir
    full_code = mock_env + "\n-- TARGET SCRIPT --\n" + content
    
    with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", suffix=".lua", delete=False) as f:
        f.write(full_code)
        temp_path = f.name

    try:
        # Kısıtlı sürede çalıştır (sonsuz döngü koruması)
        proc = subprocess.run([get_lua_executable(), temp_path], 
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE, 
                            timeout=10, text=True, errors="replace")
        
        # Yakalanan stringleri ayıkla
        captured = re.findall(r"--- CAPTURED_START ---\n(.*?)\n--- CAPTURED_END ---", proc.stdout, re.S)
        if captured:
            return "\n\n-- [DİNAMİK ÇÖZÜLEN KATMANLAR] --\n\n" + "\n\n".join(captured)
    except Exception as e:
        logger.error(f"Runtime deobf hatası: {e}")
    finally:
        if os.path.exists(temp_path): os.remove(temp_path)
    
    return ""

def process_full(content: str) -> str:
    """Statik ve dinamik analizi birleştirir."""
    # 1. Statik Temizlik (Basit)
    content = re.sub(r"--\[\[.*?\]\]", "", content, flags=re.S) # Blok yorumlar
    
    # 2. Dinamik Emülasyon
    runtime_result = deobfuscate_runtime(content)
    
    return content + runtime_result
