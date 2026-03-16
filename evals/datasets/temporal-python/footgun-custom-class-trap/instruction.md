Build a user processing workflow using Temporal in Python. Define a User class with
name and email fields. The workflow should accept a User object, pass it to a
"greet_user" activity, and return a welcome message in the format
"Welcome, {name} ({email})!".

Implement this in user_processor.py with a workflow named "UserWorkflow".
Add a runnable main block that creates a User("Alice", "alice@example.com"),
starts the workflow, and prints the result.

Running `uv run python user_processor.py` should print:
Welcome, Alice (alice@example.com)!

The temporal dev server is available on this system, but you may need to add
dependencies to this project.
