"""Data models shared between workflows, activities, and starters."""

from dataclasses import dataclass, field


@dataclass
class AgentConfig:
    """An agent configuration to evaluate."""

    name: str
    model: str


@dataclass
class EvalRunInput:
    """Input for the EvalWorkflow."""

    agents: list[AgentConfig]
    datasets: list[str]
    repo_root: str
    skills_dir: str | None = None
    baseline: bool = False


@dataclass
class HarborJobInput:
    """Input for a single Harbor job activity."""

    agent_name: str
    agent_model: str
    dataset_path: str
    skills_dir: str | None
    job_name: str
    jobs_dir: str
    repo_root: str


@dataclass
class HarborJobOutput:
    """Output from a single Harbor job activity."""

    job_dir: str
    dataset: str
    agent_name: str
    agent_model: str
    success: bool
    error: str | None = None


@dataclass
class ExistingResultsInput:
    """Input for checking which evals already have results."""

    baseline: bool
    repo_root: str
    skills_dir: str | None = None


@dataclass
class EvalIdentity:
    """Identifies a unique eval combination."""

    agent_name: str
    agent_model: str
    dataset: str


@dataclass
class ExistingResultsOutput:
    """Output listing which eval combos already have results."""

    existing: list[EvalIdentity]


@dataclass
class RecordResultsInput:
    """Input for recording results to YAML."""

    job_dirs: list[str]
    baseline: bool
    repo_root: str


@dataclass
class EvalRunOutput:
    """Output from the EvalWorkflow."""

    results: list[HarborJobOutput]
    record_message: str = ""
