#!/usr/bin/env bash
#
# run-tests.sh — offline, stubbed tests for provision.sh (PE-75 adaptation work).
#
# These tests run with NO network and NO real Temporal CLI. They build an isolated
# PATH containing only (a) symlinks to the handful of coreutils provision.sh needs
# and (b) fake "dev tool" stubs whose versions/presence we control per scenario, so
# detection/preview/install-deps are exercised through the real subcommand entry
# path — exactly as the skill invokes them.
#
# Run under macOS /bin/bash (3.2) to match the skill's portability target:
#     /bin/bash scripts/tests/run-tests.sh
#
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROVISION="$(cd "$HERE/.." && pwd)/provision.sh"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/tcloud-test.XXXXXX")"
STUB="$WORK/bin"
mkdir -p "$STUB"
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); printf 'ok   - %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf 'FAIL - %s\n' "$1"; [ -n "${2:-}" ] && printf '       %s\n' "$2"; }

# Symlink the real coreutils provision.sh touches into the isolated bin so an
# otherwise-empty PATH still has them. Discovered via the inherited PATH now.
for c in uname grep head tr cut sed cat basename dirname mktemp mkdir chmod mv rm sleep sort awk env true false sh jq; do
  p="$(command -v "$c" 2>/dev/null)" && ln -sf "$p" "$STUB/$c"
done

# make_stub <name> <<'BODY' ... BODY  — write an executable fake tool into $STUB.
make_stub() { local n="$1"; cat > "$STUB/$n"; chmod +x "$STUB/$n"; }

# Convenience builders for the dev tools, version-parameterized. The heredoc is
# UNQUOTED, so the function's $1/$name (write-time) interpolate the version, while
# \$1/\$*/\$STUB_LOG (escaped) stay as the stub's own runtime references.
stub_python3() { # $1 = version; provides BOTH python3 and python (the venv install
                 # chain calls `python` after activating), plus -m venv -> fake env.
  local n
  for n in python3 python; do
    make_stub "$n" <<BODY
#!/bin/sh
echo "$n \$*" >> "\$STUB_LOG"
[ "\$1" = "--version" ] && echo "Python $1"
if [ "\$1" = "-m" ] && [ "\$2" = "venv" ]; then mkdir -p "\$3/bin"; printf ':\n' > "\$3/bin/activate"; fi
exit 0
BODY
  done
}
stub_uv() { # $1 = version; `uv venv env` creates a fake env so the && chain proceeds
  make_stub uv <<BODY
#!/bin/sh
echo "uv \$*" >> "\$STUB_LOG"
[ "\$1" = "--version" ] && echo "uv $1"
if [ "\$1" = "venv" ]; then mkdir -p "\$2/bin"; printf ':\n' > "\$2/bin/activate"; fi
exit 0
BODY
}
stub_simple() { # $1=name $2=versionline $3=version-flag(default --version)
  local name="$1" line="$2" flag="${3:---version}"
  make_stub "$name" <<BODY
#!/bin/sh
echo "$name \$*" >> "\$STUB_LOG"
if [ "\$1" = "$flag" ]; then echo "$line"; fi
exit 0
BODY
}
stub_java() { # $1 = version (e.g. 17.0.1 or 1.8.0_292) -> printed to stderr
  make_stub java <<BODY
#!/bin/sh
echo "java \$*" >> "\$STUB_LOG"
[ "\$1" = "-version" ] && echo "openjdk version \"$1\" 2024-01-01" 1>&2
exit 0
BODY
}
# Tripwire stubs: `temporal` (whoami succeeds so provision-and-scaffold proceeds to
# manager validation) and `git`. Both LOG every invocation, so a test can assert a
# command was NOT reached (fail-fast) or that preview/detect made zero such calls.
stub_temporal() {
  make_stub temporal <<'BODY'
#!/bin/sh
echo "temporal $*" >> "$STUB_LOG"
case "$*" in
  *whoami*) echo "user@example.com"; exit 0 ;;
  # Faithful to the real CLI: `--version` prints the version; `cloud version` is NOT a
  # real subcommand and prints the group's HELP text (the source of the version= bug).
  "--version") echo "temporal version 9.9.9 (Server 1.31.1, UI 2.49.1)"; exit 0 ;;
  *"cloud version"*) echo "The Temporal Cloud CLI provides commands for managing and operating Temporal Cloud resources,"; exit 0 ;;
esac
exit 0
BODY
}
stub_git() {
  make_stub git <<'BODY'
#!/bin/sh
echo "git $*" >> "$STUB_LOG"
# emulate `git clone … <target>` by creating the target dir (the last arg), so a
# following deps step can cd into it.
if [ "$1" = clone ]; then for a in "$@"; do t="$a"; done; mkdir -p "$t"; fi
exit 0
BODY
}
# temporal stub that also answers `namespace list ... -o json` with provided JSON ($1),
# so await-namespace's namespace_active_info can resolve (or not) a handle offline.
stub_temporal_list() {
  local listjson="$1"
  make_stub temporal <<BODY
#!/bin/sh
echo "temporal \$*" >> "\$STUB_LOG"
case "\$*" in
  *whoami*) echo "user@example.com"; exit 0 ;;
  *"namespace list"*) printf '%s\n' '$listjson'; exit 0 ;;
esac
exit 0
BODY
}

reset_stubs() { rm -f "$STUB"/python3 "$STUB"/python "$STUB"/uv "$STUB"/node "$STUB"/npm "$STUB"/pnpm \
  "$STUB"/yarn "$STUB"/go "$STUB"/mvn "$STUB"/dotnet "$STUB"/ruby "$STUB"/bundle "$STUB"/java \
  "$STUB"/temporal "$STUB"/git 2>/dev/null; : > "$WORK/calls.log"; }

# run <args...> -> runs provision.sh with the isolated PATH; stdout -> $OUT, stderr -> $ERR
run() {
  STUB_LOG="$WORK/calls.log" PATH="$STUB" /bin/bash "$PROVISION" "$@" >"$WORK/out" 2>"$WORK/err"
  RC=$?; OUT="$(cat "$WORK/out")"; ERR="$(cat "$WORK/err")"
}
val() { printf '%s\n' "$OUT" | grep -E "^$1=" | head -n1 | sed "s/^$1=//"; }

