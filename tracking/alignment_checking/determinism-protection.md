# determinism-protection.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Java | J# | Go |
|---------|------|--------|-----|------------|-----|------|----|----|
| Overview | — | ✓ | 1 | ✓ | 1 | TODO | 1 | |
| How the Sandbox Works | — | ✓ | 2 | — | — | — | — | |
| Import Blocking | — | — | — | ✓ | 2 | — | — | |
| Forbidden Operations | — | ✓ | 3 | — | — | TODO | 2 | |
| Function Replacement | — | — | — | ✓ | 3 | — | — | |
| Convention-Based Enforcement | — | — | — | — | — | TODO | 3 | |
| Pass-Through Pattern | — | ✓ | 4 | — | — | — | — | |
| Importing Activities | — | ✓ | 5 | — | — | — | — | |
| Disabling the Sandbox | — | ✓ | 6 | — | — | — | — | |
| Customizing Invalid Module Members | — | ✓ | 7 | — | — | — | — | |
| Import Notification Policy | — | ✓ | 8 | — | — | — | — | |
| Disable Lazy sys.modules Passthrough | — | ✓ | 9 | — | — | — | — | |
| File Organization | — | ✓ | 10 | — | — | — | — | |
| Common Issues | — | ✓ | 11 | — | — | — | — | |
| Best Practices | — | ✓ | 12 | — | — | TODO | 4 | |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | Comprehensive (12 sections) |
| TypeScript | ✓ aligned | Minimal (3 sections) — V8 is automatic |
| Java | — | Not started |
| Go | — | Not started |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created

**Java column decisions:**
- Overview: Java has NO sandbox and NO static analyzer. Determinism protection relies on: (1) developer conventions, (2) runtime replay detection (`NonDeterministicException` when commands don't match events), (3) `WorkflowReplayer` for test-time verification. The SDK's cooperative threading model (one workflow thread at a time under global lock) eliminates the need for synchronization but does NOT prevent calling non-deterministic APIs.
- How the Sandbox Works: — (Java has no sandbox)
- Import Blocking: — (Java has no import restrictions)
- Forbidden Operations: Java-specific list — `Thread.sleep()`, `new Thread()`, synchronization primitives, `UUID.randomUUID()`, `Math.random()`, `System.currentTimeMillis()`, direct I/O in workflows. These are NOT blocked by the SDK — developer must avoid them manually.
- Function Replacement: — (Java does not replace any functions)
- Convention-Based Enforcement: Java-specific — explains that determinism is the developer's responsibility. SDK provides `Workflow.*` alternatives but does not enforce them at compile time or runtime (until replay). Contrast with Python (sandbox blocks operations) and TS (V8 isolation replaces functions). Note: Go has a `workflowcheck` static analyzer but Java does not have an equivalent.
- Pass-Through, Importing Activities, Disabling Sandbox, Customizing, Notification Policy, Lazy Passthrough: — (all Python sandbox-specific)
- File Organization: — (less critical in Java; no sandbox reload)
- Common Issues: — (Python sandbox-specific)
- Best Practices: Java best practices for determinism (use Workflow.* APIs, avoid stdlib alternatives, test with replay)

**Intentionally missing (`—`):**
- Core column: no core file (determinism protection is language-specific)
- Most sections are language-specific due to completely different protection architectures:
  - Python: Complex sandbox with many customization options (12 sections)
  - TypeScript: V8 sandbox with automatic function replacement (3 sections)
  - Java: No sandbox, convention-based (4 sections)

**Order alignment:** N/A — files have completely different structures (Python: 12 sections, TS: 3, Java: 4)

**Style alignment:** ⚠️ Very different structures (intentional, different protection architectures)
- Python: Comprehensive (12 sections) — complex sandbox with many customization options
- TypeScript: Minimal (3 sections) — V8 sandbox is mostly automatic
- Java: Minimal (4 sections) — no sandbox, conventions only
- This is appropriate given the fundamentally different approaches to determinism protection
