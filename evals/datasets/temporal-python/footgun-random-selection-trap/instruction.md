Build a load balancer workflow using Temporal in Python. The workflow should randomly
select one of three servers ["server-a", "server-b", "server-c"] and return
"Routed to {server}" where server is the selected server name.

Implement this in loadbalancer.py with a workflow named "LoadBalancerWorkflow" that takes no input.
Add a runnable main block that starts the workflow and prints the result.

Running `uv run python loadbalancer.py` should print something like:
Routed to server-b

The temporal dev server is available on this system, but you may need to add
dependencies to this project.
