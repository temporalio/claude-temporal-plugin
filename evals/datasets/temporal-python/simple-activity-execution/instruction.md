Implement a Temporal workflow in Python that uses an activity to add two numbers.
The workflow should be named "CalculatorWorkflow" and should take two integers as input.
It should call an activity named "add_numbers" to compute the sum, and return the result.

This should all be defined in the file calculator.py.

Additionally, add an if __name__ == "__main__" block that starts a worker that listens on the task queue "calculator-task-queue",
runs the workflow with the two CLI arguments as the numbers, and prints the result to the console.
Your code should be runnable with `uv run python calculator.py <NUM1> <NUM2>`.
For example, `uv run python calculator.py 5 3` should print `8`.

The temporal CLI is already installed in this system, but you may need to add dependencies to this project.
