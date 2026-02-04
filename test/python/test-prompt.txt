Create a complete Temporal workflow application in Python that demonstrates a greeting workflow.

Requirements:
1. Create a workflow that takes a name parameter and returns a greeting message
2. Create an activity that formats the greeting
3. Include a worker that registers the workflow and activity
4. Include a client that starts the workflow, with a given name passed via the CLI, e.g. `python client.py Jake`
5. Use proper async/await patterns
6. Include type hints on all function signatures
7. Use the latest version of the temporalio package
8. Create these files in the current directory (not in a subdirectory):
   - workflows.py
   - activities.py
   - worker.py
   - client.py
   - requirements.txt
9. Add a signal handler to the workflow that can update the greeting style
10. Add a query handler to get the current greeting count

The application should be production-ready with proper error handling and best practices.
