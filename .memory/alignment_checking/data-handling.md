# data-handling.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Go |
|---------|------|--------|-----|------------|-----|-----|
| Overview | — | ✓ | 1 | ✓ | 1 | |
| Default Data Converter | — | ✓ | 2 | ✓ | 2 | |
| Pydantic Integration | — | ✓ | 3 | — | — | |
| Custom Data Converter | — | ✓ | 4 | ✓ | 3 | |
| Composition of Payload Converters | — | — | — | ✓ | 4 | |
| Protobuf Support | — | — | — | ✓ | 5 | |
| Payload Encryption | — | ✓ | 5 | ✓ | 6 | |
| Search Attributes | — | ✓ | 6 | ✓ | 7 | |
| Workflow Memo | — | ✓ | 7 | ✓ | 8 | |
| Large Payloads | — | — | — | — | — | |
| Deterministic APIs for Values | — | ✓ | 8 | — | — | |
| Best Practices | — | ✓ | 9 | ✓ | 9 | |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | — |
| TypeScript | ✓ aligned | — |
| Go | — | Not started |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created

**Intentionally missing (`—`):**
- Core column: data handling is implementation-specific, no core concepts doc needed
- Pydantic Integration: Python-specific (TS uses plain JSON/types)
- Protobuf Support: TS-specific section (Python handles protobufs via default converter)
- Deterministic APIs for Values: Python-specific (`workflow.uuid4()`, `workflow.random()`)
- Large Payloads: Moved to `core/patterns.md` (Large Data Handling) and `core/gotchas.md` (Payload Size Limits)

**Order alignment:** ✅ ALIGNED — Reordered TypeScript to match Python order

**Style alignment:** All TypeScript sections aligned with Python. No changes needed.
