import http from "http";
import fs from "fs";
import path from "path";

const server = http.createServer((req, res) => {
  let filePath = path.join(process.cwd(), req.url === "/" ? "preview-badge.html" : req.url);
  const ext = path.extname(filePath);
  const types = { ".html": "text/html", ".svg": "image/svg+xml", ".js": "text/javascript" };
  fs.readFile(filePath, (err, data) => {
    if (err) { res.writeHead(404); res.end("Not found"); return; }
    res.writeHead(200, { "Content-Type": types[ext] || "text/plain" });
    res.end(data);
  });
});
server.listen(8888, () => console.log("Server running on http://localhost:8888"));