# ---------------------------------------------------------------------------
# detect-tools
# ---------------------------------------------------------------------------
reset_stubs
stub_python3 3.12.1; stub_uv 0.5.4
run detect-tools --sdk python
[ "$(val status)" = ok ] && [ "$(val default)" = pip ] && [ "$(val managers)" = "pip,uv" ] \
  && ok "detect python: default=pip, managers=pip,uv (both present)" \
  || bad "detect python default/managers" "default=$(val default) managers=$(val managers)"
[ -z "$(val discrepancies)" ] && ok "detect python: no discrepancies when versions fine" \
  || bad "detect python discrepancies should be empty" "$(val discrepancies)"

reset_stubs
stub_python3 3.7.9; stub_uv 0.5.4
run detect-tools --sdk python
case "$(val discrepancies)" in *version-too-old:python3@3.7*) ok "detect python: too-old runtime flagged" ;; *) bad "detect python too-old" "$(val discrepancies)" ;; esac
[ "$(val default)" = pip ] && ok "detect python: default still pip despite old version" || bad "detect python default with old ver" "$(val default)"

reset_stubs
stub_simple node "v20.11.0"; stub_simple npm "10.2.3"; stub_simple pnpm "8.15.0"; stub_simple yarn "1.22.19"
run detect-tools --sdk ts
[ "$(val default)" = npm ] && [ "$(val managers)" = "npm,pnpm,yarn" ] \
  && ok "detect ts: default=npm (lockfile-backed), all three available" \
  || bad "detect ts default/managers" "default=$(val default) managers=$(val managers)"

reset_stubs
stub_simple node "v20.11.0"; stub_simple pnpm "8.15.0"; stub_simple yarn "1.22.19"   # no npm
run detect-tools --sdk ts
[ "$(val default)" = pnpm ] && [ "$(val managers)" = "pnpm,yarn" ] \
  && ok "detect ts: default falls to pnpm when npm absent" \
  || bad "detect ts default w/o npm" "default=$(val default) managers=$(val managers)"

reset_stubs
stub_simple node "v14.0.0"; stub_simple npm "10.2.3"
run detect-tools --sdk ts
case "$(val discrepancies)" in *version-too-old:node@14*) ok "detect ts: old node flagged" ;; *) bad "detect ts old node" "$(val discrepancies)" ;; esac

reset_stubs   # java with no mvn and no java runtime -> manager-not-found + tool-missing
run detect-tools --sdk java
[ -z "$(val default)" ] && ok "detect java: empty default when maven absent" || bad "detect java default" "$(val default)"
case "$(val discrepancies)" in *manager-not-found:maven*) ok "detect java: manager-not-found:maven" ;; *) bad "detect java manager-not-found" "$(val discrepancies)" ;; esac

reset_stubs
stub_java 1.8.0_292; stub_simple mvn "Apache Maven 3.9.6" -version
run detect-tools --sdk java
[ "$(val default)" = maven ] && ok "detect java: maven default when present" || bad "detect java maven default" "$(val default)"
case "$(val discrepancies)" in *version-too-old:java*) bad "java 8 wrongly flagged too-old (legacy 1.8 scheme)" "$(val discrepancies)" ;; *) ok "detect java: legacy 1.8 mapped to 8, not flagged (min 8)" ;; esac

# one RESULT block + ASCII + status line
reset_stubs; stub_python3 3.12.1
run detect-tools --sdk python
[ "$(printf '%s\n' "$OUT" | grep -c '=== RESULT ===')" -eq 1 ] && ok "detect: exactly one RESULT block" || bad "detect RESULT block count" "$(printf '%s\n' "$OUT" | grep -c '=== RESULT ===')"
LC_ALL=C grep -q '[^[:print:][:space:]]' "$WORK/out" && bad "detect RESULT stdout must be ASCII" || ok "detect: RESULT stdout is pure ASCII"

# ---------------------------------------------------------------------------
# preview — side-effect free
# ---------------------------------------------------------------------------
reset_stubs
PV_DIR="$WORK/should-not-exist"
run preview clone --sdk python --dir "$PV_DIR"
[ "$(val status)" = ok ] && [ ! -e "$PV_DIR" ] && ok "preview clone: no side effects (dir not created)" || bad "preview clone side effect" "exists? $([ -e "$PV_DIR" ] && echo yes)"
case "$(val cmd_1)" in *"git clone --branch money-transfer-project-cloud-setup"*) ok "preview clone: shows real clone command" ;; *) bad "preview clone cmd" "$(val cmd_1)" ;; esac

run preview run-workflow --sdk python --dir /tmp/x --demo-failure transient
[ "$(val workflow_id)" = money-transfer-demo-recovery ] && ok "preview run-workflow: recovery workflow id for transient" || bad "preview run-workflow wf id" "$(val workflow_id)"
case "$(val cmd_1)" in *DEMO_FAILURE=transient*) ok "preview run-workflow: shows DEMO_FAILURE in worker cmd" ;; *) bad "preview run-workflow demo" "$(val cmd_1)" ;; esac

run preview install-deps --sdk python --manager uv --dir /tmp/x
case "$(val cmd_1)" in *"uv venv env"*) ok "preview install-deps: uv command shown" ;; *) bad "preview install-deps uv" "$(val cmd_1)" ;; esac

run preview create-key --handle myns.acct --address myns.acct.tmprl.cloud:7233
case "$OUT" in *eyJ*) bad "preview create-key must not contain a token" ;; *) ok "preview create-key: no secret/token in output" ;; esac
[ "$(printf '%s\n' "$OUT" | grep -c '=== RESULT ===')" -eq 1 ] && ok "preview: one RESULT block" || bad "preview RESULT block count"

