#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
PORT="${PORT:-3000}"
/usr/bin/time -p test "${RUNTIME_DIR:-unset}" = unset -o -d "${RUNTIME_DIR:-.}" || true
PROJECT_ROOT="$(/usr/bin/time -p pwd)"
/usr/bin/time -p mkdir -p "$PROJECT_ROOT/dist"
OPENCODE_WEB_DIR="${OPENCODE_WEB_DIR:-/home/runner/work/_temp/omgithub-web}"
/usr/bin/time -p mkdir -p "$OPENCODE_WEB_DIR"
/usr/bin/time -p test -f "$PROJECT_ROOT/dist/index.html"
if /usr/bin/time -p test -f "$PROJECT_ROOT/package.json"; then
  if /usr/bin/time -p test -f "$PROJECT_ROOT/package-lock.json"; then
    /usr/bin/time -p npm ci --no-audit --no-fund
  else
    /usr/bin/time -p npm install --no-audit --no-fund
  fi
  if /usr/bin/time -p node -e 'process.exit(require("./package.json").scripts?.build ? 0 : 1)'; then
    /usr/bin/time -p npm run build
  fi
  /usr/bin/time -p test -f "$PROJECT_ROOT/dist/index.html"
fi
/usr/bin/time -p bash -c 'printf "{\"project\":%s,\"directory\":%s}" "$(node -e "console.log(JSON.stringify(process.argv[1]))" "$1")" "$(node -e "console.log(JSON.stringify(process.argv[1]))" "$2")" > "$3"' _ "$PROJECT_ROOT" "$PROJECT_ROOT/dist" "$OPENCODE_WEB_DIR/deployment-output.json"
/usr/bin/time -p cat "$OPENCODE_WEB_DIR/deployment-output.json"
/usr/bin/time -p node -e '
const http = require("http");
const fs = require("fs");
const path = require("path");
const root = path.join(process.cwd(), "dist");
const port = Number(process.env.PORT || "3000");
const mime = { ".html": "text/html", ".js": "application/javascript", ".css": "text/css", ".json": "application/json", ".svg": "image/svg+xml", ".png": "image/png", ".jpg": "image/jpeg", ".webp": "image/webp", ".wasm": "application/wasm", ".glb": "model/gltf-binary" };
http.createServer((req, res) => {
  try {
    const url = new URL(req.url, "http://localhost");
    let p = path.resolve(root, "." + decodeURIComponent(url.pathname));
    if (p !== path.resolve(root) && !p.startsWith(path.resolve(root) + path.sep)) { res.writeHead(404); res.end(); return; }
    if (fs.existsSync(p) && fs.statSync(p).isDirectory()) p = path.join(p, "index.html");
    const data = fs.readFileSync(p);
    res.setHeader("Content-Type", mime[path.extname(p)] || "application/octet-stream");
    res.setHeader("Cache-Control", "no-cache");
    res.end(data);
  } catch { res.writeHead(404); res.end("Not found"); }
}).listen(port, "0.0.0.0", () => console.log("Serving " + root + " on " + port));
'
