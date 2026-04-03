# data-handling.md

## Section Inventory

| Section | Core | Python | Py# | TypeScript | TS# | Java | J# | Go | Go# |
|---------|------|--------|-----|------------|-----|------|----|----|-----|
| Overview | — | ✓ | 1 | ✓ | 1 | TODO | 1 | ✓ | 1 |
| Default Data Converter | — | ✓ | 2 | ✓ | 2 | TODO | 2 | ✓ | 2 |
| Pydantic Integration | — | ✓ | 3 | — | — | — | — | — | — |
| Jackson Integration | — | — | — | — | — | TODO | 3 | — | — |
| Custom Data Converter | — | ✓ | 4 | ✓ | 3 | TODO | 4 | ✓ | 3 |
| Composition of Payload Converters | — | — | — | ✓ | 4 | TODO | 5 | ✓ | 4 |
| Protobuf Support | — | — | — | ✓ | 5 | TODO | 6 | ✓ | 5 |
| Payload Encryption | — | ✓ | 5 | ✓ | 6 | TODO | 7 | ✓ | 6 |
| Search Attributes | — | ✓ | 6 | ✓ | 7 | TODO | 8 | ✓ | 7 |
| Workflow Memo | — | ✓ | 7 | ✓ | 8 | TODO | 9 | ✓ | 8 |
| Large Payloads | — | — | — | — | — | — | — | — | — |
| Deterministic APIs for Values | — | ✓ | 8 | — | — | TODO | 10 | — | — |
| Best Practices | — | ✓ | 9 | ✓ | 9 | TODO | 11 | ✓ | 9 |

## Style Compliance

| Language | Status | Notes |
|----------|--------|-------|
| Python | ✓ reference | — |
| TypeScript | ✓ aligned | — |
| Java | — | Not started |
| Go | ✓ aligned | JSON default, protobuf native, converter.CompositeDataConverter |

## Status

**Java column decisions:**
- Default Data Converter: Java uses Jackson JSON by default (Null, byte[], Protobuf JSON, JSON)
- Pydantic Integration: — (Python-specific; Java equivalent is Jackson Integration)
- Jackson Integration: Java-specific — `JacksonJsonPayloadConverter` for custom ObjectMapper config
- Custom Data Converter: Java has `PayloadConverter` interface, `DefaultDataConverter.withPayloadConverterOverrides()`
- Composition of Payload Converters: Java supports this (like TS) via `DefaultDataConverter`
- Protobuf Support: Java has built-in Protobuf support (like TS)
- Payload Encryption: Java has `PayloadCodec` + `CodecDataConverter`
- Deterministic APIs for Values: Java has `Workflow.newRandom()`, `Workflow.randomUUID()`, `Workflow.currentTimeMillis()` (like Python)

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
- Pydantic Integration: Python-specific (Java equivalent is Jackson Integration)
- Jackson Integration: Java-specific (custom ObjectMapper, type handling)
- Deterministic APIs for Values: Python/Java-specific; TS V8 sandbox handles automatically; Go covers in determinism.md
- Large Payloads: Moved to core/patterns.md and core/gotchas.md

**Order alignment:** ✅ ALIGNED — Java follows Python order with Java-specific additions (Jackson Integration)

**Style alignment:** ✅ Complete (Python, TypeScript, Go). Java: ~11 sections planned.