# every gated prerequisite subcommand has a preview disclosing its real command
reset_stubs   # no temporal on PATH -> install-cli preview discloses the install command
run preview install-cli
[ "$(val status)" = ok ] && case "$(val cmd_1)" in *temporal-cloud*|*temporal-cloud/releases*) ok "preview install-cli: discloses the install command" ;; *) bad "preview install-cli" "$(val cmd_1)" ;; esac || bad "preview install-cli status" "$OUT"
case "$(val cli_present)" in false) ok "preview install-cli: cli_present=false when absent" ;; *) bad "preview install-cli cli_present" "$OUT" ;; esac
# presence-aware: when the CLI is already installed, the preview discloses a skip (no install)
reset_stubs; stub_temporal   # temporal present -> 'temporal cloud version' succeeds
run preview install-cli
case "$(val cli_present)" in true) ok "preview install-cli: cli_present=true when installed" ;; *) bad "preview install-cli present" "$OUT" ;; esac
G="$(printf '%s\n' "$OUT" | sed -n '/^=== GATE ===$/,/^=== END GATE ===$/p')"
case "$G" in *'already installed'*) ok "GATE install-cli: discloses a skip when present" ;; *) bad "GATE install-cli present" "$G" ;; esac
case "$G" in *'brew install'*) bad "GATE install-cli must NOT show install when present" "$G" ;; *) ok "GATE install-cli: no install command when present" ;; esac

# install-cli skip path: version must come from `temporal --version`, NOT the
# `temporal cloud version` help line (the "version=The Temporal Cloud CLI…" bug)
reset_stubs; stub_temporal; stub_git
run install-cli
[ "$(val status)" = skipped ] && ok "install-cli: skips when CLI already present" || bad "install-cli skip" "$OUT"
case "$(val version)" in
  *"provides commands"*) bad "install-cli version must not be the 'cloud version' help line" "$(val version)" ;;
  "temporal version 9.9.9"*) ok "install-cli: version sourced from 'temporal --version'" ;;
  *) bad "install-cli version unexpected" "$(val version)" ;;
esac

# preflight.cli_installed uses the same cloud-group probe install-cli does, so the two
# never disagree — true when the cloud CLI works, false when temporal is absent
reset_stubs; stub_temporal; stub_git
run preflight --sdk python
[ "$(val cli_installed)" = true ] && ok "preflight: cli_installed=true when cloud CLI present" || bad "preflight cli_installed true" "$OUT"
reset_stubs; stub_git   # no temporal on PATH
run preflight --sdk python
[ "$(val cli_installed)" = false ] && ok "preflight: cli_installed=false when CLI absent" || bad "preflight cli_installed false" "$OUT"

run preview login
case "$(val cmd_1)" in *"temporal cloud login"*) ok "preview login: discloses 'temporal cloud login'" ;; *) bad "preview login" "$(val cmd_1)" ;; esac
run preview regions
case "$(val cmd_1)" in *"temporal cloud region list"*) ok "preview regions: discloses 'temporal cloud region list'" ;; *) bad "preview regions" "$(val cmd_1)" ;; esac
run preview await-auth
case "$(val cmd_1)" in *"workflow list"*) ok "preview await-auth: discloses the auth-poll command" ;; *) bad "preview await-auth" "$(val cmd_1)" ;; esac
run preview verify-config
case "$(val cmd_1)" in *"config list"*) ok "preview verify-config: discloses 'config list'" ;; *) bad "preview verify-config" "$(val cmd_1)" ;; esac
run preview bogus-subcommand
[ "$RC" -ne 0 ] && case "$OUT" in *error_code=bad-args*) ok "preview: unknown subcommand rejected" ;; *) bad "preview bogus" "$OUT" ;; esac || bad "preview bogus should fail" "rc=$RC"

# ---------------------------------------------------------------------------
# install-deps — runs the pinned command per manager; fail-fast errors
# ---------------------------------------------------------------------------
reset_stubs
stub_python3 3.12.1
REPO="$WORK/repo_py"; mkdir -p "$REPO"
run install-deps --sdk python --manager pip --dir "$REPO"
[ "$(val status)" = ok ] && [ "$(val manager)" = pip ] && ok "install-deps python/pip: status ok" || bad "install-deps python pip" "status=$(val status) rc=$RC err=$ERR"
grep -q "pip install -q temporalio" "$WORK/calls.log" && ok "install-deps python/pip: ran pip install temporalio" || bad "install-deps pip pinned cmd" "$(cat "$WORK/calls.log")"

reset_stubs
stub_python3 3.12.1; stub_uv 0.5.4
REPO="$WORK/repo_py2"; mkdir -p "$REPO"
run install-deps --sdk python --manager uv --dir "$REPO"
grep -q "uv venv env" "$WORK/calls.log" && grep -q "uv pip install" "$WORK/calls.log" \
  && ok "install-deps python/uv: ran 'uv venv' + 'uv pip install'" || bad "install-deps uv pinned cmd" "$(cat "$WORK/calls.log")"

reset_stubs   # unsupported (sdk,manager): python + poetry
REPO="$WORK/repo_py3"; mkdir -p "$REPO"; stub_python3 3.12.1
run install-deps --sdk python --manager poetry --dir "$REPO"
[ "$RC" -ne 0 ] && case "$OUT" in *error_code=unsupported-manager*) ok "install-deps: poetry rejected as unsupported for python" ;; *) bad "install-deps poetry" "$OUT" ;; esac || bad "install-deps poetry should fail" "rc=$RC"

reset_stubs   # manager-not-found: ts + pnpm but no pnpm binary
REPO="$WORK/repo_ts"; mkdir -p "$REPO/node_modules"; stub_simple node "v20.11.0"
run install-deps --sdk ts --manager pnpm --dir "$REPO"
[ "$RC" -ne 0 ] && case "$OUT" in *error_code=manager-not-found*) ok "install-deps: pnpm missing -> manager-not-found" ;; *) bad "install-deps pnpm missing" "$OUT" ;; esac || bad "install-deps pnpm should fail" "rc=$RC"

