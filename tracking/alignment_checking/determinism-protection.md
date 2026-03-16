# determinism-protection.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Go | PHP | PHP# |
|---------|------|--------|-----|------------|-----|----|-----|------|
| Overview | — | ✓ | 1 | ✓ | 1 | | ✓ | 1 |
| How the Sandbox Works | — | ✓ | 2 | — | — | | — | — |
| Import Blocking | — | — | — | ✓ | 2 | | — | — |
| Forbidden Operations | — | ✓ | 3 | — | — | | ✓ | 2 |
| Function Replacement | — | — | — | ✓ | 3 | | — | — |
| Pass-Through Pattern | — | ✓ | 4 | — | — | | — | — |
| Importing Activities | — | ✓ | 5 | — | — | | — | — |
| Disabling the Sandbox | — | ✓ | 6 | — | — | | — | — |
| Customizing Invalid Module Members | — | ✓ | 7 | — | — | | — | — |
| Import Notification Policy | — | ✓ | 8 | — | — | | — | — |
| Disable Lazy sys.modules Passthrough | — | ✓ | 9 | — | — | | — | — |
| File Organization | — | ✓ | 10 | — | — | | — | — |
| Common Issues | — | ✓ | 11 | — | — | | ✓ | 3 |
| Best Practices | — | ✓ | 12 | — | — | | ✓ | 4 |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | Comprehensive (12 sections) |
| TypeScript | ✓ aligned | Minimal (3 sections) — V8 is automatic |
| Go | — | Not started |
| PHP | ✓ aligned | Minimal (4 sections) — no sandbox |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created

**Intentionally missing (`—`):**
- Core column: no core file (sandbox implementation is language-specific)
- Most sections are language-specific due to different sandbox architectures:
  - Python: Pass-through pattern, customization APIs, notification policies
  - TypeScript: Import blocking, function replacement (V8-specific)
  - PHP: No sandbox at all — most sections don't apply; only Overview, Forbidden Operations, Common Issues (RoadRunner-specific), and Best Practices

**Order alignment:** N/A — files have completely different structures (Python: 12 sections, TS: 3 sections)

**Style alignment:** ⚠️ Very different structures (intentional, different sandboxes require different documentation)
- Python: Comprehensive (12 sections) — complex sandbox with many customization options
- TypeScript: Minimal (3 sections) — V8 sandbox is mostly automatic
- PHP: Very minimal (4 sections) — no sandbox at all; content covers what NOT to do and RoadRunner-specific issues
- This is appropriate given the different sandbox architectures
