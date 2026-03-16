Build a deduplication workflow using Temporal in Python. The workflow should accept
a list of items (which may contain duplicates), pass it to an activity that removes
duplicates, and return the unique items. The workflow should return the unique items
as a Python set.

Implement this in dedupe.py with a workflow named "DedupeWorkflow" that takes a list
of strings as input and returns a set of unique strings. Add a runnable main block that
runs the workflow with ["apple", "banana", "apple", "cherry", "banana"] and prints
whether the result is a set and its contents.

Running `uv run python dedupe.py` should print:
Result is a set: True
Items: {'apple', 'banana', 'cherry'}

(The order of items in the set output may vary)

The temporal dev server is available on this system, but you may need to add
dependencies to this project.
