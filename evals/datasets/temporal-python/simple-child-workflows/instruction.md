Implement a Temporal parent workflow in Python that executes multiple child workflows.

Define two workflows:
1. "ChildWorkflow" - takes a task_number (integer) as input and returns "Task {task_number} complete"
2. "ParentWorkflow" - takes a count (integer) as input, executes {count} child workflows for tasks 1 through {count} concurrently, and returns a list of all child workflow results

For example, with count=3, the parent should execute child workflows for tasks 1, 2, and 3 concurrently,
and return ["Task 1 complete", "Task 2 complete", "Task 3 complete"].

This should all be defined in the file parent_child.py.

Additionally, add an if __name__ == "__main__" block that starts a worker that listens on the task queue "parent-task-queue",
runs the parent workflow with the first CLI argument as the count, and prints each result on a separate line.
Your code should be runnable with `uv run python parent_child.py <COUNT>`.
For example, `uv run python parent_child.py 3` should print:
Task 1 complete
Task 2 complete
Task 3 complete

The temporal CLI is already installed in this system, but you may need to add dependencies to this project.