reset_stubs   # default manager when --manager omitted (ts -> npm)
REPO="$WORK/repo_ts2"; mkdir -p "$REPO"; stub_simple node "v20.11.0"; stub_simple npm "10.2.3"
run install-deps --sdk ts --dir "$REPO"
[ "$(val manager)" = npm ] && grep -q "npm install" "$WORK/calls.log" && ok "install-deps ts: default manager npm used + ran 'npm install'" || bad "install-deps ts default" "manager=$(val manager) log=$(cat "$WORK/calls.log")"

# ---------------------------------------------------------------------------
# provision-and-scaffold — manager validation is FAIL-FAST, before any resource
# (namespace create / clone). temporal+git are tripwires: assert git is never
# reached when the manager choice is rejected.
# ---------------------------------------------------------------------------
reset_stubs
stub_temporal; stub_git; stub_python3 3.12.1
run provision-and-scaffold --sdk python --region aws-us-east-1 --manager poetry --dir "$WORK/ps_unsup"
[ "$RC" -ne 0 ] && case "$OUT" in *error_code=unsupported-manager*) ok "p&s: unsupported manager rejected" ;; *) bad "p&s unsupported" "$OUT" ;; esac || bad "p&s unsupported should fail" "rc=$RC"
grep -q '^git ' "$WORK/calls.log" && bad "p&s fail-fast: git (clone) must NOT run on bad manager" "$(cat "$WORK/calls.log")" || ok "p&s fail-fast: no clone attempted on unsupported manager"
grep -q 'namespace create' "$WORK/calls.log" && bad "p&s fail-fast: namespace create must NOT run on bad manager" || ok "p&s fail-fast: no namespace created on unsupported manager"
[ ! -e "$WORK/ps_unsup" ] && ok "p&s fail-fast: clone dir not created" || bad "p&s fail-fast clone dir exists"

reset_stubs
stub_temporal; stub_git; stub_simple node "v20.11.0"   # ts + pnpm but pnpm absent
run provision-and-scaffold --sdk ts --region aws-us-east-1 --manager pnpm --dir "$WORK/ps_missing"
[ "$RC" -ne 0 ] && case "$OUT" in *error_code=manager-not-found*) ok "p&s: missing manager -> manager-not-found" ;; *) bad "p&s manager-not-found" "$OUT" ;; esac || bad "p&s missing manager should fail" "rc=$RC"
grep -q '^git ' "$WORK/calls.log" && bad "p&s fail-fast: git must NOT run when manager missing" || ok "p&s fail-fast: no clone when manager missing"

# preview/detect make ZERO temporal or git calls (network tripwire)
reset_stubs
stub_temporal; stub_git; stub_python3 3.12.1; stub_uv 0.5.4
run preview provision-and-scaffold --sdk python --region aws-us-east-1 --manager uv
grep -qE '^(git|temporal) ' "$WORK/calls.log" && bad "preview must make no git/temporal calls" "$(cat "$WORK/calls.log")" || ok "preview: zero git/temporal calls (side-effect-free)"
run detect-tools --sdk python
grep -qE '^(git|temporal) ' "$WORK/calls.log" && bad "detect-tools must make no git/temporal calls" "$(cat "$WORK/calls.log")" || ok "detect-tools: zero git/temporal calls"

# ---------------------------------------------------------------------------
# --async namespace split (PE-75): start-namespace / await-namespace / scaffold
# ---------------------------------------------------------------------------
reset_stubs
stub_temporal_list '{}'
run start-namespace --sdk python --region aws-us-east-1
[ "$(val status)" = ok ] && case "$(val namespace_name)" in quickstartai-*) ok "start-namespace: returns generated namespace_name" ;; *) bad "start-namespace name" "$(val namespace_name)" ;; esac || bad "start-namespace status" "$OUT"
grep -q 'namespace create' "$WORK/calls.log" && grep -q -- '--async' "$WORK/calls.log" && ok "start-namespace: submits 'namespace create … --async'" || bad "start-namespace --async" "$(cat "$WORK/calls.log")"
case "$OUT" in *job=*) bad "start-namespace must not emit a local job token (fire-and-forget)" ;; *) ok "start-namespace: no local job token (server-side async)" ;; esac

reset_stubs   # ACTIVE (state==3): resolves, and reads the address from endpoints
stub_temporal_list '{"Namespaces":[{"namespace":"testns.acct42","spec":{"name":"testns"},"state":3,"endpoints":{"mtls_grpc_address":"testns.acct42.tmprl.cloud:7233"}}]}'
NS_AWAIT_MAX_SECS=4 run await-namespace --name testns
[ "$(val status)" = ok ] && [ "$(val namespace_handle)" = testns.acct42 ] && ok "await-namespace: resolves handle of an ACTIVE namespace" || bad "await-namespace handle" "$OUT"
[ "$(val address)" = testns.acct42.tmprl.cloud:7233 ] && ok "await-namespace: reads address from endpoints.mtls_grpc_address" || bad "await-namespace address" "$(val address)"

reset_stubs   # still ACTIVATING (state==1): must NOT resolve, and must NOT be mistaken for a
              # phantom even with a tiny grace — it APPEARED, so it times out (not fail-fast).
stub_temporal_list '{"Namespaces":[{"namespace":"provns.acct42","spec":{"name":"provns"},"state":1}]}'
NS_PHANTOM_GRACE_SECS=2 NS_AWAIT_MAX_SECS=6 run await-namespace --name provns
[ "$RC" -ne 0 ] && case "$OUT" in *error_code=namespace-timeout*) ok "await-namespace: ACTIVATING namespace times out (not phantom-failed)" ;; *) bad "await-namespace activating" "$OUT" ;; esac || bad "await-namespace must wait for ACTIVE" "rc=$RC"

reset_stubs   # PHANTOM: create accepted but namespace never appears -> fail FAST (not full timeout)
stub_temporal_list '{"Namespaces":[]}'
NS_PHANTOM_GRACE_SECS=2 NS_AWAIT_MAX_SECS=30 run await-namespace --name ghostns
[ "$RC" -ne 0 ] && case "$OUT" in *error_code=namespace-not-provisioning*) ok "await-namespace: phantom (never appears) fails fast" ;; *) bad "await-namespace phantom" "$OUT" ;; esac || bad "await-namespace phantom should fail fast" "rc=$RC"

