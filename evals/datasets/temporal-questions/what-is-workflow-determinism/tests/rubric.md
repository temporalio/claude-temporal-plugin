You are grading an answer about Temporal workflow determinism. Score from 0.0 to 1.0.

A perfect answer (1.0) should cover ALL of these key concepts:
1. **Replay mechanism**: Temporal replays workflow code from event history to reconstruct state. The same code must produce the same commands on replay.
2. **Why it matters**: Non-deterministic code produces different results on replay, causing "non-determinism detected" errors and workflow failure.
3. **Common violations**: At least 3 of: random numbers, current time/dates, UUIDs, threading/goroutines, network calls, file I/O, global mutable state, non-deterministic iteration order.
4. **Workarounds**: Use activities for side effects, use SDK-provided deterministic APIs (e.g., workflow.now(), workflow.random()), use SideEffect/MutableSideEffect for small non-deterministic values.

Scoring guide:
- 1.0: Covers all 4 areas accurately with good depth
- 0.75: Covers 3 of 4 areas well, or all 4 with minor gaps
- 0.5: Covers 2 of 4 areas, or has some inaccuracies
- 0.25: Covers 1 area, or is mostly vague/inaccurate
- 0.0: Missing answer, completely wrong, or off-topic
