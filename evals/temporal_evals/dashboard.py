"""Generate a self-contained HTML dashboard comparing skill evals against baseline.

Usage:
    uv run --project evals eval-dashboard
    uv run --project evals eval-dashboard --out dashboard.html
"""

import argparse
import json
import subprocess
import webbrowser
from pathlib import Path

import yaml


def _load_yaml(path: Path):
    if not path.exists():
        return None
    return yaml.safe_load(path.read_text())


def _git_log_oneline(repo_root: Path, shas: list[str]) -> dict[str, str]:
    """Get short commit messages for a list of SHAs."""
    messages: dict[str, str] = {}
    for sha in shas:
        try:
            result = subprocess.run(
                ["git", "log", "--format=%s", "-1", sha],
                capture_output=True,
                text=True,
                cwd=repo_root,
            )
            if result.returncode == 0:
                messages[sha] = result.stdout.strip()
        except Exception:
            pass
    return messages


def _aggregate_score(tasks: dict) -> float:
    """Compute the mean of all per-check scores across tasks."""
    values = []
    for task_rewards in tasks.values():
        if isinstance(task_rewards, dict):
            values.extend(task_rewards.values())
    if not values:
        return 0.0
    return sum(values) / len(values)


def _build_data(evals_dir: Path):
    """Parse baseline.yaml and results.yaml into structured dashboard data.

    Keys everything by (dataset, agent, model) so multiple agent/model combos
    are tracked independently.
    """
    baseline_data = _load_yaml(evals_dir / "baseline.yaml") or []
    results_data = _load_yaml(evals_dir / "results.yaml") or {}

    # Index baseline by (dataset, agent, model)
    baseline_index: dict[tuple[str, str, str], dict] = {}
    for entry in baseline_data:
        key = (entry.get("dataset", ""), entry.get("agent", ""), entry.get("model", ""))
        baseline_index[key] = entry

    # Collect all unique (dataset, agent, model) combos across baseline + results
    combos: set[tuple[str, str, str]] = set(baseline_index.keys())
    for sha, entries in results_data.items():
        for entry in entries:
            combos.add((entry.get("dataset", ""), entry.get("agent", ""), entry.get("model", "")))

    # Collect datasets and agents
    datasets = sorted({c[0] for c in combos})
    agents = sorted({(c[1], c[2]) for c in combos})
    commits = list(results_data.keys())  # insertion order from YAML

    return baseline_index, results_data, datasets, agents, commits


