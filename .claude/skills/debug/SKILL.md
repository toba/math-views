---
name: debug
description: >
  Runtime debugging for the MathViews Swift package using LLDB and xc-debug MCP tools.
  Use when: (1) Attaching LLDB to a running app that uses MathViews, (2) Setting breakpoints
  in typesetting, parsing, or font code, (3) Inspecting math rendering state at runtime,
  (4) Diagnosing layout, spacing, or glyph issues, (5) User says "debug", "breakpoint",
  "attach", "inspect", or asks to investigate runtime behavior.
---

# Debug

## Debugging in Tests

Most debugging for a library happens through tests. Run a specific test with verbose output:

```bash
swift test --filter TestClassName.testMethodName 2>&1
```

For deeper investigation, attach LLDB directly:

```bash
# Build tests without running
swift build --build-tests

# Run under LLDB
lldb -- .build/debug/MathViewsPackageTests.xctest
(lldb) breakpoint set --name "Typesetter.createLineForMathList"
(lldb) run
```

## MCP Debug Tools (xc-debug)

When debugging an app that embeds MathViews, use xc-debug MCP tools to attach to the running process.

### Attach to running app
```
mcp__xc-debug__debug_attach_sim(bundle_id: "com.example.myapp")
```

### Set breakpoints in MathViews code

**Parser entry:**
```
debug_breakpoint_add(bundle_id: "...", file: "Parser/Builder.swift", line: 42)
```

**Typesetter entry:**
```
debug_breakpoint_add(bundle_id: "...", symbol: "Typesetter.createLineForMathList")
```

**Font loading:**
```
debug_breakpoint_add(bundle_id: "...", file: "Font/Instance.swift", line: 25)
```

### Inspect state when paused
```
debug_variables()           # Local variables
debug_stack()               # Call stack
debug_evaluate(expression: "atom.nucleus")
debug_evaluate(expression: "display.width")
```

## Key Debugging Scenarios

### Wrong spacing between atoms
1. Set breakpoint in `Typesetter` at inter-element spacing calculation
2. Inspect `leftType`, `rightType`, and the spacing table lookup
3. Check `InterElementSpaceType` for the atom pair

### Missing or wrong glyph
1. Set breakpoint in font glyph lookup (`MathTable`)
2. Inspect the glyph ID, construction variants, and assembly parts
3. Check the `.plist` math table for the expected entries

### Line breaking issues
1. Set breakpoint in `LineFitter.fitElements`
2. Inspect element widths, available width, and break decisions
3. Check `BreakableElement` properties

## Rendering Pipeline Debug Points

| Stage | Key File | What to Inspect |
|-------|----------|-----------------|
| Parse | Parser/Builder.swift | Token stream, error recovery |
| AST | Atoms/ (Atom.swift, List.swift) | Atom types, nucleus values, scripts |
| Typeset | Typesetter/Typesetter.swift | Spacing, positions, line metrics |
| Display | Display/Display.swift | Bounding boxes, draw calls |
| Render | UI/View.swift | View frame, content scale |
