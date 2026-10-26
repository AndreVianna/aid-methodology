"""check_site.py <project> <out-dir> -- grade a reworked product site; print one JSON object.

Checks, all by code: the site builds; no page names a skill command that does not exist or the old hyphenated kind
form (`/aid-create-api`); no internal link is broken; an axe accessibility scan of every page finds no serious or
critical violation; how much machinery (generator code, tests, npm scripts, dependencies) the site keeps. It also
saves desktop and phone screenshots of four pages to <out-dir> for a design review. Needs Playwright and axe-core
(AXE_JS: the path of axe.min.js).
"""

import json
import os
import re
import subprocess
import sys
import threading
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

NODE = r"""
const { chromium } = require('playwright');
const fs = require('fs');
const [base, pagesFile, axePath, shotDir] = process.argv.slice(2);
const pages = JSON.parse(fs.readFileSync(pagesFile, 'utf8'));
(async () => {
  const browser = await chromium.launch();
  const out = { violations: {}, shots: [] };
  const page = await browser.newPage();
  for (const p of pages) {
    await page.goto(base + p, { waitUntil: 'load' });
    await page.addScriptTag({ path: axePath });
    const r = await page.evaluate(async () => (await axe.run(document, { resultTypes: ['violations'] })).violations
      .filter((v) => v.impact === 'serious' || v.impact === 'critical').map((v) => v.id + ' x' + v.nodes.length));
    if (r.length) out.violations[p] = r;
  }
  const shots = ['/', pages.find((p) => p.includes('get-started')) || pages[1],
                 pages.find((p) => p.includes('/skills/')) || pages[2], pages.find((p) => p.includes('concepts')) || pages[3]];
  for (const [name, w, h] of [['desktop', 1440, 900], ['phone', 390, 844]]) {
    const ctx = await browser.newContext({ viewport: { width: w, height: h } });
    const pg = await ctx.newPage();
    for (const [i, p] of shots.entries()) {
      await pg.goto(base + p, { waitUntil: 'load' });
      const file = `${shotDir}/${name}-${i}.png`;
      await pg.screenshot({ path: file, fullPage: false });
      out.shots.push(file);
    }
    await ctx.close();
  }
  await browser.close();
  console.log(JSON.stringify(out));
})();
"""


def lines(paths) -> int:
    return sum(len(p.read_text(encoding="utf-8", errors="replace").splitlines()) for p in paths if p.is_file())


def main() -> int:
    project, out = Path(sys.argv[1]).resolve(), Path(sys.argv[2]).resolve()
    out.mkdir(parents=True, exist_ok=True)
    site, rep = project / "site", {}
    build = subprocess.run(["npm", "run", "build"], cwd=site, capture_output=True, text=True)
    rep["build_ok"] = build.returncode == 0
    (out / "build.log").write_text(build.stdout + build.stderr, encoding="utf-8")
    dist = site / "dist"
    html = sorted(dist.rglob("*.html")) if rep["build_ok"] else []
    rep["pages"] = len(html)

    skills = {p.name for p in (project / "canonical/skills").iterdir() if p.is_dir()}
    cat = (project / "canonical/aid/templates/shortcut-catalog.yml").read_text(encoding="utf-8")
    kind_ids = {n for n, b in re.findall(r"  - name: (\S+)\n((?:    .*\n)+)", cat) if "kind_of:" in b}
    stale, unknown = set(), set()
    for f in html:
        text = re.sub(r"<[^>]+>", " ", f.read_text(encoding="utf-8", errors="replace"))
        for cmd in re.findall(r"(?<![\w./-])/(aid-[a-z][a-z-]*[a-z])", text):
            if cmd in kind_ids:
                stale.add(cmd)
            elif cmd not in skills:
                unknown.add(cmd)
    rep["stale_commands"], rep["unknown_commands"] = sorted(stale), sorted(unknown)

    broken = set()
    for f in html:
        for href in re.findall(r'href="([^"#?]+)', f.read_text(encoding="utf-8", errors="replace")):
            if re.match(r"^(https?:|mailto:|data:|//)", href):
                continue
            target = (dist / href.lstrip("/")) if href.startswith("/") else (f.parent / href)
            if not (target.is_file() or (target / "index.html").is_file() or target.with_suffix(".html").is_file()):
                broken.add(href)
    rep["broken_links"] = sorted(broken)

    if html and os.environ.get("AXE_JS"):
        server = ThreadingHTTPServer(("127.0.0.1", 0), partial(SimpleHTTPRequestHandler, directory=str(dist)))
        threading.Thread(target=server.serve_forever, daemon=True).start()
        pages = ["/" + str(f.relative_to(dist).parent).strip(".") + ("/" if f.parent != dist else "")
                 for f in html if f.name == "index.html"]
        (out / "pages.json").write_text(json.dumps(sorted(set(p.replace("//", "/") for p in pages))), encoding="utf-8")
        (out / "scan.js").write_text(NODE, encoding="utf-8")
        scan = subprocess.run(["node", str(out / "scan.js"), f"http://127.0.0.1:{server.server_port}",
                               str(out / "pages.json"), os.environ["AXE_JS"], str(out)], capture_output=True, text=True,
                              env=dict(os.environ, NODE_PATH=subprocess.run(["npm", "root", "-g"], capture_output=True,
                                                                             text=True).stdout.strip()))
        server.shutdown()
        try:
            s = json.loads(scan.stdout.strip().splitlines()[-1])
            rep["a11y_pages_with_serious"] = len(s["violations"])
            rep["a11y_violations"] = s["violations"]
            rep["screenshots"] = s["shots"]
        except (ValueError, IndexError):
            rep["a11y_error"] = (scan.stderr or scan.stdout)[-400:]

    tests = [p for p in site.rglob("*") if "__tests__" in p.parts and "node_modules" not in p.parts and p.is_file()]
    code = [p for p in (site / "scripts").rglob("*") if p.is_file() and "__tests__" not in p.parts
            and p.suffix in (".mjs", ".js", ".ts", ".py")] if (site / "scripts").is_dir() else []
    content = [p for p in (site / "src/content").rglob("*") if p.suffix in (".md", ".mdx")]
    pkg = json.loads((site / "package.json").read_text(encoding="utf-8"))
    rep["machinery"] = {"script_lines": lines(code), "test_lines": lines(tests), "content_lines": lines(content),
                        "npm_scripts": len(pkg.get("scripts", {})),
                        "dependencies": len(pkg.get("dependencies", {})) + len(pkg.get("devDependencies", {}))}
    print(json.dumps(rep))
    return 0


if __name__ == "__main__":
    sys.exit(main())
