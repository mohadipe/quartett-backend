#!/usr/bin/env bash
# =============================================================================
# 🧪 Production Smoke Test Runner
# =============================================================================
# Story: STORY-010D / Issue #14
# Führt die Validierung der Produktions-Datenbank (quartett-prod)
# oder der lokalen Testinstanz durch.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$REPO_ROOT"

TARGET_ENV="${1:-${DEPLOY_ENV:-local}}"

echo "======================================================================"
echo "🧪 Starte Production Smoke Test (Ziel: $TARGET_ENV)..."
echo "======================================================================"

ARGS=()
if [ "$TARGET_ENV" = "production" ] || [ "$TARGET_ENV" = "prod" ]; then
    if [ -n "${SUPABASE_PROJECT_REF_PROD:-}" ]; then
        CLEAN_REF=$(echo "$SUPABASE_PROJECT_REF_PROD" | tr -d '[:space:]"' | sed -E 's#^https?://##' | sed -E 's#\.supabase\.(co|in).*##' | tr -d '/')
        ARGS+=("--project-ref" "$CLEAN_REF")
    else
        ARGS+=("--linked")
    fi
elif [ "$TARGET_ENV" = "staging" ] || [ "$TARGET_ENV" = "stage" ]; then
    if [ -n "${SUPABASE_PROJECT_REF_STAGING:-}" ]; then
        CLEAN_REF=$(echo "$SUPABASE_PROJECT_REF_STAGING" | tr -d '[:space:]"' | sed -E 's#^https?://##' | sed -E 's#\.supabase\.(co|in).*##' | tr -d '/')
        ARGS+=("--project-ref" "$CLEAN_REF")
    else
        ARGS+=("--linked")
    fi
else
    ARGS+=("--local")
fi

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    # Wenn in GitHub Actions, erzeuge zusätzlich Markdown für Step Summary
    python3 "$SCRIPT_DIR/smoke_test_production.py" "${ARGS[@]}" --markdown >> "$GITHUB_STEP_SUMMARY"
fi

python3 "$SCRIPT_DIR/smoke_test_production.py" "${ARGS[@]}"
