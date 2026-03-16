Create a multi-step workflow using Temporal in Python that orchestrates 3 or more
sequential activities with distinct processing steps (e.g., data validation,
processing, and notification). Include comprehensive logging at each step so the
workflow's progress can be traced.

The workflow should accept an input string and process it through the activity chain.

Write all code in a single file called run_workflow.py. It should be runnable with:
`uv run python run_workflow.py "test input"`

The program should print output showing each step's execution and the final result.

The temporal dev server is available on this system, but you may need to add
dependencies to this project.
