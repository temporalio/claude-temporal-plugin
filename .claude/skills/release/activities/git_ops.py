"""Activities for git and GitHub CLI operations in the release pipeline."""

import json
import os
import re
import shutil
import subprocess
from pathlib import Path

from temporalio import activity

from models import ActivityResult

# Resolve paths relative to the outer repo root.
# The worker must be started from the outer repo root, or OUTER_ROOT must be set.
OUTER_ROOT = Path(os.environ.get("OUTER_ROOT", Path(__file__).resolve().parents[4]))
SUBMODULE_PATH = "plugins/temporal-developer/skills/temporal-developer"
SUBMODULE_ABS = OUTER_ROOT / SUBMODULE_PATH
SKILL_MD = SUBMODULE_ABS / "SKILL.md"
PLUGIN_JSON = OUTER_ROOT / "plugins/temporal-developer/.claude-plugin/plugin.json"
CODEX_FORK = "temporalio/openai-plugins"
CODEX_UPSTREAM = "openai/plugins"
CODEX_BRANCH = "temporal"


def _run(cmd: str, cwd: Path | None = None) -> subprocess.CompletedProcess:
    """Run a shell command, raising on failure."""
    activity.logger.info(f"Running: {cmd} (cwd={cwd or '.'})")
    result = subprocess.run(
        cmd, shell=True, capture_output=True, text=True, cwd=cwd
    )
    if result.returncode != 0:
        raise RuntimeError(f"Command failed: {cmd}\nstderr: {result.stderr}\nstdout: {result.stdout}")
    return result


def _current_version() -> str:
    text = SKILL_MD.read_text()
    match = re.search(r"^version:\s*(.+)$", text, re.MULTILINE)
    if not match:
        raise RuntimeError("Could not find version in SKILL.md")
    return match.group(1).strip()


def _bump_version(current: str, level: str) -> str:
    parts = current.split(".")
    major, minor, patch = int(parts[0]), int(parts[1]), int(parts[2])
    if level == "major":
        return f"{major + 1}.0.0"
    elif level == "minor":
        return f"{major}.{minor + 1}.0"
    elif level == "patch":
        return f"{major}.{minor}.{patch + 1}"
    else:
        raise ValueError(f"Invalid level: {level}")


# --- Preflight ---


def _check_repos(expected_branch: str) -> list[str]:
    """Check both repos are clean and on the expected branch."""
    errors = []
    for label, path in [("Outer repo", OUTER_ROOT), ("Submodule", SUBMODULE_ABS)]:
        diff = subprocess.run(
            "git diff --quiet && git diff --cached --quiet",
            shell=True, cwd=path
        )
        if diff.returncode != 0:
            errors.append(f"{label} has uncommitted changes.")

        untracked = subprocess.run(
            "git ls-files --others --exclude-standard",
            shell=True, capture_output=True, text=True, cwd=path
        )
        if untracked.stdout.strip():
            errors.append(f"{label} has untracked files.")

        branch = subprocess.run(
            "git branch --show-current",
            shell=True, capture_output=True, text=True, cwd=path
        )
        if branch.stdout.strip() != expected_branch:
            errors.append(f"{label} is on branch '{branch.stdout.strip()}', expected '{expected_branch}'.")

    return errors


@activity.defn
def preflight_checks() -> ActivityResult:
    """Verify both repos are clean and on dev."""
    errors = _check_repos("dev")
    if errors:
        return ActivityResult(success=False, error="\n".join(errors))
    return ActivityResult(success=True, output="Preflight checks passed.")


@activity.defn
def preflight_checks_codex() -> ActivityResult:
    """Verify both repos are clean and on main (for codex-only releases)."""
    errors = _check_repos("main")
    if errors:
        return ActivityResult(success=False, error="\n".join(errors))
    return ActivityResult(success=True, output="Preflight checks passed (codex-only, on main).")


# --- Version ---


@activity.defn
def get_version_info(level: str) -> ActivityResult:
    """Get current version and compute new version."""
    current = _current_version()
    new = _bump_version(current, level)
    return ActivityResult(success=True, output=json.dumps({"current": current, "new": new}))


# --- Phase 1: Internal Release ---


