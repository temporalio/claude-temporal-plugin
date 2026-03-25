# /// script
# dependencies = [
#   "anthropic>=0.75.0",
#   "pydantic==2.12.5",
# ]
# ///

"""Generic LLM-as-judge verifier for Q/A tasks.

Reads the rubric from /tests/rubric.md and the answer from /workspace/answer.md.
Writes a reward to /logs/verifier/reward.json.

Environment variables:
    ANTHROPIC_API_KEY: Required.
    MODEL_NAME: Judge model (default: claude-haiku-4-5-20251001).
"""

import json
import os
from pathlib import Path

from anthropic import Anthropic, transform_schema
from pydantic import BaseModel, Field


class GradeResponse(BaseModel):
    """Response model for Q/A grading."""

    score: float = Field(
        ...,
        ge=0.0,
        le=1.0,
        description="The score of the answer from 0.0 to 1.0.",
    )
    rationale: str = Field(
        ...,
        description="Brief explanation for the score.",
    )


def main():
    rubric_path = Path("/tests/rubric.md")
    answer_path = Path("/workspace/answer.md")
    reward_path = Path("/logs/verifier/reward.json")

    if not rubric_path.exists():
        raise FileNotFoundError("Missing /tests/rubric.md — each task must provide one.")

    rubric = rubric_path.read_text()

    if not answer_path.exists() or answer_path.stat().st_size == 0:
        print("FAIL: answer.md not found or empty")
        reward_path.write_text(json.dumps({"reward": 0.0}))
        return

    answer = answer_path.read_text()

    client = Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))
    schema = transform_schema(GradeResponse.model_json_schema())

    response = client.messages.create(
        model=os.getenv("MODEL_NAME", "claude-haiku-4-5-20251001"),
        max_tokens=1024,
        output_config={"format": {"type": "json_schema", "schema": schema}},
        messages=[
            {
                "role": "user",
                "content": f"{rubric}\n\n---\n\nAnswer to grade:\n\n{answer}",
            }
        ],
    )

    result = GradeResponse.model_validate_json(response.content[0].text)
    print(f"Score: {result.score}")
    print(f"Rationale: {result.rationale}")

    reward_path.write_text(json.dumps({"reward": result.score}, indent=2))


if __name__ == "__main__":
    main()
