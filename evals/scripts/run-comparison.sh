#!/bin/bash
# Run a skill vs no-skill comparison for Temporal developer tasks.
#
# Usage:
#   ./evals/scripts/run-comparison.sh --dataset temporal-python
#   ./evals/scripts/run-comparison.sh --dataset temporal-python --model anthropic/claude-sonnet-4-6
#   ./evals/scripts/run-comparison.sh --dataset temporal-typescript --n-attempts 3
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

DATASET=""
MODEL="anthropic/claude-sonnet-4-6"
AGENT="claude-code"
N_ATTEMPTS=1
N_CONCURRENT=2
SKILLS_DIR="plugins/temporal-developer/skills/temporal-developer"
EXTRA_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dataset)      DATASET="$2";       shift 2 ;;
        --model)        MODEL="$2";         shift 2 ;;
        --agent)        AGENT="$2";         shift 2 ;;
        --n-attempts)   N_ATTEMPTS="$2";    shift 2 ;;
        --n-concurrent) N_CONCURRENT="$2";  shift 2 ;;
        --skills-dir)   SKILLS_DIR="$2";    shift 2 ;;
        *)              EXTRA_ARGS+=("$1"); shift ;;
    esac
done

if [ -z "$DATASET" ]; then
    echo "Usage: $0 --dataset <temporal-python|temporal-typescript> [--model MODEL] [--n-attempts N]"
    exit 1
fi

DATASET_PATH="$REPO_ROOT/evals/datasets/$DATASET"
if [ ! -d "$DATASET_PATH" ]; then
    echo "Error: dataset directory not found: $DATASET_PATH"
    exit 1
fi

TIMESTAMP=$(date +%Y-%m-%d__%H-%M-%S)
JOBS_DIR="$REPO_ROOT/jobs"

echo "=== Temporal Developer Skill Comparison ==="
echo "Dataset:    $DATASET"
echo "Model:      $MODEL"
echo "Agent:      $AGENT"
echo "Attempts:   $N_ATTEMPTS"
echo "Skills dir: $SKILLS_DIR"
echo ""

# --- Run 1: Baseline (no skill) ---
echo ">>> Run 1/2: Baseline (no skill)"
harbor run \
    -p "$DATASET_PATH" \
    -a "$AGENT" \
    -m "$MODEL" \
    -k "$N_ATTEMPTS" \
    -n "$N_CONCURRENT" \
    --job-name "${TIMESTAMP}__${DATASET}__baseline" \
    -o "$JOBS_DIR" \
    "${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"}"

echo ""

# --- Run 2: With skill ---
echo ">>> Run 2/2: With temporal-developer skill"
harbor run \
    -p "$DATASET_PATH" \
    -a "$AGENT" \
    -m "$MODEL" \
    -k "$N_ATTEMPTS" \
    -n "$N_CONCURRENT" \
    --skills-dir "$REPO_ROOT/$SKILLS_DIR" \
    --job-name "${TIMESTAMP}__${DATASET}__with-skill" \
    -o "$JOBS_DIR" \
    "${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"}"

echo ""
echo "=== Comparison complete ==="
echo "Baseline results: $JOBS_DIR/${TIMESTAMP}__${DATASET}__baseline/result.json"
echo "With-skill results: $JOBS_DIR/${TIMESTAMP}__${DATASET}__with-skill/result.json"
