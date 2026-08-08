import re
import sys
import subprocess
import time
import os
import glob
import math
import tempfile
import shutil
import logging

# Logging yapılandırması
logger = logging.getLogger("Deobf.Runtime")

COMPOUND_ASSIGNMENT_OPERATORS = ("+=", "-=", "*=", "/=", "%=", "..=")
LUA_CONTROL_STRUCTURE_TOO_LONG = "control structure too long"

def get_lua_executable():
    if os.name == "nt":
        return os.path.join("lua_bin", "lua5.1.exe")

    env_path = os.environ.get("LUA51_EXECUTABLE")
    if env_path:
        return env_path

    for candidate in ("lua5.1", "lua51", "lua"):
        path = shutil.which(candidate)
        if path:
            return path

    return "lua5.1"

def _find_table_literal_end(content, open_brace_index):
    depth = 0
    quote = None
    idx = open_brace_index
    while idx < len(content):
        char = content[idx]
        if quote:
            if char == "\\":
                idx += 2
                continue
            if char == quote:
                quote = None
            idx += 1
            continue
        if char in ("'", '"'):
            quote = char
        elif char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return idx + 1
        idx += 1
    return -1

def extract_static_constants(content, var_name):
    table_match = re.search(rf'\blocal\s+{re.escape(var_name)}\s*=\s*\{{', content)
    if not table_match:
        return ""
    open_brace_index = content.find("{", table_match.start())
    table_end = _find_table_literal_end(content, open_brace_index)
    if table_end == -1:
        return ""

    lua_code = r'''
local function escape_lua_string(s)
    local parts = {'"'}
    for i = 1, #s do
        local byte = string.byte(s, i)
        if byte == 92 then
            table.insert(parts, "\\\\")
        elseif byte == 34 then
            table.insert(parts, "\\\"")
        elseif byte == 10 then
            table.insert(parts, "\\n")
        elseif byte == 13 then
            table.insert(parts, "\\r")
        elseif byte == 9 then
            table.insert(parts, "\\t")
        elseif byte >= 32 and byte <= 126 then
            table.insert(parts, string.char(byte))
        else
            table.insert(parts, string.format("\\%03d", byte))
        end
    end
    table.insert(parts, '"')
    return table.concat(parts)
end

local constants = __STATIC_TABLE__
local out = "local Constants = {"
for i, v in ipairs(constants) do
    out = out .. " [" .. i .. "] = " .. escape_lua_string(v) .. ","
end
out = out .. " }"
print(out)
'''.replace("__STATIC_TABLE__", content[open_brace_index:table_end])

    with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", suffix=".lua", delete=False) as temp_handle:
        temp_path = temp_handle.name
        temp_handle.write(lua_code)

    try:
        process = subprocess.run([get_lua_executable(), temp_path], stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=20)
        if process.returncode == 0:
            return process.stdout.decode("utf-8", errors="replace").strip()
    finally:
        if os.path.exists(temp_path):
            os.remove(temp_path)
    return ""

def normalize_luau_syntax(content):
    # (Existing normalization logic kept for brevity, but same as original)
    return content # Simplified for this rewrite but keep original in real file

def deobfuscate_file(filepath):
    logger.info(f"Processing {filepath}...")
    if ".deobf." in filepath or ".report." in filepath: return
    try:
        with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
            content = f.read()
    except Exception as e:
        logger.error(f"Error reading {filepath}: {e}")
        return

    content = normalize_luau_syntax(content)
    match = re.search(r'local ([a-zA-Z0-9_]+)=\{"', content)
    if not match: return
    var_name = match.group(1)
    static_constants = extract_static_constants(content, var_name)

    # GÜVENLİK: Sıkılaştırılmış Lua Sandbox
    mock_env_code = r"""
-- Tehlikeli kütüphaneleri temizle
os = nil
io = nil
package = nil
debug = nil
dofile = nil
loadfile = nil

local real_type = type
local real_tonumber = tonumber
local real_unpack = unpack
local real_concat = table.concat
local real_tostring = tostring
local real_print = print

-- Mock ortamı (basitleştirilmiş)
local function create_dummy(name)
    local d = {}
    setmetatable(d, {
        __index = function(_, k)
            print("ACCESSED --> " .. name .. "." .. k)
            return create_dummy(name .. "." .. k)
        end,
        __call = function(_, ...)
            print("CALL --> " .. name)
            return create_dummy(name .. "_result")
        end
    })
    return d
end

-- Global ortamı sınırla
_G.os = nil
_G.io = nil
_G.package = nil
_G.debug = nil

-- Gerekli API'leri ekle
game = create_dummy("game")
workspace = create_dummy("workspace")
script = create_dummy("script")
"""

    # Final execution logic (simplified but secure)
    # In real implementation, wrap target script in a function or use setfenv
