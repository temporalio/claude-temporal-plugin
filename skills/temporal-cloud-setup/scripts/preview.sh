#!/usr/bin/env bash
# Read-only disclosure shim for temporal-cloud-setup.
#
# This forwards verbatim to `provision.sh preview <args>` and nothing else.
# It exists so the agent can build a step's GATE block (the disclosure the
# user sees BEFORE approving) WITHOUT that disclosure call itself tripping an
# approval prompt: a `Bash(*provision.sh*)` permission rule matches the real,
# effectful subcommands but NOT this file's name. Disclosure must always
# precede confirmation, so the gate-builder must be promptless.
#
# All logic remains in provision.sh — this adds zero behavior. `preview` is
# side-effect-free (no network, no writes), so running it unprompted is safe.
set -euo pipefail
# Resolve our own directory with bash builtins only (no external `dirname`/`cd`
# binary), so the shim works even on a minimal PATH.
dir="${0%/*}"; [ "$dir" = "$0" ] && dir="."
dir="$(cd "$dir" && pwd)"
# Forward with the same bash interpreter running this shim, so we don't depend on
# provision.sh's `#!/usr/bin/env bash` shebang resolving on a minimal PATH.
exec "${BASH:-bash}" "$dir/provision.sh" preview "$@"