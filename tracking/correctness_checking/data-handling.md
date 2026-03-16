# data-handling.md

Correctness verification for `references/{language}/data-handling.md`.

## TypeScript

**File:** `references/typescript/data-handling.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Overview | all good | | context7 sdk-typescript |
| 2 | Default Data Converter | FIXED | Clarified Protobuf requires custom converter | context7 sdk-typescript |
| 3 | Custom Data Converter | FIXED | Uses payloadConverterPath pattern | context7 sdk-typescript |
| 4 | Payload Codec (Encryption) | FIXED | Changed to payloadCodecs (plural, array) | context7 sdk-typescript |
| 5 | Search Attributes | all good | | context7 sdk-typescript |
| 6 | Workflow Memo | all good | | context7 sdk-typescript |
| 7 | Protobuf Support | all good | | context7 sdk-typescript |
| 8 | Large Payloads | FIXED | Import already present | context7 sdk-typescript |
| 9 | Best Practices | all good | | context7 sdk-typescript |

### Detailed Notes

#### 1. Overview
**Status:** all good

**Verified:** Data converter role description is accurate

---

#### 2. Default Data Converter
**Status:** FIXED

**Fixed:** Removed misleading Protobuf claim, added note that Protobuf requires `DefaultPayloadConverterWithProtobufs`.

---

#### 3. Custom Data Converter
**Status:** FIXED

**Fixed:** Uses `payloadConverterPath: require.resolve()` pattern, added Payload import, uses generic `<T>`.

---

#### 4. Payload Codec (Encryption)
**Status:** FIXED

**Fixed:** Changed `payloadCodec` to `payloadCodecs` (plural, as array).

---

#### 5. Search Attributes
**Status:** all good

**Verified:** searchAttributes option, array format, upsertSearchAttributes, workflowInfo().searchAttributes, client.workflow.list, query syntax all correct

---

#### 6. Workflow Memo
**Status:** all good

**Verified:** memo option, workflowInfo().memo, distinction from search attributes all correct

---

#### 7. Protobuf Support
**Status:** all good

**Verified:** Import path `@temporalio/common/lib/protobufs` and `protobufRoot` option are correct

---

#### 8. Large Payloads
**Status:** FIXED

**Fixed:** Import already present in current file (verified correct).

---

#### 9. Best Practices
**Status:** all good

**Verified:** All 6 best practices are valid and aligned with SDK documentation

---


## Python

**File:** `references/python/data-handling.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Overview | all good | | context7 sdk-python |
| 2 | Default Data Converter | all good | | context7 sdk-python |
| 3 | Pydantic Integration | all good | | context7 sdk-python |
| 4 | Custom Data Conversion | all good | | context7 sdk-python, samples-python |
| 5 | Payload Encryption | needs fixes | | context7 sdk-python |
| 6 | Search Attributes | needs fixes | | context7 sdk-python, sdk source |
| 7 | Querying Workflows by Search Attributes | all good | | context7 sdk-python, temporal-docs |
| 8 | Workflow Memo | needs fixes | | context7 sdk-python, sdk source |
| 9 | Large Payloads | all good | | temporal-docs |
| 10 | Deterministic APIs for Values | all good | | context7 sdk-python, sdk source |
| 11 | Best Practices | all good | | context7 sdk-python, temporal-docs |

### Detailed Notes

#### 1. Overview
**Status:** all good

**Verified:**
- Data converter role description is accurate ✓

---

#### 2. Default Data Converter
**Status:** all good

**Verified:**
- Supported types list is accurate (intentionally simplified) ✓
- `None`, `bytes`, Protobuf messages, JSON-serializable types all correct ✓
- SDK actually supports additional types (dataclasses, UUID, datetime) but examples listed are correct ✓

---

#### 3. Pydantic Integration
**Status:** all good

