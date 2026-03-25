Create an order management system using Temporal in Python with a distributed queue
workflow. The system should support:

- Push: Add an order to the queue (each order has order_id, item_name, quantity)
- Pop: Remove and return the next order from the queue
- GetQueueLength: Return the current number of orders in the queue
- GetAllOrders: Return all orders currently in the queue

The workflow should run indefinitely, allowing multiple clients to interact with it.

Create two files:
- worker.py: Contains the workflow definition and starts the worker
- example_client.py: Demonstrates pushing orders, querying the queue, and popping orders

Running `uv run python example_client.py` should demonstrate the full lifecycle
(push some orders, check length, get all, pop one).

The temporal dev server is available on this system, but you may need to add
dependencies to this project.
