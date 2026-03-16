# data-handling.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Go | PHP | PHP# |
|---------|------|--------|-----|------------|-----|----|-----|------|
| Overview | — | ✓ | 1 | ✓ | 1 | | ✓ | 1 |
| Default Data Converter | — | ✓ | 2 | ✓ | 2 | | ✓ | 2 |
| Pydantic Integration | — | ✓ | 3 | — | — | | — | — |
| Custom Data Conversion | — | ✓ | 4 | ✓ | 3 | | ✓ | 3 |
| Composition of Payload Converters | — | — | — | ✓ | 4 | | — | — |
| Protobuf Support | — | — | — | ✓ | 5 | | — | — |
| Payload Encryption | — | ✓ | 5 | ✓ | 6 | | ✓ | 4 |
| Search Attributes | — | ✓ | 6 | ✓ | 7 | | ✓ | 5 |
| Workflow Memo | — | ✓ | 7 | ✓ | 8 | | ✓ | 6 |
| Large Payloads | — | — | — | — | — | | — | — |
| Deterministic APIs for Values | — | ✓ | 8 | — | — | | — | — |
| Best Practices | — | ✓ | 9 | ✓ | 9 | | ✓ | 7 |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | — |
| TypeScript | ✓ aligned | — |
| Go | — | Not started |
| PHP | ✓ aligned | Matches Python structure; uses #[ReturnType] instead of Pydantic |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created

**Intentionally missing (`—`):**
- Core column: data handling is implementation-specific, no core concepts doc needed
- Pydantic Integration: Python-specific (TS/PHP use plain JSON/types)
- Composition of Payload Converters: TS-specific section
- Protobuf Support: TS-specific section (Python and PHP handle protobufs via default converter)
- Deterministic APIs for Values: Python-specific (`workflow.uuid4()`, `workflow.random()`); PHP uses `Workflow::sideEffect()`
- Large Payloads: Moved to `core/patterns.md` (Large Data Handling) and `core/gotchas.md` (Payload Size Limits)

**Order alignment:** ✅ ALIGNED — Reordered TypeScript to match Python order

**Style alignment:** All TypeScript and PHP sections aligned with Python. PHP uses `#[ReturnType]` attribute instead of Pydantic for typed deserialization.
