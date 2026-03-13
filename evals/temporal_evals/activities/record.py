"""Activity for recording Harbor job results to YAML files."""

import json
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

import yaml
from temporalio import activity

from ..models import EvalIdentity, ExistingResultsInput, ExistingResultsOutput, RecordResultsInput


def _get_git_sha(explicit: str | None = None) -> str:
    if explicit:
        return explicit
    result = subprocess.run(
        ["git", "rev-parse", "HEAD"],
        capture_output=True,
        text=True,
        check=True,
    )
    return result.stdout.strip()[:12]


def _extract_skills(config: dict) -> list[str]:
    """Extract skill names from JobConfig.skills_dir."""
    skills_dir = config.get("skills_dir")
    if not skills_dir:
        return []
    return [Path(skills_dir).name]


def _extract_job_entries(job_dir: Path) -> list[dict]:
    """Extract one results entry per evals_key from a Harbor job directory."""
    result_path = job_dir / "result.json"
    config_path = job_dir / "config.json"

    if not result_path.exists():
        print(f"Warning: {result_path} not found, skipping", file=sys.stderr)
        return []
    if not config_path.exists():
        print(f"Warning: {config_path} not found, skipping", file=sys.stderr)
        return []

    job_result = json.loads(result_path.read_text())
    job_config = json.loads(config_path.read_text())

    skills = _extract_skills(job_config)
    timestamp = job_result.get("started_at")

    # Collect per-trial rewards grouped by evals_key -> task_name
    trial_rewards: dict[str, dict[str, list[dict]]] = defaultdict(
        lambda: defaultdict(list)
    )
    trial_errors: dict[str, int] = defaultdict(int)

    for trial_dir in sorted(job_dir.iterdir()):
        if not trial_dir.is_dir():
            continue
        trial_result_path = trial_dir / "result.json"
        if not trial_result_path.exists():
            continue

        trial = json.loads(trial_result_path.read_text())

        agent_name = trial.get("agent_info", {}).get("name", "unknown")
        model_info = trial.get("agent_info", {}).get("model_info")
        model_name = model_info["name"] if model_info else None
        dataset_name = trial.get("source") or "adhoc"

        if model_name:
            evals_key = f"{agent_name}__{model_name}__{dataset_name}".replace("/", "-")
        else:
            evals_key = f"{agent_name}__{dataset_name}".replace("/", "-")

        task_name = trial.get("task_name", "unknown")
        verifier_result = trial.get("verifier_result")

        if verifier_result and verifier_result.get("rewards"):
            trial_rewards[evals_key][task_name].append(verifier_result["rewards"])
        elif trial.get("exception_info"):
            trial_errors[evals_key] += 1

    entries = []
    stats = job_result.get("stats", {})
    evals = stats.get("evals", {})

    for evals_key, evals_data in evals.items():
        parts = evals_key.split("__")
        if len(parts) == 3:
            agent_name, model_name, dataset_name = parts
        elif len(parts) == 2:
            agent_name, dataset_name = parts
            model_name = None
        else:
            agent_name = evals_key
            model_name = None
            dataset_name = "adhoc"

        metrics_list = evals_data.get("metrics", [])
        metrics = {}
        for m in metrics_list:
            if isinstance(m, dict):
                metrics.update(m)

        tasks = {}
        for task_name, reward_list in trial_rewards.get(evals_key, {}).items():
            if len(reward_list) == 1:
                tasks[task_name] = reward_list[0]
            else:
                all_keys = set()
                for r in reward_list:
                    all_keys.update(r.keys())
                averaged = {}
                for k in sorted(all_keys):
                    values = [r[k] for r in reward_list if k in r]
                    averaged[k] = round(sum(values) / len(values), 4)
                tasks[task_name] = averaged

        entry: dict = {
            "timestamp": timestamp,
            "dataset": dataset_name,
            "agent": agent_name,
        }
        if model_name:
            entry["model"] = model_name
        entry["skills"] = skills
        if metrics:
            entry["metrics"] = metrics
        if tasks:
            entry["tasks"] = tasks

        n_errors = trial_errors.get(evals_key, 0)
        if n_errors > 0:
            entry["errors"] = n_errors

        entries.append(entry)

    return entries


def _entry_identity(entry: dict) -> tuple:
    """Return a hashable identity for deduplication."""
    return (
        entry.get("dataset"),
        entry.get("agent"),
        entry.get("model"),
        tuple(sorted(entry.get("skills", []))),
        entry.get("timestamp"),
    )


