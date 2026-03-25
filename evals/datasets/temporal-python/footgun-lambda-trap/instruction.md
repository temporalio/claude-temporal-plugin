Build a data transformation workflow using Temporal in Python. The workflow should
accept a number and a transformation type ("double" or "square"), apply the
transformation via an activity, and return "Result: {value}".

Implement this in transform.py with a workflow named "TransformWorkflow".
Add a runnable main block that runs the workflow with number=5 and
transformation="double", and prints the result.

Running `uv run python transform.py` should print:
Result: 10

The temporal dev server is available on this system, but you may need to add
dependencies to this project.