reset_stubs   # mtls absent but grpc present -> use the API's grpc_address (never construct)
stub_temporal_list '{"Namespaces":[{"namespace":"gonly.acct42","spec":{"name":"gonly"},"state":3,"endpoints":{"grpc_address":"centralus.azure.api.temporal.io:7233"}}]}'
NS_AWAIT_MAX_SECS=4 run await-namespace --name gonly
[ "$(val address)" = centralus.azure.api.temporal.io:7233 ] && ok "await-namespace: falls back to API grpc_address when mtls absent" || bad "await-namespace grpc fallback" "$(val address)"

reset_stubs   # endpoints absent on an ACTIVE namespace -> address falls back to constructed (last resort)
stub_temporal_list '{"Namespaces":[{"namespace":"noep.acct42","spec":{"name":"noep"},"state":3}]}'
NS_AWAIT_MAX_SECS=4 run await-namespace --name noep
[ "$(val address)" = noep.acct42.tmprl.cloud:7233 ] && ok "await-namespace: constructs only as last resort when both endpoints absent" || bad "await-namespace fallback address" "$(val address)"

reset_stubs
stub_temporal_list '{"Namespaces":[]}'
NS_AWAIT_MAX_SECS=4 run await-namespace --name missingns
[ "$RC" -ne 0 ] && case "$OUT" in *error_code=namespace-timeout*) ok "await-namespace: times out when namespace never appears" ;; *) bad "await-namespace timeout" "$OUT" ;; esac || bad "await-namespace should time out" "rc=$RC"

reset_stubs   # region guard: flag CloudProvider=UNKNOWN regions (e.g. azure-centralus phantom)
make_stub temporal <<'BODY'
#!/bin/sh
echo "temporal $*" >> "$STUB_LOG"
case "$*" in
  *whoami*) echo "u@e.com"; exit 0 ;;
  *"region list"*) printf '%s\n' "                Id         CloudProvider  CloudProviderRegion
  aws-ca-central-1  AWS            ca-central-1
  azure-centralus   UNKNOWN        centralus
  gcp-us-central1   GCP            us-central1"; exit 0 ;;
esac
exit 0
BODY
run regions
[ "$(val unsupported_regions)" = azure-centralus ] && ok "regions: flags CloudProvider=UNKNOWN region (azure-centralus)" || bad "regions guard" "$OUT"
case "$(val unsupported_regions)" in *aws-ca-central-1*|*gcp-us-central1*) bad "regions: must not flag AWS/GCP regions" "$(val unsupported_regions)" ;; *) ok "regions: AWS/GCP regions not flagged" ;; esac

# ---------------------------------------------------------------------------
# create-key token capture (PE-75): tolerate CLI output drift; never print the token
# ---------------------------------------------------------------------------
reset_stubs   # clean path: key JSON on stdout
make_stub temporal <<'BODY'
#!/bin/sh
echo "temporal $*" >> "$STUB_LOG"
case "$*" in
  *whoami*) echo "user@example.com"; exit 0 ;;
  *"apikey create-for-me"*) printf '{"token":"eyJAAA.eyJBBB.sigCCC","keyId":"KID0123456789ABCD"}\n'; exit 0 ;;
esac
exit 0
BODY
CKCFG="$WORK/ck-json/temporal.toml"
export TEMPORAL_CONFIG_FILE="$CKCFG"; run create-key --handle n.acct42 --address n.acct42.tmprl.cloud:7233; unset TEMPORAL_CONFIG_FILE
{ [ "$(val status)" = ok ] && [ "$(val key_id)" = KID0123456789ABCD ]; } && ok "create-key: JSON-on-stdout path captures token + key_id" || bad "create-key json path" "$OUT $ERR"
grep -q 'api_key = "eyJAAA.eyJBBB.sigCCC"' "$CKCFG" 2>/dev/null && ok "create-key: token written into the profile (json path)" || bad "create-key json profile write" "$(cat "$CKCFG" 2>&1)"
case "$OUT$ERR" in *eyJAAA*) bad "create-key (json) must never print the token" ;; *) ok "create-key: token never printed (json path)" ;; esac
# display-name must be randomized (a bare fixed name errors on re-run: "already exists")
grep -qE 'apikey create-for-me .*--display-name money-transfer-cloud-setup-[a-z0-9]+' "$WORK/calls.log" && ok "create-key: display-name is randomized (avoids same-name conflict)" || bad "create-key display-name not randomized" "$(grep create-for-me "$WORK/calls.log")"

reset_stubs   # OUTPUT DRIFT: key emitted to STDERR / human text, nothing on stdout
make_stub temporal <<'BODY'
#!/bin/sh
echo "temporal $*" >> "$STUB_LOG"
case "$*" in
  *whoami*) echo "user@example.com"; exit 0 ;;
  *"apikey create-for-me"*) echo "API key created. Save it now: eyJZZZ.eyJYYY.sigXXX" >&2; exit 0 ;;
esac
exit 0
BODY
CKCFG2="$WORK/ck-stderr/temporal.toml"
export TEMPORAL_CONFIG_FILE="$CKCFG2"; run create-key --handle n.acct42 --address n.acct42.tmprl.cloud:7233; unset TEMPORAL_CONFIG_FILE
[ "$(val status)" = ok ] && ok "create-key: recovers a token emitted on stderr (output-drift fix)" || bad "create-key stderr capture" "$OUT $ERR"
grep -q 'api_key = "eyJZZZ.eyJYYY.sigXXX"' "$CKCFG2" 2>/dev/null && ok "create-key: stderr token written into the profile" || bad "create-key stderr profile write" "$(cat "$CKCFG2" 2>&1)"
case "$OUT$ERR" in *eyJZZZ*) bad "create-key (stderr) must never print the token" ;; *) ok "create-key: token never printed (stderr path)" ;; esac

