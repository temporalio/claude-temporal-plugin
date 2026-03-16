# data-handling.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Ruby | Rb# | Go |
|---------|------|--------|-----|------------|-----|------|-----|-----|
| Overview | — | ✓ | 1 | ✓ | 1 | TODO | 1 | |
| Default Data Converter | — | ✓ | 2 | ✓ | 2 | TODO | 2 | |
| Pydantic Integration | — | ✓ | 3 | — | — | — | — | |
| ActiveModel Integration | — | — | — | — | — | TODO | 3 | |
| Custom Data Converter | — | ✓ | 4 | ✓ | 3 | TODO | 4 | |
| Composition of Payload Converters | — | — | — | ✓ | 4 | — | — | |
| Converter Hints | — | — | — | — | — | TODO | 5 | |
| Protobuf Support | — | — | — | ✓ | 5 | — | — | |
| Payload Encryption | — | ✓ | 5 | ✓ | 6 | TODO | 6 | |
| Search Attributes | — | ✓ | 6 | ✓ | 7 | TODO | 7 | |
| Workflow Memo | — | ✓ | 7 | ✓ | 8 | TODO | 8 | |
| Large Payloads | — | — | — | — | — | — | — | |
| Deterministic APIs for Values | — | ✓ | 8 | — | — | TODO | 9 | |
| Best Practices | — | ✓ | 9 | ✓ | 9 | TODO | 10 | |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | — |
| TypeScript | ✓ aligned | — |
| Ruby | — | Not started |
| Go | — | Not started |

## Status

**Sections needing review (empty cells):**
- Go column: all empty — Go files not yet created
- Ruby column: all TODO — Ruby files not yet created

**Intentionally missing (`—`):**
- Core column: data handling is implementation-specific, no core concepts doc needed
- Pydantic Integration: Python-specific (TS uses plain JSON/types)
- ActiveModel Integration: Ruby-specific (equivalent of Pydantic; ActiveModelJSONSupport mixin)
- Composition of Payload Converters: TS-specific section
- Converter Hints: Ruby-specific (`workflow_arg_hint`, `workflow_result_hint` — needed because Ruby lacks type annotations)
- Protobuf Support: TS-specific section (Ruby/Python handle protobufs via default converter with `Google::Protobuf::MessageExts`)
- Deterministic APIs for Values: Python has `workflow.uuid4()`, `workflow.random()`; Ruby has `Temporalio::Workflow.random`, `Temporalio::Workflow.now`, `Temporalio::Workflow.uuid`
- Large Payloads: Moved to `core/patterns.md` (Large Data Handling) and `core/gotchas.md` (Payload Size Limits)

**Ruby notes:**
- Default converter: nil, bytes, Protobuf, then JSON (using Ruby's `JSON` module with `create_additions: true`)
- Symbol keys become string keys on deserialization
- JSON Additions supported but not cross-language compatible
- ActiveModel: needs `ActiveModelJSONSupport` mixin for proper serialization
- Converter Hints: unique to Ruby — `workflow_arg_hint MyClass`, `workflow_result_hint MyClass` — needed because Ruby lacks type hints
- Search Attributes: `Temporalio::SearchAttributes::Key.new('name', type)`, `Temporalio::Workflow.upsert_search_attributes`
- Deterministic APIs: `Temporalio::Workflow.random` (SecureRandom replacement), `Temporalio::Workflow.now` (Time.now replacement), `Temporalio::Workflow.uuid` (UUID generation)

**Order alignment:** ✅ ALIGNED — Ruby follows Python order with Ruby-specific additions (ActiveModel, Converter Hints)

**Style alignment:** All TypeScript sections aligned with Python. No changes needed.
