Create a string transformation pipeline using Temporal in Python that processes text through multiple steps.

Implement this in pipeline.py with a workflow named "PipelineWorkflow" that chains three activities: uppercase, add prefix "START-", add suffix "-END".

Running `uv run python pipeline.py hello` should print `START-HELLO-END`.

The temporal dev server is available on this system, but you may need to add dependencies to this project.
