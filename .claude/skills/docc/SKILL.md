---
name: docc
description: |
  Write and maintain DocC documentation for the MathViews Swift package. Use when:
  (1) Creating a Documentation.docc catalog
  (2) Writing or editing documentation landing pages
  (3) Adding articles or guides
  (4) Documenting symbols with triple-slash comments
  (5) Organizing Topics sections
  (6) Fixing DocC build warnings or broken links
  (7) User mentions "documentation", "docc", "docs", or asks to document code
---

# DocC Documentation

Write documentation that builds correctly and follows Apple's DocC conventions.

## Quick Reference

### Documentation Comment Syntax

```swift
/// Summary sentence (becomes the abstract).
///
/// Discussion paragraph with additional context.
///
/// - Parameters:
///   - name: Description of the parameter.
///   - value: Another parameter description.
/// - Returns: What the function returns.
/// - Throws: ``ErrorType`` when something fails.
func myFunction(name: String, value: Int) throws -> String
```

### Symbol Linking

| Syntax | Use |
|--------|-----|
| `` ``TypeName`` `` | Link to type |
| `` ``TypeName/method`` `` | Link to member |
| `<doc:ArticleName>` | Link to article |

### Catalog Structure

This package has a single module `MathViews`. Documentation catalog goes at:

```
Sources/MathViews/Documentation.docc/
├── Main.md           # Landing page: # ``MathViews``
├── Article.md        # Conceptual articles
└── Resources/
    ├── image@2x.png      # Light mode
    └── image~dark@2x.png # Dark mode
```

### Main.md Template

```markdown
# ``MathViews``

One-sentence summary of the module.

## Overview

Paragraph explaining the module's purpose and key concepts.

## Topics

### Group Name
- ``TypeName``
- ``TypeName/property``
- <doc:ArticleName>
```

### Article Template

```markdown
# Article Title

Summary sentence for the article.

## Overview

Introductory paragraph.

## Section Header

Content with code examples:

```swift
// Example code
```
```

## Layout Directives

```markdown
@Row {
    @Column { Paragraph text. }
    @Column { ![Description](image-name) }
}

@TabNavigator {
    @Tab("First") { Content for first tab. }
    @Tab("Second") { Content for second tab. }
}
```

## Common Issues

| Problem | Solution |
|---------|----------|
| Symbol not found | Verify symbol is `public`; use full path ``MathViews/Type/member`` |
| Image not showing | Check file is in Documentation.docc, correct naming (`@2x`, `~dark`) |
| Article not linked | Add `<doc:ArticleName>` to Topics section in Main.md |
| Build warning "No overview" | Add `## Overview` section after title |

## Validation

```bash
swift package generate-documentation --warnings-as-errors
```
