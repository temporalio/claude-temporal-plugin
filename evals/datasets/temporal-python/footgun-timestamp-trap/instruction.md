Build a task tracking workflow using Temporal in Python. When a task is started,
the workflow should record the current timestamp (ISO format) when processing began,
then simulate a 2-second processing delay, and return "Started at {timestamp}".

Implement this in tracker.py with a workflow named "TrackerWorkflow" that takes no input.
Add a runnable main block that starts the workflow and prints the result.

Running `uv run python tracker.py` should print something like:
Started at 2024-01-15T10:30:45.123456

The temporal dev server is available on this system, but you may need to add
dependencies to this project.
