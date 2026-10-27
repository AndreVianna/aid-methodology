"""check_site.py <project> <out-dir> -- grade a reworked product site; print one JSON object.

Checks, all by code: the site builds; no page names a skill command that does not exist or the old hyphenated kind
form (`/aid-create-api`); no internal link is broken; an axe accessibility scan of every page finds no serious or
critical violation; raw Markdown table separators in built page text; how much machinery the site keeps. It also
saves desktop and phone screenshots of four pages to <out-dir> for a design review. Needs Playwright and axe-core
(AXE_JS: the path of axe.min.js). PLAYWRIGHT_NODE_MODULES can supply the directory containing Playwright, and
PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH can select an existing Chromium executable; both default to Playwright/npm's
normal locations.
"""

import json
import os
import re
import shutil
import subprocess
import sys
import threading
from functools import partial
from html.parser import HTMLParser
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

NODE = r"""
const { chromium } = require('playwright');
const fs = require('fs');
const [base, pagesFile, axePath, shotDir] = process.argv.slice(2);
const pages = JSON.parse(fs.readFileSync(pagesFile, 'utf8'));
(async () => {
  const executablePath = process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH;
  const browser = await chromium.launch(executablePath ? { executablePath } : {});
  const out = { violations: {}, shots: [], screenshot_errors: [], scanned: 0, redirects: [], raw_texts: {} };
  const page = await browser.newPage();
  let styleErrors = [];
  page.on('response', (response) => {
    if (response.request().resourceType() === 'stylesheet' && response.status() >= 400)
      styleErrors.push(response.url() + ' HTTP ' + response.status());
  });
  page.on('requestfailed', (request) => {
    if (request.resourceType() === 'stylesheet') styleErrors.push(request.url() + ' failed');
  });
  for (const p of pages) {
    styleErrors = [];
    const response = await page.goto(base + p, { waitUntil: 'load' });
    if (!response || response.status() >= 400) throw new Error('page failed to load: ' + p);
    await page.waitForTimeout(300);
    const landed = new URL(page.url()).pathname.replace(/\/?$/, '/');
    const requested = new URL(p, base).pathname.replace(/\/?$/, '/');
    if (landed !== requested) { out.redirects.push(p); continue; }  // its target is scanned on its own
    const missingStyles = await page.evaluate(() => Array.from(document.querySelectorAll('link[rel~="stylesheet"]'))
      .filter((link) => !link.disabled && !link.sheet).map((link) => link.href));
    if (missingStyles.length || styleErrors.length)
      throw new Error('stylesheet failed to load on ' + p + ': ' + [...missingStyles, ...styleErrors].join(', '));
    out.scanned += 1;
    // Use computed styles on the live DOM, including external stylesheets.
    out.raw_texts[p] = await page.evaluate(() => {
      const text = [];
      const ignored = new Set(['PRE', 'CODE', 'SCRIPT', 'STYLE', 'TEMPLATE']);
      const blocks = new Set(['P', 'DIV', 'SECTION', 'ARTICLE', 'BR', 'LI', 'TR', 'H1', 'H2', 'H3', 'H4', 'H5', 'H6']);
      function visit(node, visible = true) {
        if (node.nodeType === Node.TEXT_NODE) { if (visible) text.push(node.nodeValue); return; }
        if (node.nodeType !== Node.ELEMENT_NODE || ignored.has(node.tagName)) return;
        const style = getComputedStyle(node);
        if (node.hidden || style.display === 'none' || Number(style.opacity) === 0 || style.contentVisibility === 'hidden') return;
        const childVisible = style.visibility !== 'hidden' && style.visibility !== 'collapse';
        if (blocks.has(node.tagName) && childVisible) text.push('\n');
        for (const child of node.childNodes) visit(child, childVisible);
        if (blocks.has(node.tagName) && childVisible) text.push('\n');
      }
      visit(document.body);
      return text.join('');
    });
    if (axePath) {
      await page.addScriptTag({ path: axePath });
      const r = await page.evaluate(async () => (await axe.run(document, { resultTypes: ['violations'] })).violations
        .filter((v) => v.impact === 'serious' || v.impact === 'critical').map((v) => v.id + ' x' + v.nodes.length));
      if (r.length) out.violations[p] = r;
    }
  }
  const shots = ['/', pages.find((p) => p.includes('get-started')) || pages[1] || '/',
                 pages.find((p) => p.includes('/skills/')) || pages[2] || '/', pages.find((p) => p.includes('concepts')) || pages[3] || '/'];
  for (const [name, w, h] of [['desktop', 1440, 900], ['phone', 390, 844]]) {
    const ctx = await browser.newContext({ viewport: { width: w, height: h } });
    const pg = await ctx.newPage();
    for (const [i, p] of shots.entries()) {
      try {
        await pg.goto(base + p, { waitUntil: 'load' });
        const file = `${shotDir}/${name}-${i}.png`;
        await pg.screenshot({ path: file, fullPage: false });
        out.shots.push(file);
      } catch (error) {
        out.screenshot_errors.push(`${name}-${i}: ${error.message}`);
      }
    }
    await ctx.close();
  }
  await browser.close();
  console.log(JSON.stringify(out));
})();
"""


