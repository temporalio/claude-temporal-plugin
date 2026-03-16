Build an order processing workflow using Temporal in Python. When an order is placed,
the workflow should generate a unique order ID (UUID format), then return a confirmation
message in the format "Order {order_id} confirmed" where order_id is the generated UUID.

Implement this in order.py with a workflow named "OrderWorkflow" that takes no input.
Add a runnable main block that starts the workflow and prints the confirmation.

Running `uv run python order.py` should print something like:
Order 550e8400-e29b-41d4-a716-446655440000 confirmed

The temporal dev server is available on this system, but you may need to add
dependencies to this project.