reset_stubs   # genuine empty: nothing on EITHER stream + exit 0 -> key-empty
make_stub temporal <<'BODY'
#!/bin/sh
echo "temporal $*" >> "$STUB_LOG"
case "$*" in *whoami*) echo "user@example.com"; exit 0 ;; esac
exit 0
BODY
export TEMPORAL_CONFIG_FILE="$WORK/ck-empty/temporal.toml"; run create-key --handle n.acct42 --address n.acct42.tmprl.cloud:7233; unset TEMPORAL_CONFIG_FILE
[ "$RC" -ne 0 ] && case "$OUT" in *error_code=key-empty*) ok "create-key: both streams empty -> key-empty" ;; *) bad "create-key empty" "$OUT" ;; esac || bad "create-key should fail when nothing returned" "rc=$RC"

reset_stubs   # scaffold = clone + deps, no namespace/temporal calls
stub_git; stub_python3 3.12.1
REPO="$WORK/scaffold_py"
run scaffold --sdk python --manager pip --dir "$REPO"
[ "$(val status)" = ok ] && [ "$(val manager)" = pip ] && ok "scaffold: clone+deps status ok" || bad "scaffold status" "$OUT $ERR"
grep -q '^git clone' "$WORK/calls.log" && grep -q 'pip install -q temporalio' "$WORK/calls.log" && ok "scaffold: ran git clone + pip install" || bad "scaffold commands" "$(cat "$WORK/calls.log")"
grep -q '^temporal ' "$WORK/calls.log" && bad "scaffold must not touch temporal/namespace" || ok "scaffold: no namespace/temporal calls"

reset_stubs   # scaffold fail-fast on unsupported manager (before clone)
stub_git; stub_python3 3.12.1
run scaffold --sdk python --manager poetry --dir "$WORK/scaffold_bad"
[ "$RC" -ne 0 ] && case "$OUT" in *error_code=unsupported-manager*) ok "scaffold: unsupported manager rejected before clone" ;; *) bad "scaffold unsupported" "$OUT" ;; esac || bad "scaffold unsupported should fail" "rc=$RC"
grep -q '^git clone' "$WORK/calls.log" && bad "scaffold fail-fast: must not clone on bad manager" || ok "scaffold fail-fast: no clone on bad manager"

# preview covers the split subcommands
reset_stubs
run preview start-namespace --region aws-us-east-1
case "$(val cmd_1)" in *"namespace create"*"--async"*) ok "preview start-namespace: discloses the --async create" ;; *) bad "preview start-namespace" "$(val cmd_1)" ;; esac
run preview await-namespace
case "$(val cmd_1)" in *"namespace list"*) ok "preview await-namespace: discloses the list poll" ;; *) bad "preview await-namespace" "$(val cmd_1)" ;; esac
run preview scaffold --sdk python --manager uv
case "$(val cmd_1)" in *"git clone"*) ok "preview scaffold: discloses git clone" ;; *) bad "preview scaffold" "$(val cmd_1)" ;; esac

# global-cache installs are flagged as GLOBAL/outside-the-repo; local ones as in-the-repo (#2)
run preview scaffold --sdk java
case "$OUT" in *"GLOBAL, outside the repo"*) ok "install disclosure: java flags the GLOBAL Maven cache" ;; *) bad "java global-cache flag" "$OUT" ;; esac
run preview scaffold --sdk go
case "$OUT" in *"GLOBAL, outside the repo"*) ok "install disclosure: go flags the GLOBAL module cache" ;; *) bad "go global-cache flag" "$OUT" ;; esac
run preview install-deps --sdk dotnet
case "$OUT" in *"GLOBAL, outside the repo"*) ok "install disclosure: dotnet flags the GLOBAL NuGet cache" ;; *) bad "dotnet global-cache flag" "$OUT" ;; esac
run preview scaffold --sdk python --manager pip
case "$OUT" in *"inside the repo"*) ok "install disclosure: python notes local venv (not global)" ;; *) bad "python local flag" "$OUT" ;; esac
case "$OUT" in *GLOBAL*) bad "python must NOT be flagged GLOBAL" "$OUT" ;; *) ok "install disclosure: python not mislabeled GLOBAL" ;; esac

# ---------------------------------------------------------------------------
# preview emits a ready-to-render === GATE === block (PE-75 determinism lever)
# ---------------------------------------------------------------------------
gate() { printf '%s\n' "$OUT" | sed -n '/^=== GATE ===$/,/^=== END GATE ===$/p'; }
reset_stubs
run preview start-namespace --region aws-us-east-1
[ "$(printf '%s\n' "$OUT" | grep -c '^=== GATE ===$')" -eq 1 ] && ok "preview: emits exactly one GATE block" || bad "GATE block count" "$OUT"
G="$(gate)"
case "$G" in *'**Creating your Cloud namespace**'*) ok "GATE: has bold heading" ;; *) bad "GATE heading" "$G" ;; esac
case "$G" in *'```bash'*) ok "GATE: has a bash fence" ;; *) bad "GATE fence" "$G" ;; esac
printf '%s\n' "$G" | grep -qE '^> ' && bad "GATE must not be blockquoted" "$G" || ok "GATE: not blockquoted"
# gate has no "# ----" divider lines (heading + fenced commands only)
[ "$(printf '%s\n' "$G" | grep -cE '^# -{6,}$')" -eq 0 ] && ok "GATE: no divider lines" || bad "GATE unexpected dividers" "$G"
case "$G" in *'namespace create'*'--async'*) ok "GATE: discloses the real --async command" ;; *) bad "GATE command" "$G" ;; esac
case "$G" in *'# create your Cloud namespace'*) ok "GATE: comment above the command" ;; *) bad "GATE comment" "$G" ;; esac
LC_ALL=C printf '%s' "$G" | grep -q '[^[:print:][:space:]]' && bad "GATE block must be ASCII" || ok "GATE: ASCII-clean"

reset_stubs
run preview run-workflow --sdk python --dir repo-x --demo-failure transient
G="$(gate)"
case "$G" in *'**Run the recovery Workflow (inject a failure)**'*) ok "GATE run-workflow: demo heading" ;; *) bad "GATE rw heading" "$G" ;; esac
case "$G" in *'DEMO_FAILURE=transient'*python\ run_worker.py*) ok "GATE run-workflow: worker command present" ;; *) bad "GATE rw worker" "$G" ;; esac
case "$G" in *run_workflow.py*) ok "GATE run-workflow: starter command present" ;; *) bad "GATE rw starter" "$G" ;; esac