def _render_html(evals_dir: Path, repo_root: Path) -> str:
    baseline_index, results_data, datasets, agents, commits = _build_data(evals_dir)
    commit_messages = _git_log_oneline(repo_root, commits)

    # Build JSON payload for the HTML.
    # Structure:
    # {
    #   datasets: [...],
    #   agents: [{name, model}, ...],
    #   baseline: { "dataset::agent::model": {tasks, aggregate} },
    #   commits: [ {sha, message, results: { "dataset::agent::model": {tasks, aggregate, skills} }} ]
    # }
    payload: dict = {"datasets": datasets, "agents": [], "baseline": {}, "commits": []}

    for agent_name, agent_model in agents:
        payload["agents"].append({"name": agent_name, "model": agent_model})

    for (ds, ag, mo), entry in baseline_index.items():
        tasks = entry.get("tasks", {})
        key = f"{ds}::{ag}::{mo}"
        payload["baseline"][key] = {
            "tasks": tasks,
            "aggregate": round(_aggregate_score(tasks), 4),
        }

    for sha in commits:
        commit_entry: dict = {
            "sha": sha,
            "message": commit_messages.get(sha, ""),
            "results": {},
        }
        for entry in results_data.get(sha, []):
            ds = entry.get("dataset", "")
            ag = entry.get("agent", "")
            mo = entry.get("model", "")
            key = f"{ds}::{ag}::{mo}"
            tasks = entry.get("tasks", {})
            commit_entry["results"][key] = {
                "tasks": tasks,
                "aggregate": round(_aggregate_score(tasks), 4),
                "skills": entry.get("skills", []),
            }
        payload["commits"].append(commit_entry)

    data_json = json.dumps(payload)

    return f"""\
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Temporal Skill Evals</title>
<style>
* {{ margin: 0; padding: 0; box-sizing: border-box; }}
body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif; background: #0d1117; color: #c9d1d9; padding: 24px; }}
h1 {{ font-size: 20px; font-weight: 600; margin-bottom: 4px; color: #e6edf3; }}
.subtitle {{ color: #7d8590; font-size: 13px; margin-bottom: 24px; }}
.section {{ margin-bottom: 32px; }}
.section-title {{ font-size: 15px; font-weight: 600; color: #e6edf3; margin-bottom: 12px; display: flex; align-items: center; gap: 8px; }}
.dataset-tag {{ background: #1f2937; border: 1px solid #30363d; border-radius: 12px; padding: 2px 10px; font-size: 12px; font-weight: 500; }}
.agent-tag {{ background: #1a1a2e; border: 1px solid #30363d; border-radius: 12px; padding: 2px 10px; font-size: 11px; font-weight: 500; color: #a78bfa; }}
table {{ border-collapse: collapse; width: 100%; font-size: 13px; }}
th, td {{ padding: 6px 12px; text-align: left; border-bottom: 1px solid #21262d; }}
th {{ color: #7d8590; font-weight: 500; font-size: 12px; text-transform: uppercase; letter-spacing: 0.5px; }}
tr:hover {{ background: #161b22; }}
.sha {{ font-family: 'SF Mono', 'Consolas', monospace; font-size: 12px; color: #58a6ff; }}
.msg {{ color: #7d8590; font-size: 12px; max-width: 220px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }}
.score {{ font-family: 'SF Mono', 'Consolas', monospace; font-weight: 600; }}
.score-perfect {{ color: #3fb950; }}
.score-good {{ color: #a5d6a7; }}
.score-mid {{ color: #d29922; }}
.score-low {{ color: #f85149; }}
.delta {{ font-size: 11px; margin-left: 4px; }}
.delta-pos {{ color: #3fb950; }}
.delta-neg {{ color: #f85149; }}
.delta-zero {{ color: #484f58; }}
.baseline-row {{ background: #161b22; }}
.baseline-label {{ color: #7d8590; font-style: italic; font-size: 12px; }}
.checks-grid {{ display: grid; grid-template-columns: repeat(auto-fill, minmax(140px, 1fr)); gap: 4px; margin-top: 4px; margin-bottom: 8px; }}
.check {{ display: flex; justify-content: space-between; padding: 3px 8px; border-radius: 4px; font-size: 12px; font-family: 'SF Mono', 'Consolas', monospace; }}
.check-pass {{ background: #0d2818; color: #3fb950; }}
.check-fail {{ background: #2d1117; color: #f85149; }}
.check-partial {{ background: #2a1f00; color: #d29922; }}
.task-name {{ font-family: 'SF Mono', 'Consolas', monospace; font-size: 12px; color: #7d8590; }}
.summary-cards {{ display: flex; gap: 16px; margin-bottom: 24px; flex-wrap: wrap; }}
.card {{ background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 16px 20px; min-width: 160px; }}
.card-value {{ font-size: 28px; font-weight: 700; font-family: 'SF Mono', 'Consolas', monospace; }}
.card-label {{ font-size: 12px; color: #7d8590; margin-top: 2px; }}
.no-data {{ color: #484f58; font-style: italic; }}
.agent-header {{ background: #0d1117; }}
.agent-header td {{ padding-top: 16px; font-weight: 600; color: #e6edf3; border-bottom: 2px solid #30363d; }}
</style>
</head>
<body>

<h1>Temporal Developer Skill &mdash; Eval Dashboard</h1>
<div class="subtitle">Comparing skill performance across commits against baseline</div>

<div id="app"></div>

<script>
const DATA = {data_json};

function scoreClass(v) {{
  if (v >= 1.0) return 'score-perfect';
  if (v >= 0.75) return 'score-good';
  if (v >= 0.5) return 'score-mid';
  return 'score-low';
}}

function fmt(v) {{
  if (v === undefined || v === null) return '<span class="no-data">-</span>';
  return (v * 100).toFixed(0) + '%';
}}

function deltaHtml(v, baseline) {{
  if (baseline === undefined || v === undefined) return '';
  const d = v - baseline;
  if (Math.abs(d) < 0.001) return '<span class="delta delta-zero">=</span>';
  const sign = d > 0 ? '+' : '';
  const cls = d > 0 ? 'delta-pos' : 'delta-neg';
  return `<span class="delta ${{cls}}">${{sign}}${{(d * 100).toFixed(0)}}%</span>`;
}}

function checkHtml(name, val, baselineVal) {{
  let cls = 'check-pass';
  if (val <= 0) cls = 'check-fail';
  else if (val < 1) cls = 'check-partial';
  const delta = deltaHtml(val, baselineVal);
  return `<span class="${{cls}} check">${{name}} ${{fmt(val)}}${{delta}}</span>`;
}}

function checksColumn(tasks, baselineTasks) {{
  let h = '';
  for (const [taskName, checks] of Object.entries(tasks)) {{
    const blTask = baselineTasks && baselineTasks[taskName] ? baselineTasks[taskName] : {{}};
    h += `<div class="task-name">${{taskName}}</div><div class="checks-grid">`;
    for (const [k, v] of Object.entries(checks)) {{
      h += checkHtml(k, v, blTask[k]);
    }}
    h += '</div>';
  }}
  return h;
}}

function render() {{
  const app = document.getElementById('app');
  let h = '';
  const multiAgent = DATA.agents.length > 1;

  // Summary cards
  const latestCommit = DATA.commits[DATA.commits.length - 1];
  h += '<div class="summary-cards">';
  h += `<div class="card"><div class="card-value">${{DATA.commits.length}}</div><div class="card-label">Commits tracked</div></div>`;
  h += `<div class="card"><div class="card-value">${{DATA.datasets.length}}</div><div class="card-label">Datasets</div></div>`;
  h += `<div class="card"><div class="card-value">${{DATA.agents.length}}</div><div class="card-label">Agent configs</div></div>`;

  if (latestCommit) {{
    // Latest aggregate across all combos
    let totalScore = 0, count = 0;
    for (const [, d] of Object.entries(latestCommit.results)) {{
      totalScore += d.aggregate; count++;
    }}
    const avg = count > 0 ? totalScore / count : 0;
    h += `<div class="card"><div class="card-value ${{scoreClass(avg)}}">${{fmt(avg)}}</div><div class="card-label">Latest overall (skill)</div></div>`;
  }}

  // Baseline aggregate
  let bTotal = 0, bCount = 0;
  for (const [, b] of Object.entries(DATA.baseline)) {{
    bTotal += b.aggregate; bCount++;
  }}
  const bAvg = bCount > 0 ? bTotal / bCount : 0;
  h += `<div class="card"><div class="card-value ${{scoreClass(bAvg)}}">${{fmt(bAvg)}}</div><div class="card-label">Baseline overall</div></div>`;
  h += '</div>';

  // Per-dataset sections
  for (const ds of DATA.datasets) {{
    h += `<div class="section">`;
    h += `<div class="section-title"><span class="dataset-tag">${{ds}}</span></div>`;
    h += '<table>';

    if (multiAgent) {{
      h += '<tr><th>Commit</th><th>Message</th><th>Agent / Model</th><th>Aggregate</th><th style="width:45%">Per-Task Checks</th></tr>';
    }} else {{
      h += '<tr><th>Commit</th><th>Message</th><th>Aggregate</th><th style="width:50%">Per-Task Checks</th></tr>';
    }}

    // Baseline rows (one per agent)
    for (const agent of DATA.agents) {{
      const key = `${{ds}}::${{agent.name}}::${{agent.model}}`;
      const bl = DATA.baseline[key];
      if (!bl) continue;

      h += `<tr class="baseline-row">`;
      h += `<td><span class="baseline-label">baseline</span></td>`;
      h += `<td><span class="baseline-label">no skill</span></td>`;
      if (multiAgent) h += `<td><span class="agent-tag">${{agent.name}} / ${{agent.model}}</span></td>`;
      h += `<td><span class="score ${{scoreClass(bl.aggregate)}}">${{fmt(bl.aggregate)}}</span></td>`;
      h += `<td>${{checksColumn(bl.tasks, undefined)}}</td>`;
      h += '</tr>';
    }}

    // Commit rows (newest first)
    const reversed = [...DATA.commits].reverse();
    for (const commit of reversed) {{
      // For each agent, emit a row if data exists
      let first = true;
      for (const agent of DATA.agents) {{
        const key = `${{ds}}::${{agent.name}}::${{agent.model}}`;
        const cd = commit.results[key];
        const blKey = `${{ds}}::${{agent.name}}::${{agent.model}}`;
        const bl = DATA.baseline[blKey];

        h += '<tr>';
        if (first) {{
          const rowspan = multiAgent ? ` rowspan="${{DATA.agents.length}}"` : '';
          h += `<td${{rowspan}}><span class="sha">${{commit.sha}}</span></td>`;
          h += `<td${{rowspan}}><span class="msg">${{commit.message}}</span></td>`;
          first = false;
        }} else {{
          // sha and message cells covered by rowspan
        }}

        if (multiAgent) h += `<td><span class="agent-tag">${{agent.name}} / ${{agent.model}}</span></td>`;

        if (!cd) {{
          h += `<td class="no-data">-</td>`;
          h += `<td class="no-data">not run</td>`;
        }} else {{
          const baselineAgg = bl ? bl.aggregate : undefined;
          h += `<td><span class="score ${{scoreClass(cd.aggregate)}}">${{fmt(cd.aggregate)}}</span>${{deltaHtml(cd.aggregate, baselineAgg)}}</td>`;
          h += `<td>${{checksColumn(cd.tasks, bl ? bl.tasks : undefined)}}</td>`;
        }}
        h += '</tr>';
      }}
    }}

    h += '</table></div>';
  }}

  app.innerHTML = h;
}}

render();
</script>
</body>
</html>"""


def main():
    parser = argparse.ArgumentParser(description="Generate eval dashboard")
    parser.add_argument("--out", default=None, help="Output HTML path (default: evals/dashboard.html)")
    parser.add_argument("--no-open", action="store_true", help="Don't open in browser")
    args = parser.parse_args()

    evals_dir = Path(__file__).resolve().parent.parent
    repo_root = evals_dir.parent

    out_path = Path(args.out) if args.out else evals_dir / "dashboard.html"

    html_content = _render_html(evals_dir, repo_root)
    out_path.write_text(html_content)
    print(f"Dashboard written to {out_path}")

    if not args.no_open:
        webbrowser.open(f"file://{out_path.resolve()}")


def main_sync():
    main()


if __name__ == "__main__":
    main_sync()
