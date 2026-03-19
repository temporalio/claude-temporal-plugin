# data-handling.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | .NET | DN# | Go | Go# |
|---------|------|--------|-----|------------|-----|------|-----|----|-----|
| Overview | — | ✓ | 1 | ✓ | 1 | TODO | 1 | ✓ | 1 |
| Default Data Converter | — | ✓ | 2 | ✓ | 2 | TODO | 2 | ✓ | 2 |
| Pydantic Integration | — | ✓ | 3 | — | — | — | — | — | — |
| Custom Data Converter | — | ✓ | 4 | ✓ | 3 | TODO | 3 | ✓ | 3 |
| Composition of Payload Converters | — | — | — | ✓ | 4 | — | — | ✓ | 4 |
| Protobuf Support | — | — | — | ✓ | 5 | TODO | 4 | ✓ | 5 |
| Payload Encryption | — | ✓ | 5 | ✓ | 6 | TODO | 5 | ✓ | 6 |
| Search Attributes | — | ✓ | 6 | ✓ | 7 | TODO | 6 | ✓ | 7 |
| Workflow Memo | — | ✓ | 7 | ✓ | 8 | TODO | 7 | ✓ | 8 |
| Large Payloads | — | — | — | — | — | — | — | — | — |
| Deterministic APIs for Values | — | ✓ | 8 | — | — | TODO | 8 | — | — |
| Best Practices | — | ✓ | 9 | ✓ | 9 | TODO | 9 | ✓ | 9 |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | — |
| TypeScript | ✓ aligned | — |
| .NET | — | Not started |
| Go | ✓ aligned | JSON default, protobuf native, converter.CompositeDataConverter |

## Status

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
- Pydantic Integration: Python-specific
- Deterministic APIs for Values: Python-specific; Go covers in determinism.md Safe Builtin Alternatives
- Large Payloads: Moved to core/patterns.md and core/gotchas.md

**Order alignment:** ✅ ALIGNED — Go sections follow same order as Python/TypeScript

**Style alignment:** ✅ Complete (Python, TypeScript)
