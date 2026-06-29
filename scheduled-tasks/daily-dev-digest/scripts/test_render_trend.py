#!/usr/bin/env python3
"""Smoke tests for render-trend.py. Run: python3 test_render_trend.py"""
import importlib.util
import os

_spec = importlib.util.spec_from_file_location(
    "render_trend", os.path.join(os.path.dirname(__file__), "render-trend.py"))
rt = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(rt)

SAMPLE = [
    {"date": "2026-06-27", "skills_updated": "1", "papers_added": "0",
     "tool_releases": "3", "candidates": "1"},
    {"date": "2026-06-28", "skills_updated": "2", "papers_added": "2",
     "tool_releases": "5", "candidates": "2"},
]


def test_renders_svg():
    svg = rt.render(SAMPLE)
    assert svg.startswith("<svg") and svg.endswith("</svg>")
    # 4 series × 2 dates = 8 data bars (+ legend swatches use <rect rx>)
    assert svg.count('fill="#185FA5"') == 1 + 2  # legend swatch + 2 bars
    assert "2026" not in svg  # x labels are MM-DD only
    assert "06-27" in svg and "06-28" in svg


def test_empty_is_valid_svg():
    assert rt.EMPTY.startswith("<svg") and rt.EMPTY.endswith("</svg>")


if __name__ == "__main__":
    test_renders_svg()
    test_empty_is_valid_svg()
    print("ok: render-trend tests pass")