**Verified:**
- `pydantic.BaseModel` subclass as workflow input/output type ✓
- `pydantic_data_converter` import from `temporalio.contrib.pydantic` ✓
- Client configuration with `data_converter=pydantic_data_converter` ✓
- Automatic validation claim is accurate ✓

---

#### 4. Custom Data Conversion
**Status:** all good

**Verified:**
- `EncodingPayloadConverter` and `CompositePayloadConverter` approach is correct ✓
- Both sample URLs are valid and accessible ✓

---

#### 5. Payload Encryption
**Status:** needs fixes

**Issues:**
- `PayloadCodec` import from `temporalio.converter` is correct ✓
- `Payload` import from `temporalio.api.common.v1` is correct ✓
- `encode()` and `decode()` methods are correct ✓
- `Sequence[Payload]` parameter and `list[Payload]` return type are correct ✓
- `DataConverter(payload_codec=...)` configuration is correct ✓
- **`asyncio.to_thread()` usage is NOT in official samples** - official encryption sample calls crypto synchronously
- Missing `import asyncio` if keeping `asyncio.to_thread()` pattern
- The pattern is a valid optimization but not official - should add note or align with official samples

---

#### 6. Search Attributes
**Status:** needs fixes

**Issues:**
- Imports from `temporalio.common` are correct ✓
- `SearchAttributeKey.for_keyword()`, `.for_float()`, `.for_datetime()` factory methods are correct ✓
- `client.start_workflow()` with `search_attributes=TypedSearchAttributes([...])` is correct ✓
- **`workflow.upsert_search_attributes()` API is INCORRECT:**
  - Document shows: `workflow.upsert_search_attributes(TypedSearchAttributes([SearchAttributePair(...)]))`
  - Correct API: `workflow.upsert_search_attributes([KEY.value_set(value)])`
  - Function takes `Sequence[SearchAttributeUpdate]`, not `TypedSearchAttributes`
  - Use `.value_set()` or `.value_unset()` on `SearchAttributeKey`

---

#### 7. Querying Workflows by Search Attributes
**Status:** all good

**Verified:**
- `client.list_workflows(query)` API ✓
- Query string syntax with `=`, `OR` operators ✓
- Async iteration over results ✓

---

#### 8. Workflow Memo
**Status:** needs fixes

**Issues:**
- `memo` parameter type is correct (dict works as Mapping) ✓
- "Not searchable" distinction is correctly stated ✓
- **`workflow.memo_value()` signature is incomplete:**
  - Document shows: `workflow.memo_value("key", type_hint=Type)`
  - Missing `default` parameter: `workflow.memo_value(key, default=..., type_hint=...)`
  - Without default, `KeyError` is raised if key missing
  - Should document: `workflow.memo_value("key", default="", type_hint=str)`

---

#### 9. Large Payloads
**Status:** all good

**Verified:**
- External storage pattern (S3/GCS) ✓
- Payload Codec compression suggestion ✓
- Chunking suggestion ✓
- Reference pattern code example is correct ✓

---

#### 10. Deterministic APIs for Values
**Status:** all good

