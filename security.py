# -*- coding: utf-8 -*-
"""security.py — Deobf Bot güvenlik katmanı (çoklu savunma).

Kontrol 1: SSRF korumalı HTTP getirici (şema kısıtı + özel/meta IP engeli
           + DNS çoklu çözüm + yönlendirme takibi KAPALI + boyut limiti).
Kontrol 2: Kaynak limitli (bellek/CPU/dosya) sandbox yürütücüsü — Lua yalnızca
           DEOBF_RUNTIME=1 ile ve dar limitlerle çalışır.
Kontrol 3: Komut yetkilendirme + hız sınırı yardımcıları.

Bu modül stdlib dışında bağımlılık istemez; tüm bot buna bağımlıdır.
"""
import os
import re
import socket
import logging
import ipaddress
import http.client
import urllib.request
import urllib.parse
import resource
import subprocess
import tempfile
from typing import Dict, List, Optional, Tuple

logger = logging.getLogger("Deobf.Security")

# ---- genel sabitler ----
HTTP_TIMEOUT = 20
MAX_BYTES = 12 * 1024 * 1024            # tek seferde indirilebilecek tavan
ALLOWED_SCHEMES = ("http", "https")

# bulut metadata / özel uç noktalar (token çalmak için kullanılan klasik hedefler)
META_IPS = {
    "169.254.169.254",   # AWS / GCP / Azure / DigitalOcean IMDS
    "169.254.169.253",
    "fd00:ec2::254",     # AWS IMDSv6
    "100.100.100.200",   # AlibabaCloud
    "metadata.google.internal",
}
BLOCKED_HOSTS = {"localhost", "0.0.0.0", "::1", "ip6-localhost", "metadata.google.internal"}

UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36")


# ===========================================================================
# KONTROL 1 — SSRF korumalı getirici
# ===========================================================================
def _all_ips(host: str) -> List[str]:
    """Bir host için çözülen TÜM IP'leri döndürür (round-robin/rebinding savunması)."""
    try:
        infos = socket.getaddrinfo(host, None, type=socket.SOCK_STREAM)
        return list({sa[4][0] for sa in infos})
    except OSError:
        return []


def is_safe_ip(ip: str) -> bool:
    """IP özel/metadata ağındaysa False."""
    try:
        o = ipaddress.ip_address(ip)
    except ValueError:
        return False
    if (o.is_private or o.is_loopback or o.is_link_local or o.is_multicast
            or o.is_reserved or o.is_unspecified):
        return False
    if str(o) in META_IPS:
        return False
    return True


def validate_url(url: str) -> Tuple[bool, str]:
    """URL'yi güvenlik açısından denetler -> (geçerli mi, sebep/IP)."""
    if not url or len(url) > 2048:
        return False, "URL boş veya 2048 karakterden uzun"
    try:
        p = urllib.parse.urlparse(url)
    except Exception:
        return False, "URL parse edilemedi"
    if p.scheme not in ALLOWED_SCHEMES:
        return False, f"izin verilmeyen şema: {p.scheme!r}"
    host = (p.hostname or "").lower()
    if not host or host in BLOCKED_HOSTS:
        return False, f"yasaklı host: {host!r}"
    # host literal IP ise direkt kontrol, değilse çöz
    ips = _all_ips(host)
    if not ips:
        return False, "DNS çözülemedi"
    for ip in ips:
        if not is_safe_ip(ip) or ip in META_IPS:
            return False, f"özel/meta ağı engellendi: {ip}"
    return True, ips[0]


class _NoRedirect(urllib.request.HTTPRedirectHandler):
    """3xx yönlendirmelerini TAKİP ETME — SSRF için kritik."""

    def redirect_request(self, req, fp, code, msg, headers, newurl):  # noqa: D401
        return None


class _PinnedHTTPConnection(http.client.HTTPConnection):
    """DNS rebinding'i önlemek için soketi önceden denetlenmiş IP'ye bağlar."""

    def __init__(self, connect_ip: str, host_header: str, port: int, timeout: int):
        super().__init__(host_header, port, timeout=timeout)
        self._connect_ip = connect_ip

    def connect(self):
        self.sock = socket.create_connection((self._connect_ip, self.port), self.timeout)


class _PinnedHTTPSConnection(http.client.HTTPSConnection):
    """TLS SNI/sertifika doğrulamasını host adıyla korurken IP'yi sabitler."""

    def __init__(self, connect_ip: str, host_header: str, port: int, timeout: int):
        super().__init__(host_header, port, timeout=timeout)
        self._connect_ip = connect_ip

    def connect(self):
        raw_sock = socket.create_connection((self._connect_ip, self.port), self.timeout)
        self.sock = self._context.wrap_socket(raw_sock, server_hostname=self.host)