@activity.defn
def internal_release(new_version: str) -> ActivityResult:
    """Phase 1: version bump PR to submodule dev, update outer dev."""
    current = _current_version()
    branch = f"release/v{new_version}"

    activity.logger.info(f"Internal release: {current} → {new_version}")

    # --- Submodule: version bump PR to dev ---
    _run("git checkout dev && git pull origin dev", cwd=SUBMODULE_ABS)
    _run(f"git checkout -b {branch}", cwd=SUBMODULE_ABS)

    # Bump version in SKILL.md
    text = SKILL_MD.read_text()
    text = text.replace(f"version: {current}", f"version: {new_version}", 1)
    SKILL_MD.write_text(text)

    # Verify
    actual = _current_version()
    if actual != new_version:
        return ActivityResult(success=False, error=f"Version bump failed: expected {new_version}, got {actual}")

    _run("git add SKILL.md", cwd=SUBMODULE_ABS)
    _run(f'git commit -m "Bump version to {new_version}"', cwd=SUBMODULE_ABS)
    _run(f"git push -u origin {branch}", cwd=SUBMODULE_ABS)

    # Create PR to dev and merge it
    pr_result = _run(
        f'gh pr create --repo temporalio/skill-temporal-developer '
        f'--base dev --head {branch} '
        f'--title "Release v{new_version}" '
        f'--body "Bump skill version to {new_version}."',
        cwd=SUBMODULE_ABS,
    )
    pr_url = pr_result.stdout.strip()
    activity.logger.info(f"PR created: {pr_url}")

    _run(f"gh pr merge {pr_url} --merge --delete-branch", cwd=SUBMODULE_ABS)
    activity.logger.info("Release branch merged to submodule dev.")

    # --- Outer repo: update submodule pointer + plugin.json on dev ---
    _run("git checkout dev && git pull origin dev", cwd=OUTER_ROOT)
    _run("git checkout dev && git pull origin dev", cwd=SUBMODULE_ABS)

    # Bump plugin.json
    pj = json.loads(PLUGIN_JSON.read_text())
    pj["version"] = new_version
    PLUGIN_JSON.write_text(json.dumps(pj, indent=2) + "\n")

    _run(f"git add {SUBMODULE_PATH} {PLUGIN_JSON.relative_to(OUTER_ROOT)}", cwd=OUTER_ROOT)
    _run(
        f'git commit -m "Release v{new_version}: update submodule pointer and plugin.json on dev"',
        cwd=OUTER_ROOT,
    )
    _run("git push origin dev", cwd=OUTER_ROOT)

    return ActivityResult(
        success=True,
        output=f"Phase 1 complete. Both repos on dev at v{new_version}.",
    )


# --- Phase 2: External Release ---


@activity.defn
def create_release_pr(new_version: str) -> ActivityResult:
    """Create submodule dev→main PR (requires human review)."""
    _run("git checkout dev && git pull origin dev", cwd=SUBMODULE_ABS)

    pr_result = _run(
        f'gh pr create --repo temporalio/skill-temporal-developer '
        f'--base main --head dev '
        f'--title "Release v{new_version}" '
        f'--body "Merge dev → main for v{new_version} release."',
        cwd=SUBMODULE_ABS,
    )
    pr_url = pr_result.stdout.strip()
    return ActivityResult(success=True, pr_url=pr_url, output=f"Release PR: {pr_url}")


@activity.defn
def complete_external_release(new_version: str) -> ActivityResult:
    """After submodule PR merged: update outer dev pointer to submodule main, merge outer dev→main."""
    _run("git checkout dev && git pull origin dev", cwd=OUTER_ROOT)

    # Update submodule to main
    _run("git fetch origin && git checkout main && git pull origin main", cwd=SUBMODULE_ABS)
    _run(f"git add {SUBMODULE_PATH}", cwd=OUTER_ROOT)

    # Commit (may be no-op if pointer already correct)
    commit_result = subprocess.run(
        f'git commit -m "Release v{new_version}: point submodule to main"',
        shell=True, capture_output=True, text=True, cwd=OUTER_ROOT,
    )
    if commit_result.returncode == 0:
        _run("git push origin dev", cwd=OUTER_ROOT)

    # Merge outer dev → main
    _run("git checkout main && git pull origin main", cwd=OUTER_ROOT)
    _run(f'git merge dev -m "Release v{new_version}: merge dev → main"', cwd=OUTER_ROOT)
    _run("git push origin main", cwd=OUTER_ROOT)

    # Fast-forward dev to main in both repos so dev is up to date for future work
    _run("git checkout dev && git merge main --ff-only && git push origin dev", cwd=SUBMODULE_ABS)
    _run("git checkout dev && git merge main --ff-only && git push origin dev", cwd=OUTER_ROOT)

    return ActivityResult(
        success=True,
        output=f"Phase 2 complete. Both repos released on main at v{new_version}. dev fast-forwarded.",
    )