**Verified:**
- `workflow.uuid4()` returns deterministic UUID based on `random()` ✓
- `workflow.random()` returns deterministically-seeded pseudo-RNG ✓
- `rng.randint(a, b)` API works (returns Python's `random.Random` class) ✓
- "Same on replay" claim is accurate - both are deterministically-seeded ✓

---

#### 11. Best Practices
**Status:** all good

**Verified:**
- All 6 best practices are valid ✓
- 2MB payload recommendation matches Temporal Cloud limits ✓
- `workflow.uuid4()` and `workflow.random()` recommendation is correct ✓

---


## PHP

**File:** `references/php/data-handling.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Overview | all good | | context7 sdk-php |
| 2 | Default Data Converter | all good | | context7 sdk-php |
| 3 | Custom Data Converter | needs verification | | context7 sdk-php |
| 4 | Payload Encryption | needs verification | | context7 sdk-php |
| 5 | Search Attributes | FIXED | `TypedSearchAttributes::new()->withSearchAttribute()`, `->valueSet()` | context7 sdk-php |
| 6 | Workflow Memo | needs verification | | context7 sdk-php |
| 7 | Best Practices | all good | | context7 sdk-php |

### Detailed Notes

#### 1. Overview
**Status:** all good

**Verified:**
- Data converter role description is accurate
- JSON as default format is correct

---

#### 2. Default Data Converter
**Status:** all good

**Verified:**
- Supported types (null, scalars, arrays, objects) are correct
- `#[ReturnType]` attribute usage on workflow interface methods is correct
- Import `Temporal\Workflow\ReturnType` is consistent with SDK conventions
- Explanation that generators need `#[ReturnType]` for deserialization is correct

---

#### 3. Custom Data Converter
**Status:** needs verification

**Issues:**
- **`PayloadConverter` interface name could not be fully verified** -- the reference uses `implements PayloadConverter` but the actual interface may be `PayloadConverterInterface`. Context7 docs do not include custom PayloadConverter examples for PHP SDK.
- Method signatures (`getEncodingType()`, `toPayload()`, `fromPayload()`) are plausible but could not be confirmed against source.
- `DataConverter` constructor taking multiple converters is plausible but unverified.
- `WorkflowClient::create()` with `dataConverter:` named parameter is plausible.

**Note:** Unable to verify custom data converter PHP-specific API due to limited documentation availability.

---

#### 4. Payload Encryption
**Status:** needs verification

**Issues:**
- **`PayloadCodecInterface` name could not be fully verified** -- the reference uses `implements PayloadCodecInterface` which is plausible but unconfirmed.
- `encode(array $payloads): array` and `decode(array $payloads): array` signatures are plausible.
- `DataConverter::createDefault()->withCodec(...)` pattern is plausible but unverified.

**Note:** Unable to verify PayloadCodec PHP-specific API due to limited documentation availability.

---

#### 5. Search Attributes
**Status:** needs fixes

**Issues:**
- **Wrong import path for `SearchAttributeKey`:**
  - Reference uses: `use Temporal\Common\SearchAttributeKey;`
  - Correct (per Context7): `use Temporal\Common\SearchAttributes\SearchAttributeKey;`
  - The class lives in the `SearchAttributes` sub-namespace
- **Wrong method on `TypedSearchAttributes` for setting initial values:**
  - Reference uses: `TypedSearchAttributes::empty()->withValue($key, $value)`
  - Correct (per Context7): `TypedSearchAttributes::new()->withSearchAttribute($key, $value)`
  - Factory method is `new()` not `empty()`
  - Setter method is `withSearchAttribute()` not `withValue()`
- **Wrong method for upserting search attributes inside workflow:**
  - Reference uses: `SearchAttributeKey::forKeyword('OrderStatus')->withValue('completed')`
  - Correct (per Context7): `SearchAttributeKey::forKeyword('OrderStatus')->valueSet('completed')`
  - Method is `valueSet()` not `withValue()`
- The `Workflow::upsertTypedSearchAttributes()` call itself is correct (takes variadic search attribute updates)
- `SearchAttributeKey::forKeyword()` factory method is correct
- `$client->listWorkflowExecutions()` query API appears correct

---

#### 6. Workflow Memo
**Status:** needs verification

**Issues:**
- `WorkflowOptions::new()->withMemo([...])` for setting memo at start is plausible but not verified in Context7 docs
- **`Workflow::upsertMemo()` could not be verified** -- Context7 does not include examples of upserting memo in PHP SDK. This method may or may not exist.

**Note:** Unable to verify memo PHP-specific API due to limited documentation availability.

---

#### 7. Best Practices
**Status:** all good

**Verified:**
- All 4 best practices are valid
- `#[ReturnType]` recommendation is correct
- PayloadCodec for encryption recommendation is correct
- Typed Search Attributes recommendation is correct

---

