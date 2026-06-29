#!/usr/bin/env python3
"""Render docs/digests/metrics.csv -> a self-contained SVG activity trend.

Grouped vertical bars per digest date for each metric. Native (no browser),
stdlib only — safe in this sandbox where headless-browser renderers hang.

CSV schema: date,skills_updated,papers_added,tool_releases,candidates
Usage: render-trend.py [metrics.csv] [-o out.svg]   (default csv: docs/digests/metrics.csv; default out: stdout)
"""
import argparse
import csv

SERIES = [("skills_updated", "skills", "#185FA5"),
          ("papers_added", "papers", "#3C3489"),
          ("tool_releases", "releases", "#0F6E56"),
          ("candidates", "candidates", "#BA7517")]
W, H = 680, 260
ML, MR, MT, MB = 44, 16, 46, 52


def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def load(path, n=14):
    with open(path, newline="") as f:
        rows = list(csv.DictReader(f))
    return rows[-n:]


def render(rows):
    plot_w, plot_h = W - ML - MR, H - MT - MB
    ceil = max(1, max(int(r.get(k) or 0) for r in rows for k, _, _ in SERIES))
    step = max(1, ceil // 4)
    o = [f'<svg width="{W}" height="{H}" viewBox="0 0 {W} {H}" '
         f'xmlns="http://www.w3.org/2000/svg" font-family="Helvetica,Arial,sans-serif">',
         f'<rect width="{W}" height="{H}" fill="white"/>',
         f'<text x="{ML}" y="18" font-size="13" font-weight="600" fill="#1a1a1a">'
         f'Digest activity — last {len(rows)} run(s)</text>']
    lx = ML
    for _, lab, c in SERIES:
        o.append(f'<rect x="{lx}" y="27" width="10" height="10" rx="2" fill="{c}"/>')
        o.append(f'<text x="{lx + 14}" y="36" font-size="11" fill="#555">{lab}</text>')
        lx += 18 + len(lab) * 7 + 12
    for i in range(0, ceil + 1, step):
        y = MT + plot_h - (i / ceil) * plot_h
        o.append(f'<line x1="{ML}" y1="{y:.1f}" x2="{W - MR}" y2="{y:.1f}" stroke="#eee"/>')
        o.append(f'<text x="{ML - 6}" y="{y + 3:.1f}" font-size="10" fill="#999" '
                 f'text-anchor="end">{i}</text>')
    ng = len(rows)
    gw = plot_w / max(1, ng)
    bw = min(16, (gw - 10) / len(SERIES))
    for gi, r in enumerate(rows):
        gx = ML + gi * gw + (gw - bw * len(SERIES)) / 2
        for si, (k, _, c) in enumerate(SERIES):
            v = int(r.get(k) or 0)
            bh = (v / ceil) * plot_h
            x, y = gx + si * bw, MT + plot_h - bh
            o.append(f'<rect x="{x:.1f}" y="{y:.1f}" width="{max(1, bw - 1):.1f}" '
                     f'height="{bh:.1f}" fill="{c}"/>')
        d = (r.get("date") or "")[5:]
        o.append(f'<text x="{ML + gi * gw + gw / 2:.1f}" y="{H - MB + 16}" '
                 f'font-size="10" fill="#555" text-anchor="middle">{esc(d)}</text>')
    o.append('</svg>')
    return "\n".join(o)


EMPTY = ('<svg width="680" height="60" xmlns="http://www.w3.org/2000/svg">'
         '<text x="10" y="35" font-family="Helvetica" font-size="13" fill="#999">'
         'No digest metrics yet.</text></svg>')


def main(argv=None):
    p = argparse.ArgumentParser()
    p.add_argument("csv", nargs="?", default="docs/digests/metrics.csv")
    p.add_argument("-o", "--out")
    a = p.parse_args(argv)
    try:
        rows = load(a.csv)
    except FileNotFoundError:
        rows = []
    svg = render(rows) if rows else EMPTY
    if a.out:
        with open(a.out, "w") as f:
            f.write(svg)
        print(f"wrote {a.out}")
    else:
        print(svg)


if __name__ == "__main__":
    main()
