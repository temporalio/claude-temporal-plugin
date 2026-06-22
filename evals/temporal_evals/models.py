"""Shared data models."""

from dataclasses import dataclass


@dataclass
class AgentConfig:
    """An agent configuration to evaluate."""

    name: str
    model: str
