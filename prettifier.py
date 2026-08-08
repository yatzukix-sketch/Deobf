import re

def prettify_lua(code: str) -> str:
    """Lua kodunu temel düzeyde girintilerle güzelleştirir."""
    lines = code.splitlines()
    indent_level = 0
    new_lines = []
    
    # Blok başlatan ve bitiren anahtar kelimeler
    open_tokens = ["then", "do", "repeat", "{"]
    close_tokens = ["end", "until", "}", "else", "elseif"]
    
    for line in lines:
        line = line.strip()
        if not line: continue
        
        # Kapanış tokenları varsa girintiyi azalt (satırın başında kontrol et)
        first_word = line.split()[0] if line.split() else ""
        if any(line.startswith(t) for t in close_tokens) or line.startswith(")"):
            indent_level = max(0, indent_level - 1)
            
        # Girintiyi uygula
        new_lines.append("    " * indent_level + line)
        
        # Açılış tokenları varsa girintiyi artır
        # 'end' ile biten tek satırlık blokları atla
        if any(line.endswith(t) for t in open_tokens) or "(" in line and not ")" in line:
            indent_level += 1
            
        # Else/Elseif durumunda bir sonraki satır için girintiyi tekrar artır
        if first_word in ["else", "elseif"]:
            indent_level += 1
            
    return "\n".join(new_lines)
