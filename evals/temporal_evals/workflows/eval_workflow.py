"""Eval workflow that fans out Harbor jobs across agent configs and datasets."""

import asyncio
from datetime import timedelta

from temporalio import workflow

with workflow.unsafe.imports_passed_through():
    from ..activities.harbor import run_harbor_job
    from ..activities.record import get_existing_results, record_results
    from ..models import (
        EvalRunInput,
        EvalRunOutput,
        ExistingResultsInput,
        HarborJobInput,
        HarborJobOutput,
        RecordResultsInput,
    )


@workflow.defn
class EvalWorkflow:
    """Run Harbor evals across multiple agent configurations and datasets.

    Fans out one activity per (agent, dataset) combination, then records
    results to the appropriate YAML file.
    """

    @workflow.run
    async def run(self, input: EvalRunInput) -> EvalRunOutput:
        timestamp = workflow.now().strftime("%Y-%m-%d__%H-%M-%S")
        jobs_dir = f"{input.repo_root}/jobs"

        # Check which combos already have results
        existing = await workflow.execute_activity(
            get_existing_results,
            ExistingResultsInput(
                baseline=input.baseline,
                repo_root=input.repo_root,
                skills_dir=input.skills_dir,
            ),
            start_to_close_timeout=timedelta(minutes=1),
        )
        skip_set = {
            (e.agent_name, e.agent_model, e.dataset)
            for e in existing.existing
        }

        # Fan out: one activity per (agent, dataset) pair, skipping existing
        tasks: list[asyncio.Task[HarborJobOutput]] = []
        skipped_count = 0
        for agent in input.agents:
            for dataset in input.datasets:
                model_key = agent.model.replace("/", "-")
                if (agent.name, model_key, dataset) in skip_set:
                    workflow.logger.info(
                        f"Skipping {agent.name}/{agent.model} on {dataset} — results already exist"
                    )
                    skipped_count += 1
                    continue

                dataset_path = f"{input.repo_root}/evals/datasets/{dataset}"
                suffix = "__baseline" if input.baseline else ""
                job_name = f"{timestamp}__{agent.name}__{dataset}{suffix}"

                task = asyncio.ensure_future(
                    workflow.execute_activity(
                        run_harbor_job,
                        HarborJobInput(
                            agent_name=agent.name,
                            agent_model=agent.model,
                            dataset_path=dataset_path,
                            skills_dir=input.skills_dir,
                            job_name=job_name,
                            jobs_dir=jobs_dir,
                            repo_root=input.repo_root,
                        ),
                        start_to_close_timeout=timedelta(minutes=60),
                        heartbeat_timeout=timedelta(minutes=5),
                    )
                )
                tasks.append(task)

        if skipped_count:
            workflow.logger.info(f"Skipped {skipped_count} evals with existing results")

        if not tasks:
            workflow.logger.info("All evals already have results, nothing to run")
            return EvalRunOutput(results=[], record_message="All evals already have results.")

        results: list[HarborJobOutput] = list(await asyncio.gather(*tasks))

        # Record results from successful jobs
        successful_dirs = [r.job_dir for r in results if r.success]
        record_message = ""
        if successful_dirs:
            record_message = await workflow.execute_activity(
                record_results,
                RecordResultsInput(
                    job_dirs=successful_dirs,
                    baseline=input.baseline,
                    repo_root=input.repo_root,
                ),
                start_to_close_timeout=timedelta(minutes=5),
            )

        # Log failures
        for r in results:
            if not r.success:
                workflow.logger.error(
                    f"FAILED: {r.dataset} ({r.agent_name}/{r.agent_model}): {r.error}"
                )

        return EvalRunOutput(results=results, record_message=record_message)