def lines(paths) -> int:
    return sum(len(p.read_text(encoding="utf-8", errors="replace").splitlines()) for p in paths if p.is_file())


class PageText(HTMLParser):
    """Collect text outside code and explicitly hidden HTML; CSS stylesheets are not evaluated."""

    ignored = {"pre", "code", "script", "style", "template"}
    blocks = {"p", "div", "section", "article", "br", "li", "tr", "h1", "h2", "h3", "h4", "h5", "h6"}

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.depth = 0
        self.text = []

    def handle_starttag(self, tag, attrs):
        attributes = dict(attrs)
        declarations = {}
        for declaration in (attributes.get("style") or "").split(";"):
            name, separator, value = declaration.partition(":")
            if separator:
                declarations[name.strip().lower()] = value.strip().lower().replace("!important", "").strip()
        hidden = ("hidden" in attributes or declarations.get("display") == "none"
                  or declarations.get("visibility") == "hidden")
        if self.depth or tag in self.ignored or hidden:
            if tag not in {"br", "hr", "img", "input", "meta", "link", "source", "wbr"}:
                self.depth += 1
        elif tag in self.blocks:
            self.text.append("\n")

    def handle_endtag(self, tag):
        if self.depth:
            self.depth -= 1
        elif tag in self.blocks:
            self.text.append("\n")

    def handle_startendtag(self, tag, attrs):
        if not self.depth and tag in self.blocks:
            self.text.append("\n")

    def handle_data(self, data):
        if not self.depth:
            self.text.append(data)


def count_raw_tables(html: str) -> int:
    parser = PageText()
    parser.feed(html)
    return count_raw_table_text("".join(parser.text))


def count_raw_table_text(text: str) -> int:
    # A delimiter can be rendered inside a single paragraph with the other rows.
    separator = re.compile(r"(?:\\?\|[ \t]*:?-{3,}:?[ \t]*)+\\?\||"
                           r"(?<![-:]):?-{3,}:?[ \t]*(?:\\?\|[ \t]*:?-{3,}:?[ \t]*)+(?:\\?\|)?")
    return sum(1 for line in text.splitlines() for _ in separator.finditer(line))


def raw_table_pages(dist: Path, pages) -> dict:
    result = {}
    for path in pages:
        count = count_raw_tables(path.read_text(encoding="utf-8", errors="replace"))
        if count:
            result[path.relative_to(dist).as_posix()] = count
    return result


def page_urls(dist: Path, pages) -> list:
    urls = []
    for path in pages:
        relative = path.relative_to(dist)
        if path.name == "index.html":
            parent = relative.parent
            urls.append("/" if parent == Path(".") else "/" + parent.as_posix() + "/")
        else:
            urls.append("/" + relative.as_posix())
    return sorted(set(urls))


def npm_command() -> str:
    return shutil.which("npm.cmd" if os.name == "nt" else "npm") or "npm"


def playwright_node_modules(npm: str) -> str:
    configured = os.environ.get("PLAYWRIGHT_NODE_MODULES")
    if configured:
        return configured
    return subprocess.run([npm, "root", "-g"], capture_output=True, text=True).stdout.strip()


