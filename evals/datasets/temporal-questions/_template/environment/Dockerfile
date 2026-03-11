FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    python3.12 \
    python3.12-venv \
    && rm -rf /var/lib/apt/lists/*

# Install uv (used by test.sh to run llm_judge.py with inline deps)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

RUN mkdir -p /workspace /logs/verifier
WORKDIR /workspace
