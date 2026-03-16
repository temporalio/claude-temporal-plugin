Implement a Temporal workflow in Python that uses an activity to compute a greeting.
The workflow should be named "GreetingWorkflow" and should take a name as input.
It should then call an activity defined as compute_greeting to compute the greeting "Hello, {name}!".
The workflow should then return the greeting as its result.

This should all be defined in the file greeting.py.

Additionally, add an if __name__ == "__main__" block that starts a worker that listens on the task queue "greeting-task-queue",
runs the workflow with the first CLI argument as the name, and prints the result to the console.
Your code should be runnable with `uv run python greeting.py <NAME>`.

The temporal CLI is already installed in this system, but you may need to add dependencies to this project.