# run-workflow fast-fail: starter exits 0 but submits NO workflow (e.g. a client that
# swallows its connect/start error and exits 0, like the .NET sample) -> fail fast with
# workflow-not-submitted instead of burning the full --max-secs as a misleading timeout.
reset_stubs
make_stub go <<'BODY'
#!/bin/sh
echo "go $*" >> "$STUB_LOG"
case "$*" in
  *worker*) sleep 30 ;;          # worker stays "alive" so readiness proceeds
  *start*)  exit 0 ;;            # starter exits 0, prints no run id, submits nothing
esac
exit 0
BODY
make_stub temporal <<'BODY'
#!/bin/sh
echo "temporal $*" >> "$STUB_LOG"
case "$*" in
  *whoami*) echo "u@e.com"; exit 0 ;;
  *"task-queue describe"*) printf '{"pollers":[{"identity":"w"}]}'; exit 0 ;;  # worker registers
  *"workflow describe"*) printf '' ; exit 0 ;;  # no workflow ever exists
  *"workflow list"*) printf '[]'; exit 0 ;;
esac
exit 0
BODY
mkdir -p "$WORK/gorepo"
NOWF_SETTLE_SECS=4 WORKER_READY_MAX_SECS=12 RUN_WF_MAX_SECS=20 run run-workflow --sdk go --dir "$WORK/gorepo"
[ "$RC" -ne 0 ] && case "$OUT" in *error_code=workflow-not-submitted*) ok "run-workflow: fast-fails when starter exits 0 but no workflow is submitted" ;; *) bad "run-workflow fast-fail" "$OUT" ;; esac || bad "run-workflow should fast-fail, not time out" "rc=$RC $OUT"

reset_stubs
run preview scaffold --sdk python --manager uv --dir repo-y
G="$(gate)"
case "$G" in *'git clone --branch money-transfer-project-cloud-setup'*'uv venv env'*) ok "GATE scaffold: clone + install both present" ;; *) bad "GATE scaffold" "$G" ;; esac

reset_stubs
run preview login
G="$(gate)"
case "$G" in *'temporal cloud login'*'temporal cloud whoami'*) ok "GATE login: both commands present" ;; *) bad "GATE login" "$G" ;; esac

reset_stubs
run preview preflight --sdk python
G="$(gate)"
case "$G" in *'command -v git jq brew'*) ok "GATE preflight: discloses the env probes" ;; *) bad "GATE preflight" "$G" ;; esac
case "$G" in *'TEMPORAL_'*) ok "GATE preflight: discloses the stray-env check" ;; *) bad "GATE preflight env" "$G" ;; esac

reset_stubs
run preview detect-tools --sdk python
G="$(gate)"
case "$G" in *'command -v python3 uv'*) ok "GATE detect-tools: discloses the manager probes" ;; *) bad "GATE detect-tools" "$G" ;; esac

# utility subcommands must ALSO emit a gate (so any provision.sh call is disclosable)
reset_stubs
run preview install-deps --sdk python --manager uv --dir repo-z
G="$(gate)"
case "$G" in *'```bash'*'uv venv env'*) ok "GATE install-deps: discloses the install command" ;; *) bad "GATE install-deps" "$G" ;; esac
reset_stubs
run preview clone --sdk python
G="$(gate)"
case "$G" in *'git clone --branch money-transfer-project-cloud-setup'*) ok "GATE clone: discloses the clone command" ;; *) bad "GATE clone" "$G" ;; esac
reset_stubs
run preview repair-config
G="$(gate)"
case "$G" in *'profile.cloud-setup'*) ok "GATE repair-config: discloses what it strips" ;; *) bad "GATE repair-config" "$G" ;; esac

# create-key disclosure must never carry the token (the source the floor reuses)
reset_stubs
run preview create-key --handle myns.acct --address myns.acct.tmprl.cloud:7233
G="$(gate)"
case "$G" in *'apikey create-for-me'*) ok "GATE create-key: discloses the mint command" ;; *) bad "GATE create-key cmd" "$G" ;; esac
case "$G" in *eyJ*) bad "GATE create-key must never show a token" "$G" ;; *) ok "GATE create-key: tokenless disclosure" ;; esac

# ---------------------------------------------------------------------------
# disclosure floor (PE-75) — every effectful subcommand echoes its gate to
# STDERR before acting, so the tool block records what ran even when the agent
# skips the chat-side gate (the Cursor "sometimes doesn't disclose" failure).
# It reuses cmd_preview, so it can't drift from the real command.
# ---------------------------------------------------------------------------
reset_stubs
stub_python3 3.12.1; stub_uv 0.5.4
run detect-tools --sdk python
case "$ERR" in *'disclosure — the command(s) this step runs'*) ok "disclosure floor: effectful subcommand echoes its gate to stderr" ;; *) bad "disclosure floor stderr" "$ERR" ;; esac
case "$ERR" in *'command -v python3 uv'*) ok "disclosure floor: the echo carries the real command(s)" ;; *) bad "disclosure floor cmd" "$ERR" ;; esac
# stdout RESULT must stay machine-clean — no disclosure prose, no GATE markers
case "$OUT" in *'disclosure —'*) bad "disclosure floor must not touch stdout" "$OUT" ;; *) ok "disclosure floor: stdout has no disclosure prose" ;; esac
case "$OUT" in *'=== GATE ==='*) bad "disclosure floor must not leak GATE markers to stdout" "$OUT" ;; *) ok "disclosure floor: stdout RESULT stays machine-clean" ;; esac

