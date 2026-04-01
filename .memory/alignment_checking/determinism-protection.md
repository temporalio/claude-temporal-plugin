# determinism-protection.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | .NET | DN# | Go | Go# |
|---------|------|--------|-----|------------|-----|------|-----|----|-----|
| Overview | — | ✓ | 1 | ✓ | 1 | ✓ | 1 | ✓ | 1 |
| How the Sandbox Works | — | ✓ | 2 | — | — | — | — | — | — |
| Import Blocking | — | — | — | ✓ | 2 | — | — | — | — |
| Forbidden Operations | — | ✓ | 3 | — | — | — | — | — | — |
| Function Replacement | — | — | — | ✓ | 3 | — | — | — | — |
| Runtime Task Detection | — | — | — | — | — | ✓ | 2 | — | — |
| .NET Task Determinism Rules | — | — | — | — | — | ✓ | 3 | — | — |
| workflowcheck Static Analysis | — | — | — | — | — | — | — | ✓ | 2 |
| Determinism Rules | — | — | — | — | — | — | — | ✓ | 3 |
| Pass-Through Pattern | — | ✓ | 4 | — | — | — | — | — | — |
| Importing Activities | — | ✓ | 5 | — | — | — | — | — | — |
| Disabling the Sandbox | — | ✓ | 6 | — | — | — | — | — | — |
| Customizing Invalid Module Members | — | ✓ | 7 | — | — | — | — | — | — |
| Import Notification Policy | — | ✓ | 8 | — | — | — | — | — | — |
| Disable Lazy sys.modules Passthrough | — | ✓ | 9 | — | — | — | — | — | — |
| File Organization | — | ✓ | 10 | — | — | — | — | — | — |
| Common Issues | — | ✓ | 11 | — | — | — | — | — | — |
| Best Practices | — | ✓ | 12 | — | — | ✓ | 4 | ✓ | 4 |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | Comprehensive (12 sections) |
| TypeScript | ✓ aligned | Minimal (3 sections) — V8 is automatic |
| .NET | ✓ aligned | Minimal (4 sections) — no sandbox, runtime EventListener + Task rules |
| Go | ✓ aligned | Minimal (4 sections) — no runtime sandbox, convention + static analysis |

## Status

**Go-specific notes:**
- Go has NO runtime sandbox (unlike Python's import-restricting sandbox or TS's V8 isolate)
- Determinism enforcement is purely by developer convention + optional static analysis
- `workflowcheck` tool: `go.temporal.io/sdk/contrib/tools/workflowcheck` — detects non-deterministic function calls, channel ops, goroutines, map range
- The tool flags: `time.Now`, `time.Sleep`, `math/rand.globalRand`, `crypto/rand.Reader`, `os.Stdin/Stdout/Stderr`, native goroutines, channel send/receive/range, map range iteration
- Determinism Rules section: covers what developers must avoid (unique to Go since no sandbox catches these)
- Overview: brief explanation that Go relies on convention rather than sandboxing
- Best Practices: use workflowcheck in CI, follow workflow.* API conventions

**Intentionally missing (`—`):**
- Core column: no core file (sandbox implementation is language-specific)
- Most Python sections (sandbox internals, import blocking, pass-through, customization): Not applicable to Go (no sandbox)
- TS sections (Import Blocking, Function Replacement): Not applicable to Go (no V8 isolate)
- Go doesn't need sandbox customization sections because there's no sandbox to customize

**Order alignment:** N/A — files have completely different structures per language

**Style alignment:** ⚠️ Very different structures (intentional, different protection mechanisms)
- Python: Comprehensive (12 sections) — complex sandbox with many customization options
- TypeScript: Minimal (3 sections) — V8 sandbox is mostly automatic
- Go: Minimal (4 sections) — no sandbox, convention-based with static analysis tool
