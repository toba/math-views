---
# gp1-4uh
title: Document radical spacing departure from LaTeX
status: completed
type: task
priority: low
created_at: 2026-02-23T03:36:08Z
updated_at: 2026-02-23T04:57:13Z
---

In Typesetter.swift:52, there's a comment: 'This is a departure from latex but we don't want \sqrt{4}4 to look weird so we put a space in between.' This intentional deviation from LaTeX behavior should be documented in the FontSystem or RenderingPipeline DocC article, and possibly as a note on the interElementSpaceIndex function.


## Summary of Changes

- Added a `- Note:` doc comment on `interElementSpaceIndex(for:row:)` in `Spacing.swift` explaining the radical-specific row and why it departs from LaTeX.
- Extended the inter-element spacing bullet in `RenderingPipeline.md` to call out the radical spacing deviation.
