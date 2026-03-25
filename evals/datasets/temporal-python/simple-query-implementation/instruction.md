Implement a Temporal workflow in Python that maintains a counter with signal and query handlers.
The workflow should be named "CounterWorkflow" and should take no input.
It should:
1. Maintain an internal counter starting at 0
2. Define a signal handler named "increment" (no payload) that increases the counter by 1
3. Define a query handler named "get_count" that returns the current counter value as an integer
4. Wait indefinitely (until cancelled) using workflow.wait_condition with a condition that never becomes true

This should all be defined in the file counter.py.

Additionally, add an if __name__ == "__main__" block that:
1. Starts a worker that listens on the task queue "counter-task-queue"
2. Starts the workflow
3. Queries and prints the initial count (should be 0)
4. Sends three increment signals, querying and printing the count after each one
5. Cancels the workflow

The output should show the counter incrementing: 0, then 1, then 2, then 3.
Your code should be runnable with `uv run python counter.py`.

The temporal CLI is already installed in this system, but you may need to add dependencies to this project.
