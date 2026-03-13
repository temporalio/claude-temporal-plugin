FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    git \
    python3.12 \
    python3.12-venv \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Node.js 20.x
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Temporal CLI
RUN curl -sSf https://temporal.download/cli.sh | sh
ENV PATH="/root/.temporalio/bin:${PATH}"

# uv (for running Python scripts with inline deps)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

RUN mkdir -p /workspace /logs/verifier
WORKDIR /workspace
