# determinism-protection.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Go |
|---------|------|--------|-----|------------|-----|-----|
| Overview | — | ✓ | 1 | ✓ | 1 | |
| How the Sandbox Works | — | ✓ | 2 | — | — | |
| Import Blocking | — | — | — | ✓ | 2 | |
| Forbidden Operations | — | ✓ | 3 | — | — | |
| Function Replacement | — | — | — | ✓ | 3 | |
| Pass-Through Pattern | — | ✓ | 4 | — | — | |
| Importing Activities | — | ✓ | 5 | — | — | |
| Disabling the Sandbox | — | ✓ | 6 | — | — | |
| Customizing Invalid Module Members | — | ✓ | 7 | — | — | |
| Import Notification Policy | — | ✓ | 8 | — | — | |
| Disable Lazy sys.modules Passthrough | — | ✓ | 9 | — | — | |
| File Organization | — | ✓ | 10 | — | — | |
| Common Issues | — | ✓ | 11 | — | — | |
| Best Practices | — | ✓ | 12 | — | — | |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | Comprehensive (12 sections) |
| TypeScript | ✓ aligned | Minimal (3 sections) — V8 is automatic |
| Go | — | Not started |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created

**Intentionally missing (`—`):**
- Core column: no core file (sandbox implementation is language-specific)
- Most sections are language-specific due to different sandbox architectures:
  - Python: Pass-through pattern, customization APIs, notification policies
  - TypeScript: Import blocking, function replacement (V8-specific)

**Order alignment:** N/A — files have completely different structures (Python: 12 sections, TS: 3 sections)

**Style alignment:** ⚠️ Very different structures (intentional, different sandboxes require different documentation)
- Python: Comprehensive (12 sections) — complex sandbox with many customization options
- TypeScript: Minimal (3 sections) — V8 sandbox is mostly automatic
- This is appropriate given the different sandbox architectures
