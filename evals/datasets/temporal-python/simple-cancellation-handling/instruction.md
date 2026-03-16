Implement a Temporal workflow in Python that handles cancellation gracefully.
The workflow should be named "CancellableWorkflow" and should take no input.

The workflow should:
1. Perform iterations with a short delay between each (e.g., 0.1 seconds using workflow.sleep)
2. Track the number of completed iterations
3. Handle cancellation by catching asyncio.CancelledError
4. When cancelled, return "Cancelled after {N} iterations" where N is the number of completed iterations
5. If it completes all 100 iterations without cancellation, return "Completed all iterations"

This should all be defined in the file cancellable.py.

Additionally, add an if __name__ == "__main__" block that:
1. Starts a worker that listens on the task queue "cancellable-task-queue"
2. Starts the workflow
3. Waits for 0.5 seconds
4. Cancels the workflow
5. Gets the result and prints it to the console

Your code should be runnable with `uv run python cancellable.py`.
Running `uv run python cancellable.py` should print something like `Cancelled after N iterations` where N is a small number.

The temporal CLI is already installed in this system, but you may need to add dependencies to this project.
