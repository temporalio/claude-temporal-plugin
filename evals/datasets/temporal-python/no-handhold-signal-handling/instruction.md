Create a Temporal workflow in Python that waits for an external signal before completing.

Implement this in approval.py with a workflow named "ApprovalWorkflow" that waits for an "approval" signal (boolean), then returns "APPROVED" or "REJECTED".

Running `uv run python approval.py` should print `APPROVED`.

The temporal dev server is available on this system, but you may need to add dependencies to this project.