def main() -> int:
    project, out = Path(sys.argv[1]).resolve(), Path(sys.argv[2]).resolve()
    out.mkdir(parents=True, exist_ok=True)
    site, rep = project / "site", {}
    npm = npm_command()
    build = subprocess.run([npm, "run", "build"], cwd=site, capture_output=True, text=True)
    rep["build_ok"] = build.returncode == 0
    (out / "build.log").write_text(build.stdout + build.stderr, encoding="utf-8")
    dist = site / "dist"
    html = sorted(dist.rglob("*.html")) if rep["build_ok"] else []
    rep["pages"] = len(html)
    # A failed build is unscanned, not evidence of zero broken tables.
    rep["raw_table_static_estimate"] = raw_table_pages(dist, html) if rep["build_ok"] else None
    rep["raw_table_pages"] = None
    rep["raw_table_status"] = "not_run"
    rep["raw_table_reason"] = "no built HTML" if not html else "browser scan not yet completed"

    skills = {p.name for p in (project / "canonical/skills").iterdir() if p.is_dir()}
    cat = (project / "canonical/aid/templates/shortcut-catalog.yml").read_text(encoding="utf-8")
    kind_ids = {n for n, b in re.findall(r"  - name: (\S+)\n((?:    .*\n)+)", cat) if "kind_of:" in b}
    stale, unknown = set(), set()
    for f in html:
        text = re.sub(r"<[^>]+>", " ", f.read_text(encoding="utf-8", errors="replace"))
        for tok in re.findall(r"(?<![\w./-])/(aid-[\w$-]+)", text):
            cmd = tok.rstrip("-")
            if not re.fullmatch(r"aid-[a-z-]*[a-z]", cmd):
                continue  # part of a file name or template, such as aid-claude-code-vX.Y.Z
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

    if html:
        server = ThreadingHTTPServer(("127.0.0.1", 0), partial(SimpleHTTPRequestHandler, directory=str(dist)))
        threading.Thread(target=server.serve_forever, daemon=True).start()
        pages = page_urls(dist, html)
        (out / "pages.json").write_text(json.dumps(pages), encoding="utf-8")
        (out / "scan.js").write_text(NODE, encoding="utf-8")
        try:
            scan = subprocess.run(["node", str(out / "scan.js"), f"http://127.0.0.1:{server.server_port}",
                                   str(out / "pages.json"), os.environ.get("AXE_JS", ""), str(out)], capture_output=True, text=True,
                                  encoding="utf-8", env=dict(os.environ, NODE_PATH=playwright_node_modules(npm)))
            if scan.returncode:
                raise ValueError((scan.stderr or scan.stdout)[-400:])
            s = json.loads(scan.stdout.strip().splitlines()[-1])
            if s["scanned"] + len(s["redirects"]) != len(pages) or len(s["raw_texts"]) != s["scanned"]:
                raise ValueError("browser did not scan every non-redirect page")
            rep["raw_table_pages"] = {}
            for url, text in s["raw_texts"].items():
                count = count_raw_table_text(text)
                if count:
                    file = url.lstrip("/") + ("index.html" if url.endswith("/") else "")
                    rep["raw_table_pages"][file] = count
            rep["raw_table_status"] = "complete"
            rep.pop("raw_table_reason", None)
            if os.environ.get("AXE_JS"):
                rep["a11y_pages_with_serious"] = len(s["violations"])
                rep["a11y_status"] = "complete"
                rep["a11y_violations"] = s["violations"]
                rep["a11y_scanned"], rep["redirect_pages"] = s["scanned"], len(s["redirects"])
            else:
                rep["a11y_status"], rep["a11y_reason"] = "not_run", "AXE_JS not set"
            rep["screenshots"] = s["shots"]
            rep["screenshot_errors"] = s["screenshot_errors"]
        except (OSError, ValueError, IndexError, KeyError) as exc:
            rep["raw_table_status"], rep["raw_table_reason"] = "error", str(exc)
            rep["a11y_status"] = "error" if os.environ.get("AXE_JS") else "not_run"
            rep["a11y_reason"] = str(exc) if os.environ.get("AXE_JS") else "AXE_JS not set"
        finally:
            server.shutdown()
            server.server_close()
    else:
        rep["a11y_status"] = "not_run"
        rep["a11y_reason"] = "no built HTML" if not html else "AXE_JS not set"

    tests = [p for p in site.rglob("*") if p.is_file() and not {"node_modules", "dist"} & set(p.parts)
             and ({"__tests__", "tests", "test"} & set(p.relative_to(site).parts) or ".test." in p.name)]
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
