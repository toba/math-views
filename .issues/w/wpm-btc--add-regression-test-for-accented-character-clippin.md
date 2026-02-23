---
# wpm-btc
title: Add regression test for accented character clipping fix
status: ready
type: task
priority: low
created_at: 2026-02-23T03:36:08Z
updated_at: 2026-02-23T03:36:08Z
---

In Display.swift:97-103, there's a critical fix using max of typographic and visual width to prevent accented character clipping. This fix is well-documented in comments but should have a dedicated regression test that verifies italic/oblique accented characters don't get clipped. The test should render characters like accented italic letters and verify the display width accounts for glyph overhang.