# opt-out for clean test/quiet contexts
reset_stubs
stub_python3 3.12.1; stub_uv 0.5.4
TCLOUD_DISCLOSE=0 STUB_LOG="$WORK/calls.log" PATH="$STUB" /bin/bash "$PROVISION" detect-tools --sdk python >"$WORK/out" 2>"$WORK/err"
ERR="$(cat "$WORK/err")"; OUT="$(cat "$WORK/out")"
case "$ERR" in *'disclosure —'*) bad "TCLOUD_DISCLOSE=0 should suppress the echo" "$ERR" ;; *) ok "disclosure floor: TCLOUD_DISCLOSE=0 suppresses the echo" ;; esac
case "$OUT" in *'status=ok'*) ok "disclosure floor: command still runs normally with disclosure off" ;; *) bad "disclosure off still runs" "$OUT" ;; esac

# preview/help don't act → no disclosure echo (cmd_preview can't render them anyway)
reset_stubs
run preview detect-tools --sdk python
case "$ERR" in *'disclosure —'*) bad "preview must not emit the disclosure floor (it IS the gate)" "$ERR" ;; *) ok "disclosure floor: preview is exempt (no double echo)" ;; esac

# ---------------------------------------------------------------------------
# preflight arg convention — --sdk (standard) + bare positional (back-compat)
# ---------------------------------------------------------------------------
reset_stubs; stub_temporal; stub_git
run preflight --sdk python
case "$(val status)" in ok) ok "preflight: accepts --sdk" ;; *) bad "preflight --sdk" "$OUT" ;; esac
case "$(val repo_url)" in *money-transfer-project-template-python) ok "preflight --sdk: resolves repo_url" ;; *) bad "preflight --sdk repo_url" "$OUT" ;; esac
reset_stubs; stub_temporal; stub_git
run preflight python
case "$(val status)" in ok) ok "preflight: positional <sdk> still works (back-compat)" ;; *) bad "preflight positional" "$OUT" ;; esac
reset_stubs; stub_temporal; stub_git
run preflight --bogus x
case "$(val error_code)" in bad-args) ok "preflight: rejects an unknown flag" ;; *) bad "preflight bad flag" "$OUT" ;; esac

# ---------------------------------------------------------------------------
# preview.sh — the read-only disclosure shim forwards to `provision.sh preview`
# ---------------------------------------------------------------------------
PREVIEW_SH="$(cd "$HERE/.." && pwd)/preview.sh"
[ -x "$PREVIEW_SH" ] && ok "preview.sh: exists and is executable" || bad "preview.sh missing/not executable" "$PREVIEW_SH"
reset_stubs
STUB_LOG="$WORK/calls.log" PATH="$STUB" /bin/bash "$PREVIEW_SH" preflight --sdk python >"$WORK/out" 2>"$WORK/err"
OUT="$(cat "$WORK/out")"
SHIM_G="$(printf '%s\n' "$OUT" | sed -n '/^=== GATE ===$/,/^=== END GATE ===$/p')"
case "$SHIM_G" in *'**Checking your environment**'*'command -v git jq brew'*) ok "preview.sh: forwards and emits the same GATE block" ;; *) bad "preview.sh forward" "$OUT" ;; esac
[ "$(printf '%s\n' "$OUT" | grep -c '^=== GATE ===$')" -eq 1 ] && ok "preview.sh: emits exactly one GATE block" || bad "preview.sh GATE count" "$OUT"

# ---------------------------------------------------------------------------
# Drift guard (PE-75): disclosure now lives in SKILL.md's §Gate templates (agent-rendered,
# no preview.sh call). Every distinctive command the templates SHOW the user must also be
# what provision.sh actually RUNS — otherwise disclosure would lie. Bind them: assert each
# skeleton appears in BOTH files. Plus: no real token literal may ever sit in SKILL.md.
# ---------------------------------------------------------------------------
SKILL_MD="$(cd "$HERE/../.." && pwd)/SKILL.md"
[ -f "$SKILL_MD" ] && ok "drift: SKILL.md found" || bad "drift: SKILL.md missing" "$SKILL_MD"

drift_check() {  # <label> <substring that must be in BOTH SKILL.md and provision.sh>
  local label="$1" sub="$2"
  grep -qF -- "$sub" "$SKILL_MD" || { bad "drift: '$label' missing from SKILL.md gate templates" "$sub"; return; }
  grep -qF -- "$sub" "$PROVISION" || { bad "drift: '$label' missing from provision.sh runtime" "$sub"; return; }
  ok "drift: '$label' matches (SKILL.md gate == provision.sh runtime)"
}

drift_check "namespace create"       "temporal cloud namespace create --name"
drift_check "namespace list --name"  "temporal cloud namespace list --name"
drift_check "region list"            "temporal cloud region list"
drift_check "login"                  "temporal cloud login"
drift_check "apikey create-for-me"   "temporal cloud apikey create-for-me"
drift_check "config list"            "temporal --profile cloud-setup config list"
drift_check "workflow list"          "temporal --profile cloud-setup workflow list"
drift_check "git clone branch"       "git clone --branch money-transfer-project-cloud-setup --single-branch"
drift_check "brew install cli"       "brew install temporalio/prerelease/temporal-cloud"
drift_check "py worker"              "python run_worker.py"
drift_check "py starter"            "python run_workflow.py"
drift_check "go worker"              "go run worker/main.go"
drift_check "ts worker"              "npm run worker"
drift_check "java worker"            "moneytransferapp.MoneyTransferWorker"
drift_check "dotnet worker"          "dotnet run --project MoneyTransferWorker"
drift_check "ruby worker"            "ruby worker.rb"
drift_check "pip install"            "python3 -m venv env"
drift_check "uv install"             "uv venv env"
drift_check "go mod download"        "go mod download"
drift_check "maven install"          "mvn -q -DskipTests dependency:resolve"
drift_check "dotnet restore"         "dotnet restore"
drift_check "bundler install"        "bundle install"

# Secret guard: SKILL.md may MENTION "eyJ…" when explaining the carve-out, but must never
# contain a real token literal (eyJ followed by base64). Match only the real-token shape.
grep -qE 'eyJ[A-Za-z0-9_-]{6,}' "$SKILL_MD" && bad "drift: SKILL.md contains a real eyJ token literal" || ok "drift: SKILL.md has no real token literal"

# ---------------------------------------------------------------------------
echo "-----------------------------------------"
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]