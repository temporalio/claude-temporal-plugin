Build a file info workflow using Temporal in Python. The workflow should accept a
file path, pass it to an activity that checks whether the path exists on disk,
and return "Path exists: True" or "Path exists: False".

Implement this in pathcheck.py with a workflow named "PathCheckWorkflow".
Add a runnable main block that creates a test file, starts the workflow with its path,
and prints the result.

Running `uv run python pathcheck.py` should print:
Path exists: True

The temporal dev server is available on this system, but you may need to add
dependencies to this project.
