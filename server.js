const http = require('http');

const port = Number(process.env.PORT || 3000);

const server = http.createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    return res.end(JSON.stringify({ ok: true, service: 'deobf-host' }));
  }

  res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
  res.end(`<!doctype html>
<html lang="tr"><head><meta name="viewport" content="width=device-width, initial-scale=1">
<title>DEOBF Bot</title><style>body{margin:0;background:#10131a;color:#e8edf5;font:16px system-ui;display:grid;min-height:100vh;place-items:center}.card{max-width:520px;margin:24px;padding:32px;border:1px solid #293141;border-radius:16px;background:#171c26}h1{margin-top:0}code{background:#0d1118;padding:3px 6px;border-radius:5px}</style></head>
<body><main class="card"><h1>DEOBF Bot</h1><p>Discord Lua analiz ve deobfuscation botu.</p><p>Durum: <strong>hosting hazır</strong></p><p>Bot komutları Discord içinde kullanılabilir. Sağlık kontrolü: <code>/health</code></p></main></body></html>`);
});

server.listen(port, '0.0.0.0', () => console.log(`DEOBF host listening on ${port}`));
