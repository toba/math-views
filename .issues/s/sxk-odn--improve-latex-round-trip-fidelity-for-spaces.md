---
# sxk-odn
title: Improve LaTeX round-trip fidelity for spaces
status: ready
type: task
priority: low
created_at: 2026-02-23T03:36:08Z
updated_at: 2026-02-23T03:36:08Z
---

In MathAtomFactory.swift:789,792, there are known limitations in the LaTeX-to-atom-to-LaTeX round-trip conversion, specifically around space handling. The mathListToString function doesn't always reproduce the original LaTeX exactly. Could improve fidelity for better round-trip support.
