# data-handling.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Ruby | Rb# | Go | Go# |
|---------|------|--------|-----|------------|-----|------|-----|-----|-----|
| Overview | — | ✓ | 1 | ✓ | 1 | TODO | 1 | ✓ | 1 |
| Default Data Converter | — | ✓ | 2 | ✓ | 2 | TODO | 2 | ✓ | 2 |
| Pydantic Integration | — | ✓ | 3 | — | — | — | — | — | — |
| ActiveModel Integration | — | — | — | — | — | TODO | 3 | — | — |
| Custom Data Converter | — | ✓ | 4 | ✓ | 3 | TODO | 4 | ✓ | 3 |
| Composition of Payload Converters | — | — | — | ✓ | 4 | — | — | ✓ | 4 |
| Converter Hints | — | — | — | — | — | TODO | 5 | — | — |
| Protobuf Support | — | — | — | ✓ | 5 | — | — | ✓ | 5 |
| Payload Encryption | — | ✓ | 5 | ✓ | 6 | TODO | 6 | ✓ | 6 |
| Search Attributes | — | ✓ | 6 | ✓ | 7 | TODO | 7 | ✓ | 7 |
| Workflow Memo | — | ✓ | 7 | ✓ | 8 | TODO | 8 | ✓ | 8 |
| Large Payloads | — | — | — | — | — | — | — | — | — |
| Deterministic APIs for Values | — | ✓ | 8 | — | — | TODO | 9 | — | — |
| Best Practices | — | ✓ | 9 | ✓ | 9 | TODO | 10 | ✓ | 9 |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | — |
| TypeScript | ✓ aligned | — |
| Ruby | — | Not started |
| Go | ✓ aligned | JSON default, protobuf native, converter.CompositeDataConverter |

## Status

**Ruby notes:**
- Default converter: nil, bytes, Protobuf, then JSON (using Ruby's `JSON` module with `create_additions: true`)
- Symbol keys become string keys on deserialization
- JSON Additions supported but not cross-language compatible
- ActiveModel: needs `ActiveModelJSONSupport` mixin for proper serialization
- Converter Hints: unique to Ruby — `workflow_arg_hint MyClass`, `workflow_result_hint MyClass` — needed because Ruby lacks type hints
- Search Attributes: `Temporalio::SearchAttributes::Key.new('name', type)`, `Temporalio::Workflow.upsert_search_attributes`
- Deterministic APIs: `Temporalio::Workflow.random` (SecureRandom replacement), `Temporalio::Workflow.now` (Time.now replacement), `Temporalio::Workflow.uuid` (UUID generation)

**Go-specific notes:**
- Default Data Converter: Go uses `converter.NewCompositeDataConverter()` with JSON as default — chain: NilPayloadConverter, ByteSlicePayloadConverter, ProtoPayloadConverter, ProtoJSONPayloadConverter, JSONPayloadConverter
- Custom Data Converter: implement `converter.DataConverter` interface
- Composition of Payload Converters: Go has `converter.NewCompositeDataConverter()` — similar to TS
- Protobuf Support: Go has native proto support via `converter.NewProtoPayloadConverter()` — both proto binary and proto JSON
- Payload Encryption: Go uses `converter.PayloadCodec` interface for encryption/compression
- Search Attributes: `workflow.UpsertSearchAttributes(ctx, map)`, query via client
- Workflow Memo: set in `client.StartWorkflowOptions`
- Note on v1.26.0+: proto types changed from gogo to google protobuf; `LegacyTemporalProtoCompat` option available

**Intentionally missing (`—`):**
- Core column: data handling is implementation-specific
- Pydantic Integration: Python-specific (TS uses plain JSON/types)
- ActiveModel Integration: Ruby-specific (equivalent of Pydantic)
- Composition of Payload Converters: TS/Go-specific section
- Converter Hints: Ruby-specific (`workflow_arg_hint`, `workflow_result_hint` — needed because Ruby lacks type annotations)
- Protobuf Support: TS/Go-specific section (Ruby/Python handle protobufs via default converter)
- Deterministic APIs for Values: Python has `workflow.uuid4()`, `workflow.random()`; Ruby has `Temporalio::Workflow.random/now/uuid`; Go covers in determinism.md
- Large Payloads: Moved to core/patterns.md and core/gotchas.md

**Order alignment:** ✅ ALIGNED — Ruby follows Python order with Ruby-specific additions (ActiveModel, Converter Hints)

**Style alignment:** ✅ Complete (Python, TypeScript, Go). Ruby: ~10 sections planned.