def safe_fetch(url: str, timeout: int = HTTP_TIMEOUT, max_bytes: int = MAX_BYTES,
               referer: Optional[str] = None) -> Tuple[bytes, str]:
    """Tek DNS çözümüyle IP'ye sabitlenmiş, yönlendirmesiz ve boyut sınırlı GET."""
    ok, info = validate_url(url)
    if not ok:
        raise ValueError("SSRF engeli: {}".format(info))
    parsed = urllib.parse.urlsplit(url)
    host = parsed.hostname
    if not host:
        raise ValueError("SSRF engeli: host yok")
    ips = _all_ips(host)
    if not ips or any(not is_safe_ip(ip) for ip in ips):
        raise ValueError("SSRF engeli: DNS sonucu değişti veya güvenli değil")
    connect_ip = ips[0]
    port = parsed.port or (443 if parsed.scheme == "https" else 80)
    host_header = host if parsed.port is None else "{}:{}".format(host, parsed.port)
    path = urllib.parse.urlunsplit(("", "", parsed.path or "/", parsed.query, ""))
    headers = {"Host": host_header, "User-Agent": UA, "Accept-Encoding": "identity"}
    if referer:
        headers["Referer"] = referer
    conn_cls = _PinnedHTTPSConnection if parsed.scheme == "https" else _PinnedHTTPConnection
    conn = conn_cls(connect_ip, host, port, timeout)
    try:
        conn.request("GET", path, headers=headers)
        resp = conn.getresponse()
        if 300 <= resp.status < 400:
            raise ValueError("yönlendirme engellendi (HTTP {})".format(resp.status))
        chunks, total = [], 0
        while True:
            block = resp.read(65536)
            if not block:
                break
            total += len(block)
            if total > max_bytes:
                raise ValueError("boyut limiti aşıldı ({} MB)".format(max_bytes // 1024 // 1024))
            chunks.append(block)
        return b"".join(chunks), "HTTP {}".format(resp.status)
    finally:
        conn.close()


# ===========================================================================
# KONTROL 2 — Kaynak limitli sandbox yürütücüsü
# ===========================================================================
def runtime_on() -> bool:
    """Güvenilmeyen Lua yürütmesi bu dağıtımda bilinçli olarak desteklenmez."""
    return False


def run_limited(cmd: List[str], input_text: Optional[str] = None,
                timeout: int = 10, mem_mb: int = 256, cpu_sec: int = 8,
                env: Optional[Dict[str, str]] = None, limit_mem: bool = True):
    """Alt süreci dar kaynak limitleriyle (bellek/CPU/dosya) yürütür.

    Linux'ta preexec_fn ile RLIMIT_AS/CPU/FSIZE uygular. limit_mem=False ise
    bellek limiti uygulanmaz (Python yorumlayıcısı gibi çok sanal bellek
    ayıran süreçler için — CPU/wall timeout yine de aktif). Yürütme öncesi
    DEOBF_RUNTIME=1 kontrolü yapılmalıdır (çağıran yer yapar).
    """
    def _apply_limits():
        for lim, val in (
            (resource.RLIMIT_CPU, cpu_sec),
            (resource.RLIMIT_FSIZE, mem_mb * 1024 * 1024),
        ):
            try:
                resource.setrlimit(lim, (val, val))
            except (ValueError, OSError):
                pass
        if limit_mem:
            # Adres alanı (sanal bellek) tavanı -> OOM/DoS savunması (sadece
            # küçük ikili — lua — için güvenli; Python için kapatın)
            try:
                v = mem_mb * 1024 * 1024
                resource.setrlimit(resource.RLIMIT_AS, (v, v))
            except (ValueError, OSError):
                pass

    return subprocess.run(
        cmd, input=input_text, capture_output=True, text=True,
        timeout=timeout, preexec_fn=_apply_limits, env=env, errors="replace",
    )


def run_lua_sandboxed(lua_exe: str, script_text: str, timeout: int = 10,
                      mem_mb: int = 256, cpu_sec: int = 8) -> Tuple[str, str, int]:
    """Güvenilmeyen Lua kodunu izole geçici dosyada, dar limitlerle yürütür.

    Dönüş: (stdout, stderr_kuyruk, returncode). DEOBF_RUNTIME=1 değilse
    PermissionError yükseltir (çağıran yer bunu beklemeli).
    """
    if not runtime_on():
        raise PermissionError("Runtime Lua yürütme kapalı (DEOBF_RUNTIME=1 gerekiyor)")
    if not os.path.exists(lua_exe):
        raise FileNotFoundError(f"lua yorumlayıcı yok: {lua_exe}")
    # izole çalışma dizini
    d = tempfile.mkdtemp(prefix="lua_sbx_")
    try:
        hedef = os.path.join(d, "target.lua")
        with open(hedef, "w", encoding="utf-8", errors="replace") as f:
            f.write(script_text)
        env = dict(os.environ)
        env["LUA_PATH"] = ""          # modül aramasını kapat
        try:
            r = run_limited([lua_exe, hedef], timeout=timeout,
                            mem_mb=mem_mb, cpu_sec=cpu_sec, env=env)
            return r.stdout or "", (r.stderr or "")[-400:], r.returncode
        except subprocess.TimeoutExpired:
            return "", "timeout (süre aşımı)", -1
    finally:
        import shutil
        shutil.rmtree(d, ignore_errors=True)


# ===========================================================================
# KONTROL 3 — Yetki & hız sınırı
# ===========================================================================
def get_owner_id() -> Optional[int]:
    v = os.environ.get("OWNER_ID") or os.environ.get("DISCORD_OWNER_ID")
    try:
        return int(v) if v else None
    except ValueError:
        return None


def owner_or_manage_guild(ctx) -> bool:
    """Komut sahibi veya 'Sunucuyu Yönet' yetkili biri mi?"""
    owner = get_owner_id()
    if owner and ctx.author.id == owner:
        return True
    if ctx.guild:
        return ctx.author.guild_permissions.manage_guild
    return False  # DM'de sadece owner


def fetch_budget_ok(key: str, limit: int = 6, window: float = 60.0) -> Tuple[bool, int]:
    """Çok basit süreli istek bütçesi (kanal/URL başı). -> (izin, kalan).

    Bot süreci boyunca RAM'de tutulur; restart'ta sıfırlanır (kabul edilebilir).
    """
    import time
    now = time.time()
    state = fetch_budget_ok._state  # type: ignore[attr-defined]
    bucket = state.setdefault(key, [])
    bucket[:] = [t for t in bucket if now - t < window]
    if len(bucket) >= limit:
        return False, 0
    bucket.append(now)
    return True, limit - len(bucket)
fetch_budget_ok._state = {}  # type: ignore[attr-defined]
