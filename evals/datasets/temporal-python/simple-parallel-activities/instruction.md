Implement a Temporal workflow in Python that executes multiple activities in parallel.
The workflow should be named "ParallelWorkflow" and should take no input.
It should execute three activities in parallel:
- "get_a" - returns the string "A"
- "get_b" - returns the string "B"
- "get_c" - returns the string "C"

The workflow should concatenate the results in order (A, B, C) and return "ABC".
The activities must execute in parallel, not sequentially.

This should all be defined in the file parallel.py.

Additionally, add an if __name__ == "__main__" block that starts a worker that listens on the task queue "parallel-task-queue",
runs the workflow, and prints the result to the console.
Your code should be runnable with `uv run python parallel.py`.
Running `uv run python parallel.py` should print `ABC`.

The temporal CLI is already installed in this system, but you may need to add dependencies to this project.
