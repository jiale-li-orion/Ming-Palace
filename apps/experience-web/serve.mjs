/**
 * 本地静态服务：手机同网预览体验层。
 * 用法：node serve.mjs  或  node serve.mjs --local
 */
import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { join, extname } from "node:path";
import { fileURLToPath } from "node:url";
import { networkInterfaces } from "node:os";

const root = fileURLToPath(new URL(".", import.meta.url));
const port = Number(process.env.PORT) || 5173;
const localOnly = process.argv.includes("--local");

const MIME = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".json": "text/json; charset=utf-8",
  ".webp": "image/webp",
  ".mp4": "video/mp4",
  ".webm": "video/webm",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".svg": "image/svg+xml",
};

function lanIp() {
  for (const iface of Object.values(networkInterfaces())) {
    for (const cfg of iface ?? []) {
      if (cfg.family === "IPv4" && !cfg.internal) return cfg.address;
    }
  }
  return "127.0.0.1";
}

const server = createServer(async (req, res) => {
  const raw = req.url?.split("?")[0] ?? "/";
  const rel = raw === "/" ? "index.html" : raw.replace(/^\//, "");
  const path = join(root, rel);

  try {
    const body = await readFile(path);
    const type = MIME[extname(path)] ?? "application/octet-stream";
    res.writeHead(200, { "Content-Type": type, "Cache-Control": "no-store" });
    res.end(body);
  } catch {
    res.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" });
    res.end("404 Not found");
  }
});

server.listen(port, localOnly ? "127.0.0.1" : "0.0.0.0", () => {
  const host = localOnly ? "127.0.0.1" : lanIp();
  console.log(`体验层已启动`);
  console.log(`  本机: http://127.0.0.1:${port}`);
  if (!localOnly) console.log(`  手机: http://${host}:${port}`);
});
