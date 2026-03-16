# data-handling.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Java | J# | Go |
|---------|------|--------|-----|------------|-----|------|----|----|
| Overview | — | ✓ | 1 | ✓ | 1 | TODO | 1 | |
| Default Data Converter | — | ✓ | 2 | ✓ | 2 | TODO | 2 | |
| Pydantic Integration | — | ✓ | 3 | — | — | — | — | |
| Jackson Integration | — | — | — | — | — | TODO | 3 | |
| Custom Data Converter | — | ✓ | 4 | ✓ | 3 | TODO | 4 | |
| Composition of Payload Converters | — | — | — | ✓ | 4 | TODO | 5 | |
| Protobuf Support | — | — | — | ✓ | 5 | TODO | 6 | |
| Payload Encryption | — | ✓ | 5 | ✓ | 6 | TODO | 7 | |
| Search Attributes | — | ✓ | 6 | ✓ | 7 | TODO | 8 | |
| Workflow Memo | — | ✓ | 7 | ✓ | 8 | TODO | 9 | |
| Large Payloads | — | — | — | — | — | — | — | |
| Deterministic APIs for Values | — | ✓ | 8 | — | — | TODO | 10 | |
| Best Practices | — | ✓ | 9 | ✓ | 9 | TODO | 11 | |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | — |
| TypeScript | ✓ aligned | — |
| Java | — | Not started |
| Go | — | Not started |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created

**Java column decisions:**
- Default Data Converter: Java uses Jackson JSON by default (Null, byte[], Protobuf JSON, JSON)
- Pydantic Integration: — (Python-specific; Java equivalent is Jackson Integration)
- Jackson Integration: Java-specific — `JacksonJsonPayloadConverter` for custom ObjectMapper config
- Custom Data Converter: Java has `PayloadConverter` interface, `DefaultDataConverter.withPayloadConverterOverrides()`
- Composition of Payload Converters: Java supports this (like TS) via `DefaultDataConverter`
- Protobuf Support: Java has built-in Protobuf support (like TS)
- Payload Encryption: Java has `PayloadCodec` + `CodecDataConverter`
- Deterministic APIs for Values: Java has `Workflow.newRandom()`, `Workflow.randomUUID()`, `Workflow.currentTimeMillis()` (like Python)
- Large Payloads: — (moved to patterns.md and gotchas.md)

**Intentionally missing (`—`):**
- Core column: data handling is implementation-specific, no core concepts doc needed
- Pydantic Integration: Python-specific (TS uses plain JSON/types)
- Jackson Integration: Java-specific (custom ObjectMapper, type handling)
- Protobuf Support: TS/Java-specific section (Python handles protobufs via default converter)
- Deterministic APIs for Values: Python/Java-specific (TS V8 sandbox handles automatically)
- Large Payloads: Moved to `core/patterns.md` (Large Data Handling) and `core/gotchas.md` (Payload Size Limits)

**Order alignment:** ✅ ALIGNED — Reordered TypeScript to match Python order. Java follows similar order.

**Style alignment:** All TypeScript sections aligned with Python. No changes needed.
