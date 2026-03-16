# data-handling.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | .NET | DN# | Go |
|---------|------|--------|-----|------------|-----|------|-----|-----|
| Overview | — | ✓ | 1 | ✓ | 1 | TODO | 1 | |
| Default Data Converter | — | ✓ | 2 | ✓ | 2 | TODO | 2 | |
| Pydantic Integration | — | ✓ | 3 | — | — | — | — | |
| Custom Data Converter | — | ✓ | 4 | ✓ | 3 | TODO | 3 | |
| Composition of Payload Converters | — | — | — | ✓ | 4 | — | — | |
| Protobuf Support | — | — | — | ✓ | 5 | TODO | 4 | |
| Payload Encryption | — | ✓ | 5 | ✓ | 6 | TODO | 5 | |
| Search Attributes | — | ✓ | 6 | ✓ | 7 | TODO | 6 | |
| Workflow Memo | — | ✓ | 7 | ✓ | 8 | TODO | 7 | |
| Large Payloads | — | — | — | — | — | — | — | |
| Deterministic APIs for Values | — | ✓ | 8 | — | — | TODO | 8 | |
| Best Practices | — | ✓ | 9 | ✓ | 9 | TODO | 9 | |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | — |
| TypeScript | ✓ aligned | — |
| .NET | — | Not started |
| Go | — | Not started |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created

**Intentionally missing (`—`):**
- Core column: data handling is implementation-specific, no core concepts doc needed
- Pydantic Integration: Python-specific (TS uses plain JSON/types, .NET uses System.Text.Json)
- Composition of Payload Converters: TS-specific section (Python and .NET handle converter composition differently)
- Large Payloads: Moved to `core/patterns.md` (Large Data Handling) and `core/gotchas.md` (Payload Size Limits)

**.NET alignment notes:**
- Protobuf Support: ✓ for .NET — built-in via `Google.Protobuf.IMessage` in default converter (unlike Python where it's implicit, .NET has explicit protobuf converter). Follows TS pattern of dedicated section.
- Deterministic APIs for Values: ✓ for .NET — `Workflow.Random`, `Workflow.UtcNow`, `Workflow.NewGuid()`. Similar to Python's `workflow.uuid4()`, `workflow.random()`.
- Custom Data Converter: .NET uses `DataConverter.Default with { PayloadConverter = ... }` record-with pattern

**Order alignment:** ✅ ALIGNED — Reordered TypeScript to match Python order; .NET DN# monotonically increases

**Style alignment:** All TypeScript sections aligned with Python. No changes needed.
