# ai-patterns.md

Correctness verification for `references/python/ai-patterns.md` (Python only).

## Python

**File:** `references/python/ai-patterns.md` (relative to skill root)

### Tracking

| # | Section | Status | Fix Applied | Sources |
|---|---------|--------|-------------|---------|
| 1 | Overview | needs fixes | | context7 sdk-python |
| 2 | Pydantic Data Converter Setup | needs fixes | | context7 sdk-python |
| 3 | OpenAI Client Configuration | all good | | context7 openai-python, temporal-docs |
| 4 | LiteLLM Configuration | all good | | litellm docs |
| 5 | Generic LLM Activity | all good | | context7 sdk-python |
| 6 | Activity Retry Policy | all good | | context7 sdk-python |
| 7 | Tool-Calling Agent Workflow | needs fixes | | context7 sdk-python |
| 8 | Structured Outputs | needs fixes | | context7 openai-python |
| 9 | Multi-Agent Pipeline | all good | | context7 sdk-python |
| 10 | OpenAI Agents SDK Integration | needs fixes | | context7 sdk-python |
| 11 | Best Practices | all good | | context7 sdk-python |

### Detailed Notes

#### 1. Overview
**Status:** needs fixes

**Issues:**
- Reference path `references/core/ai-integration.md` is INCORRECT - file does not exist
- Correct path should be `references/core/ai-patterns.md`

---

#### 2. Pydantic Data Converter Setup
**Status:** needs fixes

**Issues:**
- Import and converter name are correct (`from temporalio.contrib.pydantic import pydantic_data_converter`)
- `Client.connect()` with `data_converter` parameter placement needs verification
- Claim about "complex types like OpenAI response objects" is misleading - Pydantic converter is for Pydantic models that WRAP responses, not raw OpenAI response objects

---

#### 3. OpenAI Client Configuration
**Status:** all good

**Verified:**
- `AsyncOpenAI` import from `openai` ✓
- `max_retries=0` recommendation is valid and explicitly recommended by Temporal docs ✓
- `timeout` parameter accepts float value in seconds ✓

---

#### 4. LiteLLM Configuration
**Status:** all good

**Verified:**
- `litellm.num_retries = 0` is correct module-level variable for disabling retries ✓

---

#### 5. Generic LLM Activity
**Status:** all good

**Verified:**
- `@activity.defn` decorator ✓
- `ApplicationError` import from `temporalio.exceptions` ✓
- `non_retryable=True` parameter ✓
- `next_retry_delay` parameter for rate limits ✓
- All OpenAI exception types exist (AuthenticationError, RateLimitError, APIStatusError, APIConnectionError) ✓
- Pydantic `BaseModel` usage ✓

---

#### 6. Activity Retry Policy
**Status:** all good

**Verified:**
- `workflow.unsafe.imports_passed_through()` context manager ✓
- `workflow.execute_activity()` API ✓
- `start_to_close_timeout` parameter ✓
- Note about automatic retry behavior is accurate ✓

**Note:** Unused `RetryPolicy` import is technically unnecessary but not incorrect.

---

#### 7. Tool-Calling Agent Workflow
**Status:** needs fixes

**Issues:**
- `@workflow.defn`, `@workflow.run`, `workflow.execute_activity()` patterns are all correct
- **Message accumulation pattern is problematic:**
  - Code converts `messages` list to string: `current_input = f"Tool results: {messages}"`
  - This loses proper message structure expected by OpenAI API
  - Missing assistant's message with tool calls before tool results
  - `LLMRequest` model should accept `messages` list, not just `user_input`

**Recommended:** Either modify `LLMRequest` to accept messages list, or use `temporalio.contrib.openai_agents` integration.

---

#### 8. Structured Outputs
**Status:** needs fixes

**Issues:**
- `openai_client.beta.chat.completions.parse()` is INCORRECT
- Correct API: `openai_client.chat.completions.parse()` (no `beta` prefix)
- `response_format=AnalysisResult` (Pydantic model) is correct ✓
- `response.choices[0].message.parsed` returns Pydantic instance is correct ✓

---

#### 9. Multi-Agent Pipeline
**Status:** all good

**Verified:**
- `asyncio.gather(*tasks, return_exceptions=True)` pattern ✓
- `schedule_to_close_timeout` vs `start_to_close_timeout` usage together is valid ✓
- Parallel activity execution pattern ✓
- Partial failure handling with `isinstance(r, Exception)` filter ✓

---

#### 10. OpenAI Agents SDK Integration
**Status:** needs fixes

**Issues:**
- `from temporalio.contrib.openai import create_workflow_agent` is INCORRECT
- `create_workflow_agent()` function does NOT exist
- Correct module is `temporalio.contrib.openai_agents`
- Correct API uses `OpenAIAgentsPlugin` as a client plugin:
  ```python
  from temporalio.contrib.openai_agents import OpenAIAgentsPlugin, ModelActivityParameters
  client = await Client.connect(..., plugins=[OpenAIAgentsPlugin(...)])
  ```
- `Agent`, `Runner` imports from `agents` are correct ✓
- "Automatically dispatches to activities for LLM calls" claim is accurate ✓

---

#### 11. Best Practices
**Status:** all good

**Verified:**
- All 8 best practices are valid ✓
- "Disable retries in LLM clients" recommendation is correct - prevents double-retry with Temporal ✓

---

