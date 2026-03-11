#!/bin/bash
# Minimal reference solution for the TypeScript greeting workflow task.
set -euo pipefail
cd /workspace

cat > activities.ts << 'TSEOF'
export async function formatGreeting(name: string): Promise<string> {
  return `Hello, ${name}!`;
}
TSEOF

cat > workflows.ts << 'TSEOF'
import { proxyActivities, defineSignal, defineQuery, setHandler } from "@temporalio/workflow";
import type { formatGreeting } from "./activities";

const { formatGreeting: greet } = proxyActivities<{ formatGreeting: typeof formatGreeting }>({
  startToCloseTimeout: "10s",
});

export const updateGreetingStyleSignal = defineSignal<[string]>("updateGreetingStyle");
export const getGreetingCountQuery = defineQuery<number>("getGreetingCount");

export async function greetingWorkflow(name: string): Promise<string> {
  let greetingCount = 0;
  let greetingStyle = "Hello";

  setHandler(updateGreetingStyleSignal, (style: string) => {
    greetingStyle = style;
  });

  setHandler(getGreetingCountQuery, () => greetingCount);

  greetingCount++;
  const result = await greet(name);
  return result;
}
TSEOF

cat > worker.ts << 'TSEOF'
import { Worker } from "@temporalio/worker";
import * as activities from "./activities";

async function run(): Promise<void> {
  const worker = await Worker.create({
    workflowsPath: require.resolve("./workflows"),
    activities,
    taskQueue: "greeting-task-queue",
  });
  await worker.run();
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
TSEOF

cat > client.ts << 'TSEOF'
import { Client } from "@temporalio/client";
import { greetingWorkflow } from "./workflows";

async function run(): Promise<void> {
  const client = new Client();
  const name = process.argv[2] || "World";
  const result = await client.workflow.execute(greetingWorkflow, {
    args: [name],
    taskQueue: "greeting-task-queue",
    workflowId: `greeting-${name}`,
  });
  console.log(result);
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
TSEOF

cat > package.json << 'TSEOF'
{
  "name": "temporal-greeting",
  "version": "1.0.0",
  "scripts": {
    "build": "tsc",
    "start:worker": "ts-node worker.ts",
    "start:client": "ts-node client.ts"
  },
  "dependencies": {
    "@temporalio/client": "^1.11.0",
    "@temporalio/worker": "^1.11.0",
    "@temporalio/workflow": "^1.11.0",
    "@temporalio/activity": "^1.11.0"
  },
  "devDependencies": {
    "typescript": "^5.0.0",
    "ts-node": "^10.9.0",
    "@types/node": "^20.0.0"
  }
}
TSEOF

cat > tsconfig.json << 'TSEOF'
{
  "compilerOptions": {
    "target": "ES2021",
    "module": "commonjs",
    "lib": ["ES2021"],
    "strict": true,
    "esModuleInterop": true,
    "outDir": "./dist",
    "rootDir": ".",
    "skipLibCheck": true
  },
  "include": ["*.ts"]
}
TSEOF
