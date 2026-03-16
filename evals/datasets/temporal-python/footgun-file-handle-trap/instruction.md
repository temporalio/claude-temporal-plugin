Build a file processing workflow using Temporal in Python. The workflow should accept
a file path as input, then use an activity to count the number of lines in the file
and return "File has {n} lines".

Implement this in file_processor.py with a workflow named "FileWorkflow".
Add a runnable main block that creates a test file with 5 lines, starts the workflow
with the file path, and prints the result.

Running `uv run python file_processor.py` should print:
File has 5 lines

The temporal dev server is available on this system, but you may need to add
dependencies to this project.
