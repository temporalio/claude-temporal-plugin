Build a data analysis workflow using Temporal in Python. The workflow should accept
a pandas DataFrame, pass it to an activity that calculates the sum of the "value"
column, and return "Total: {sum}".

Implement this in analysis.py with a workflow named "AnalysisWorkflow".
Add a runnable main block that creates a DataFrame with a "value" column containing
[10, 20, 30, 40], starts the workflow, and prints the result.

Running `uv run python analysis.py` should print:
Total: 100

The temporal dev server is available on this system, but you may need to add
dependencies to this project.