# --- Codex Release ---


@activity.defn
def codex_release() -> ActivityResult:
    """Copy plugin to openai-plugins fork and create/update PR."""
    import tempfile

    tmpdir = Path(tempfile.mkdtemp())
    activity.logger.info(f"Codex release working dir: {tmpdir}")

    try:
        clone_dir = tmpdir / "openai-plugins"

        # Clone fork
        try:
            _run(
                f"gh repo clone {CODEX_FORK} {clone_dir} -- --single-branch --branch {CODEX_BRANCH}",
            )
        except RuntimeError:
            activity.logger.info(f"Branch '{CODEX_BRANCH}' doesn't exist, cloning default branch")
            _run(f"gh repo clone {CODEX_FORK} {clone_dir}")
            _run(f"git checkout -b {CODEX_BRANCH}", cwd=clone_dir)

        # Sync with upstream
        upstream_check = subprocess.run(
            "git remote get-url upstream", shell=True, capture_output=True, cwd=clone_dir
        )
        if upstream_check.returncode != 0:
            _run(f"git remote add upstream https://github.com/{CODEX_UPSTREAM}.git", cwd=clone_dir)

        _run("git fetch upstream main", cwd=clone_dir)
        _run("git rebase upstream/main", cwd=clone_dir)

        # Copy plugin directory
        dest = clone_dir / "plugins" / "temporal-developer"
        if dest.exists():
            shutil.rmtree(dest)

        src = OUTER_ROOT / "plugins" / "temporal-developer"

        # Use shutil with ignore for .claude-plugin
        shutil.copytree(
            src, dest,
            ignore=shutil.ignore_patterns(".claude-plugin", ".git"),
        )

        # Expand submodule — replace the (possibly empty) gitlink with actual content
        submod_dest = dest / "skills" / "temporal-developer"
        if submod_dest.exists():
            shutil.rmtree(submod_dest)
        shutil.copytree(
            SUBMODULE_ABS, submod_dest,
            ignore=shutil.ignore_patterns(".git"),
        )

        # Stage and commit
        _run("git add -A", cwd=clone_dir)
        diff_check = subprocess.run(
            "git diff --cached --quiet", shell=True, cwd=clone_dir
        )
        if diff_check.returncode == 0:
            return ActivityResult(success=True, output="No changes — Codex plugin already up to date.")

        version = _current_version()
        _run(f'git commit -m "Update temporal-developer plugin to v{version}"', cwd=clone_dir)
        _run(f"git push -u origin {CODEX_BRANCH} --force-with-lease", cwd=clone_dir)

        # Check for existing PR
        existing = subprocess.run(
            f'gh pr list --repo {CODEX_UPSTREAM} --head "temporalio:{CODEX_BRANCH}" --json number --jq ".[0].number"',
            shell=True, capture_output=True, text=True, cwd=clone_dir,
        )
        existing_num = existing.stdout.strip()

        if existing_num and existing_num != "null":
            pr_url = f"https://github.com/{CODEX_UPSTREAM}/pull/{existing_num}"
            return ActivityResult(success=True, pr_url=pr_url, output=f"Existing PR updated: {pr_url}")

        pr_result = _run(
            f'gh pr create --repo {CODEX_UPSTREAM} --base main --head "temporalio:{CODEX_BRANCH}" '
            f'--title "Add temporal-developer plugin" '
            f'--body "Adds the temporal-developer plugin for Temporal application development across Python, TypeScript, and Go."',
            cwd=clone_dir,
        )
        pr_url = pr_result.stdout.strip()
        return ActivityResult(success=True, pr_url=pr_url, output=f"PR created: {pr_url}")

    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)
