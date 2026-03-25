Implement a Temporal workflow in Python that demonstrates signal handling.
The workflow should be named "ApprovalWorkflow" and should take no input.
It should:
1. Define a signal handler named "approval" that accepts a boolean value
2. Wait for the approval signal to be received
3. Return "APPROVED" if the signal value is True, or "REJECTED" if False

This should all be defined in the file approval.py.

Additionally, add an if __name__ == "__main__" block that:
1. Starts a worker that listens on the task queue "approval-task-queue"
2. Starts the workflow
3. Sends an approval signal with value True
4. Waits for the workflow result and prints it to the console

Your code should be runnable with `uv run python approval.py`.
Running `uv run python approval.py` should print `APPROVED`.

The temporal CLI is already installed in this system, but you may need to add dependencies to this project.
