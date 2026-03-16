Implement a Temporal workflow in Python that transforms a string using multiple activities executed in sequence.
The workflow should be named "PipelineWorkflow" and should take a string as input.
It should execute three activities in sequence:
1. "to_uppercase" - converts the string to uppercase
2. "add_prefix" - adds "START-" prefix to the string
3. "add_suffix" - adds "-END" suffix to the string

For example, input "hello" should produce output "START-HELLO-END".

This should all be defined in the file pipeline.py.

Additionally, add an if __name__ == "__main__" block that starts a worker that listens on the task queue "pipeline-task-queue",
runs the workflow with the first CLI argument as the input string, and prints the result to the console.
Your code should be runnable with `uv run python pipeline.py <STRING>`.
For example, `uv run python pipeline.py hello` should print `START-HELLO-END`.

The temporal CLI is already installed in this system, but you may need to add dependencies to this project.