def _load_yaml_dict(path: Path) -> dict:
    if not path.exists():
        return {}
    data = yaml.safe_load(path.read_text())
    return data if isinstance(data, dict) else {}


def _load_yaml_list(path: Path) -> list:
    if not path.exists():
        return []
    data = yaml.safe_load(path.read_text())
    return data if isinstance(data, list) else []


def _save_results(results_path: Path, data: dict) -> None:
    header = (
        "# Eval results keyed by commit SHA.\n"
        "# Each commit maps to an array of run configurations (agent, model, skills, dataset).\n"
        "# Generated by: temporal_evals.activities.record\n\n"
    )
    body = yaml.dump(data, default_flow_style=False, sort_keys=False, allow_unicode=True)
    results_path.write_text(header + body)


def _save_baseline(baseline_path: Path, data: list) -> None:
    header = (
        "# Baseline eval results (no skills enabled).\n"
        "# Re-run when eval tasks or Harbor change, not on every skill change.\n"
        "# Generated by: temporal_evals.activities.record\n\n"
    )
    body = yaml.dump(data, default_flow_style=False, sort_keys=False, allow_unicode=True)
    baseline_path.write_text(header + body)


@activity.defn
def get_existing_results(input: ExistingResultsInput) -> ExistingResultsOutput:
    """Check which eval combos already have results on disk."""
    repo_root = Path(input.repo_root)
    skills = [Path(input.skills_dir).name] if input.skills_dir else []
    skills_tuple = tuple(sorted(skills))

    existing: list[EvalIdentity] = []

    if input.baseline:
        baseline_path = repo_root / "evals" / "baseline.yaml"
        entries = _load_yaml_list(baseline_path)
    else:
        sha = _get_git_sha()
        results_path = repo_root / "evals" / "results.yaml"
        results = _load_yaml_dict(results_path)
        entries = results.get(sha, [])

    for entry in entries:
        entry_skills = tuple(sorted(entry.get("skills", [])))
        if entry_skills != skills_tuple:
            continue
        agent = entry.get("agent")
        model = entry.get("model")
        dataset = entry.get("dataset")
        if agent and dataset:
            existing.append(EvalIdentity(
                agent_name=agent,
                agent_model=model or "",
                dataset=dataset,
            ))

    activity.logger.info(f"Found {len(existing)} existing results to skip")
    return ExistingResultsOutput(existing=existing)


@activity.defn
def record_results(input: RecordResultsInput) -> str:
    """Extract Harbor job results and append to the appropriate YAML file."""
    repo_root = Path(input.repo_root)

    # Extract entries from all job dirs
    new_entries = []
    for job_dir_str in input.job_dirs:
        job_dir = Path(job_dir_str).resolve()
        if not job_dir.is_dir():
            activity.logger.warning(f"{job_dir} is not a directory, skipping")
            continue
        entries = _extract_job_entries(job_dir)
        new_entries.extend(entries)
        activity.logger.info(f"Extracted {len(entries)} entries from {job_dir.name}")

    if not new_entries:
        return "No entries extracted."

    if input.baseline:
        output_path = repo_root / "evals" / "baseline.yaml"
        existing = _load_yaml_list(output_path)
        existing_ids = {_entry_identity(e) for e in existing}

        added = 0
        skipped = 0
        for entry in new_entries:
            if _entry_identity(entry) in existing_ids:
                skipped += 1
            else:
                existing.append(entry)
                existing_ids.add(_entry_identity(entry))
                added += 1

        _save_baseline(output_path, existing)
        msg = f"Added {added} baseline entries in {output_path}"
    else:
        sha = _get_git_sha()
        output_path = repo_root / "evals" / "results.yaml"
        results = _load_yaml_dict(output_path)

        if sha not in results:
            results[sha] = []

        existing_ids = {_entry_identity(e) for e in results[sha]}
        added = 0
        skipped = 0
        for entry in new_entries:
            if _entry_identity(entry) in existing_ids:
                skipped += 1
            else:
                results[sha].append(entry)
                existing_ids.add(_entry_identity(entry))
                added += 1

        _save_results(output_path, results)
        msg = f"Added {added} entries under commit {sha} in {output_path}"

    if skipped:
        msg += f" ({skipped} duplicates skipped)"
    return msg
