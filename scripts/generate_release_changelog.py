#!/usr/bin/env python3
"""
Automated Release & Changelog Generator for quartett-backend.
Generates semantic versions, conventional changelogs, and release notes for Supabase deployments.
"""

import argparse
import os
import re
import subprocess
import sys
from typing import Dict, List, Optional, Tuple


def run_git(args: List[str]) -> str:
    """Run a git command and return its trimmed stdout."""
    result = subprocess.run(
        ["git"] + args,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=False,
    )
    return result.stdout.strip()


def parse_version(version_str: str) -> Tuple[int, int, int]:
    """
    Parse a semantic version string (e.g., '0.9.0', 'backend-v0.9.0', 'v1.2.3').
    Returns (major, minor, patch).
    """
    cleaned = re.sub(r"^(backend-)?v", "", version_str.strip())
    match = re.match(r"^(\d+)\.(\d+)\.(\d+)$", cleaned)
    if not match:
        raise ValueError(f"Invalid semantic version string: '{version_str}'")
    return int(match.group(1)), int(match.group(2)), int(match.group(3))


def bump_version(
    current: str,
    bump_type: str,
    custom_version: str = "",
    commits: Optional[List[str]] = None,
) -> str:
    """
    Calculate the next version string based on bump_type:
    'patch', 'minor', 'major', 'custom', or 'auto'.
    """
    if bump_type == "custom":
        if not custom_version:
            raise ValueError("custom_version must be provided when bump_type is 'custom'")
        major, minor, patch = parse_version(custom_version)
        return f"{major}.{minor}.{patch}"

    if bump_type == "auto":
        bump_type = detect_conventional_bump(commits or [])

    major, minor, patch = parse_version(current)

    if bump_type == "patch":
        patch += 1
    elif bump_type == "minor":
        minor += 1
        patch = 0
    elif bump_type == "major":
        major += 1
        minor = 0
        patch = 0
    else:
        raise ValueError(f"Unknown bump_type: '{bump_type}'")

    return f"{major}.{minor}.{patch}"


def detect_conventional_bump(commits: List[str]) -> str:
    """
    Analyze conventional commit messages to determine bump type:
    - BREAKING CHANGE or '!:' -> major
    - 'feat...' -> minor
    - otherwise -> patch
    """
    has_breaking = False
    has_feat = False

    for commit in commits:
        if not commit.strip():
            continue
        # Check for breaking changes in subject or body
        if "BREAKING CHANGE" in commit or re.search(r"^[a-zA-Z]+(\([^\)]+\))?!:", commit):
            has_breaking = True
            break

        # Check for features
        if re.match(r"^feat(\([^\)]+\))?:", commit.strip(), re.IGNORECASE):
            has_feat = True

    if has_breaking:
        return "major"
    if has_feat:
        return "minor"
    return "patch"


def get_previous_tag(pattern: str = "backend-v*") -> str:
    """Find the latest git tag matching pattern."""
    output = run_git(["tag", "--list", pattern, "--sort=-v:refname"])
    lines = [line.strip() for line in output.splitlines() if line.strip()]
    if lines:
        return lines[0]
    return ""


def get_commits_since(since_tag: str = "") -> List[str]:
    """Retrieve non-merge git commits since tag (or last 30 commits)."""
    git_args = ["log", "--no-merges", "--pretty=format:%s (%h)"]
    if since_tag:
        git_args.append(f"{since_tag}..HEAD")
    else:
        git_args.extend(["-n", "30"])

    output = run_git(git_args)
    if not output:
        return []
    return [line.strip() for line in output.splitlines() if line.strip()]


def get_changed_migrations(since_tag: str = "") -> List[str]:
    """Return list of new or modified SQL migration files since tag."""
    git_args = ["diff", "--name-only"]
    if since_tag:
        git_args.append(f"{since_tag}..HEAD")
    else:
        git_args.extend(["HEAD~10", "HEAD"])
    git_args.extend(["--", "supabase/migrations"])

    output = run_git(git_args)
    if not output:
        return []
    return [line.strip() for line in output.splitlines() if line.strip().endswith(".sql")]


def categorize_commits(commits: List[str]) -> Dict[str, List[str]]:
    """Categorize commit messages by scope and type."""
    categories: Dict[str, List[str]] = {
        "🗄️ Database & Schema": [],
        "⚡ Edge Functions & APIs": [],
        "🔒 Security & RLS": [],
        "🚀 Features & Enhancements": [],
        "🐛 Bug Fixes": [],
        "🧪 Tests & Qualitätssicherung": [],
        "🔧 CI/CD & Maintenance": [],
        "📚 Dokumentation": [],
        "📌 Sonstiges": [],
    }

    for line in commits:
        line = line.strip()
        if not line or "[skip ci]" in line or "chore(release):" in line:
            continue

        lower = line.lower()

        # Tests
        if lower.startswith("test"):
            categories["🧪 Tests & Qualitätssicherung"].append(line)
        # Database & Schema
        elif any(kw in lower for kw in ["(db)", "db:", "schema:", "migration:", "postgres", "table"]):
            categories["🗄️ Database & Schema"].append(line)
        # Edge Functions
        elif any(kw in lower for kw in ["(fn)", "(function)", "edge function", "matchmaking", "functions/"]):
            categories["⚡ Edge Functions & APIs"].append(line)
        # Security & RLS
        elif any(kw in lower for kw in ["(rls)", "(security)", "rls:", "security:", "policy"]):
            categories["🔒 Security & RLS"].append(line)
        # Features
        elif lower.startswith("feat"):
            categories["🚀 Features & Enhancements"].append(line)
        # Fixes
        elif lower.startswith("fix"):
            categories["🐛 Bug Fixes"].append(line)
        # Documentation
        elif lower.startswith("docs") or "doku" in lower:
            categories["📚 Dokumentation"].append(line)
        # Maintenance & CI
        elif any(lower.startswith(prefix) for prefix in ["chore", "ci", "refactor", "perf", "build"]):
            categories["🔧 CI/CD & Maintenance"].append(line)
        else:
            categories["📌 Sonstiges"].append(line)

    return {k: v for k, v in categories.items() if v}


