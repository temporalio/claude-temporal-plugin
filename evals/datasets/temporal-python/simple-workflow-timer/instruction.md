Implement a Temporal workflow in Python that waits for a specified duration before completing.
The workflow should be named "TimerWorkflow" and should take an integer (delay_seconds) as input.
It should use Temporal's timer functionality to wait for the specified number of seconds,
then return the string "Completed after {delay_seconds} seconds".

This should all be defined in the file timer.py.

Additionally, add an if __name__ == "__main__" block that starts a worker that listens on the task queue "timer-task-queue",
runs the workflow with the first CLI argument as the delay in seconds, and prints the result to the console.
Your code should be runnable with `uv run python timer.py <SECONDS>`.
For example, `uv run python timer.py 2` should print `Completed after 2 seconds`.

The temporal CLI is already installed in this system, but you may need to add dependencies to this project.
