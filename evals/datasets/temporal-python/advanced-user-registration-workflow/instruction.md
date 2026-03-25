Create a Temporal workflow in Python that manages user registration. The workflow should:

1. Receive an email address as input
2. Look up in a SQLite table (named 'users') whether a user with that email already exists
3. If the user does not exist, insert the user into the table
4. Return true if the user was inserted, false otherwise (if user already existed)

Requirements:
- Write all code in a single file called user_workflow.py
- The SQLite database should be stored in a file called users.db
- The users table should have at minimum an 'email' column
- Initialize the database and table if they don't exist when the workflow runs
- The workflow should be runnable with `uv run python user_workflow.py <email_address>`
- Print the result (true/false) to stdout

The temporal dev server is available on this system, but you may need to add
dependencies to this project.