def generate_changelog_markdown(
    version: str,
    commits: List[str],
    custom_notes: str = "",
    changed_migrations: Optional[List[str]] = None,
    prev_tag: str = "",
) -> str:
    """Generate markdown changelog for the backend release."""
    tag_name = f"backend-v{version}"
    cat_commits = categorize_commits(commits)

    md = [f"## 🚀 quartett-backend Release `{tag_name}`\n"]

    if prev_tag:
        md.append(f"**Vergleich:** `{prev_tag}` ➔ `{tag_name}`\n")

    if custom_notes.strip():
        md.append(f"### 💡 Release Notes\n{custom_notes.strip()}\n")

    if changed_migrations:
        md.append("### 🗄️ Enthaltene Datenbank-Migrationen")
        for mig in changed_migrations:
            base_mig = os.path.basename(mig)
            md.append(f"- `{base_mig}`")
        md.append("")

    if cat_commits:
        md.append("### 📋 Änderungen in dieser Version\n")
        for category, items in cat_commits.items():
            md.append(f"#### {category}")
            for item in items:
                md.append(f"- {item}")
            md.append("")
    else:
        md.append("### 📋 Änderungen\n- Allgemeine Performance-Verbesserungen und Backend-Optimierungen.\n")

    md.append("---")
    md.append("### 🚀 Deployment-Informationen")
    md.append("- **Deployment Pipeline:** Wird automatisch via `deploy_backend.yml` auf Production (`quartett-prod`) aufgespielt.")
    md.append("- **Sicherheits-Check:** Automatischer Schema- & Daten-Backup vor Ausführung der Migrationen.")

    return "\n".join(md)


def main():
    parser = argparse.ArgumentParser(description="Backend Release & Changelog Tool")
    subparsers = parser.add_subparsers(dest="subcommand", required=True)

    # Subcommand: bump
    bump_parser = subparsers.add_parser("bump", help="Calculate next version and tag")
    bump_parser.add_argument("--current-tag", default="", help="Current tag (e.g. backend-v0.9.0)")
    bump_parser.add_argument("--bump-type", choices=["patch", "minor", "major", "auto", "custom"], default="patch")
    bump_parser.add_argument("--custom-version", default="", help="Custom target version (e.g. 1.0.0)")

    # Subcommand: changelog
    ch_parser = subparsers.add_parser("changelog", help="Generate release changelog markdown")
    ch_parser.add_argument("--version", required=True, help="New version (e.g. 0.9.1)")
    ch_parser.add_argument("--custom-notes", default="", help="Optional release notes")
    ch_parser.add_argument("--prev-tag", default="", help="Previous tag")
    ch_parser.add_argument("--output", default="", help="File path to write markdown to")

    args = parser.parse_args()

    if args.subcommand == "bump":
        current_tag = args.current_tag or get_previous_tag()
        if not current_tag:
            current_tag = "backend-v0.9.0"

        commits = get_commits_since(current_tag)
        new_version = bump_version(
            current=current_tag,
            bump_type=args.bump_type,
            custom_version=args.custom_version,
            commits=commits,
        )
        new_tag = f"backend-v{new_version}"

        print(f"prev_tag={current_tag}")
        print(f"new_version={new_version}")
        print(f"new_tag={new_tag}")

        # If running inside GitHub Actions, populate $GITHUB_OUTPUT
        gh_output = os.environ.get("GITHUB_OUTPUT")
        if gh_output and os.path.isfile(gh_output):
            with open(gh_output, "a", encoding="utf-8") as f:
                f.write(f"prev_tag={current_tag}\n")
                f.write(f"new_version={new_version}\n")
                f.write(f"new_tag={new_tag}\n")

    elif args.subcommand == "changelog":
        prev_tag = args.prev_tag or get_previous_tag()
        commits = get_commits_since(prev_tag)
        migrations = get_changed_migrations(prev_tag)
        markdown = generate_changelog_markdown(
            version=args.version,
            commits=commits,
            custom_notes=args.custom_notes,
            changed_migrations=migrations,
            prev_tag=prev_tag,
        )

        if args.output:
            with open(args.output, "w", encoding="utf-8") as f:
                f.write(markdown)
            print(f"Changelog written to {args.output}")
        else:
            print(markdown)


if __name__ == "__main__":
    main()
