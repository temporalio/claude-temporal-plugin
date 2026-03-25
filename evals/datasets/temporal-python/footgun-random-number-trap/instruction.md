Build a lottery workflow using Temporal in Python. The workflow should generate a
random winning number between 1 and 100 (inclusive) and return "Winning number: {n}"
where n is the generated number.

Implement this in lottery.py with a workflow named "LotteryWorkflow" that takes no input.
Add a runnable main block that starts the workflow and prints the result.

Running `uv run python lottery.py` should print something like:
Winning number: 42

The temporal dev server is available on this system, but you may need to add
dependencies to this project.
