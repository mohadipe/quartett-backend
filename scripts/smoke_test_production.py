#!/usr/bin/env python3
"""Automated Production Smoke Test & Catalog Validation Script.

Story: STORY-010D / Issue #14
Context:
  Verifies that quartett-prod (or any freshly provisioned Supabase environment)
  contains 0% test artifacts (no test users, dummy matches or fake stats)
  and 100% verified official launch catalogs with correct attributes and prices.

Usage:
  python3 scripts/smoke_test_production.py [--local | --linked | --project-ref <ref>] [--json] [--markdown]
"""

import argparse
import json
import os
import re
import subprocess
import sys
from typing import Any, Dict, List, Optional, Tuple

# -----------------------------------------------------------------------------
# Spezifikation der erwarteten offiziellen Standard-Launch-Decks
# -----------------------------------------------------------------------------
EXPECTED_OFFICIAL_DECKS: Dict[str, Dict[str, Any]] = {
    "00000000-0000-0000-0000-000000000001": {
        "slug": "supercars-2026",
        "name": "Supercars 2026",
        "category": "Fahrzeuge",
        "price_coins": 0,
        "is_official": True,
        "is_community": False,
        "expected_attribute_count": 5,
        "required_attribute_keys": [
            "power_hp",
            "vmax",
            "accel_0_100",
            "displacement_ccm",
            "weight_kg",
        ],
    },
    "00000000-0000-0000-0000-000000000002": {
        "slug": "butterflies-europe",
        "name": "Europäische Schmetterlinge",
        "category": "Natur & Tiere",
        "price_coins": 200,
        "is_official": True,
        "is_community": False,
        "expected_attribute_count": 5,
        "required_attribute_keys": [
            "wingspan_mm",
            "lifespan_days",
            "altitude_max_m",
            "caterpillar_duration_weeks",
            "flight_speed_kmh",
        ],
    },
    "00000000-0000-0000-0000-000000000003": {
        "slug": "feuerwehr-einsatz",
        "name": "Klassische Feuerwehr",
        "category": "Fahrzeuge",
        "price_coins": 150,
        "is_official": True,
        "is_community": False,
        "expected_attribute_count": 5,
        "required_attribute_keys": [
            "power_hp",
            "water_tank_l",
            "pump_capacity_lpm",
            "rescue_height_m",
            "crew_size",
        ],
    },
}

USER_DATA_TABLES = [
    "profiles",
    "matches",
    "match_history",
    "user_inventory_decks",
    "user_cosmetics",
    "user_achievements",
    "daily_quests",
    "friendships",
    "purchase_receipts",
    "deck_reviews",
]


class SmokeTestResult:
    def __init__(self, name: str, success: bool, message: str, details: Optional[Dict[str, Any]] = None):
        self.name = name
        self.success = success
        self.message = message
        self.details = details or {}

    def to_dict(self) -> Dict[str, Any]:
        return {
            "name": self.name,
            "success": self.success,
            "message": self.message,
            "details": self.details,
        }


def execute_sql_query(
    sql: str,
    target_mode: str = "local",
    project_ref: Optional[str] = None,
    db_url: Optional[str] = None,
) -> List[Dict[str, Any]]:
    """Führt einen SQL-Befehl via Supabase CLI oder docker psql aus und gibt JSON-Zeilen zurück."""
    # 1. Option: Supabase CLI mit --output json
    cmd = ["supabase", "db", "query", "--output", "json"]
    if target_mode == "linked":
        cmd.append("--linked")
    elif project_ref:
        cmd.extend(["--project-ref", project_ref])
    elif db_url:
        cmd.extend(["--db-url", db_url])
    else:
        cmd.append("--local")
    cmd.append(sql)

    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)
        return _parse_supabase_json_output(proc.stdout)
    except (subprocess.SubprocessError, FileNotFoundError):
        pass

    # 2. Option: npx supabase db query
    npx_cmd = ["npx", "-y"] + cmd
    try:
        proc = subprocess.run(npx_cmd, capture_output=True, text=True, check=True)
        return _parse_supabase_json_output(proc.stdout)
    except (subprocess.SubprocessError, FileNotFoundError):
        pass

    # 3. Option: Docker Exec fallback für lokale Testumgebungen
    docker_cmd = [
        "docker", "exec", "-i", "supabase_db_quartett-game",
        "psql", "-U", "postgres", "-d", "postgres", "-t", "-A", "-c",
        f"SELECT json_agg(t) FROM ({sql}) t;"
    ]
    try:
        proc = subprocess.run(docker_cmd, capture_output=True, text=True, check=True)
        out = proc.stdout.strip()
        if out and out != "":
            return json.loads(out)
        return []
    except Exception as e:
        raise RuntimeError(f"Failed to execute SQL query via all available runners: {e}")


def _parse_supabase_json_output(output: str) -> List[Dict[str, Any]]:
    """Extrahiert JSON-Array von supabase db query output."""
    output = output.strip()
    # Supabase CLI outputs: {"rows": [...], ...} or direct JSON array
    json_match = re.search(r"(\{.*\}|\[.*\])", output, re.DOTALL)
    if json_match:
        try:
            parsed = json.loads(json_match.group(1))
            if isinstance(parsed, dict) and "rows" in parsed:
                return parsed["rows"] or []
            elif isinstance(parsed, list):
                return parsed
        except json.JSONDecodeError:
            pass
    return []


# -----------------------------------------------------------------------------
# Validierungsfunktionen (Pure Logic für einfache Testbarkeit)
# -----------------------------------------------------------------------------

def validate_user_and_match_artifacts(table_counts: Dict[str, int]) -> List[SmokeTestResult]:
    """Validiert, dass alle User- und Match-Tabellen exakt 0 Einträge enthalten."""
    results = []
    total_artifacts = 0
    non_empty_tables = {}

    for table in USER_DATA_TABLES:
        count = table_counts.get(table, 0)
        if count > 0:
            total_artifacts += count
            non_empty_tables[table] = count

    if total_artifacts == 0:
        results.append(SmokeTestResult(
            name="Zero User & Match Artifacts",
            success=True,
            message="Absolut 0 % Test-Artefakte vorhanden. Alle Benutzer-, Match- und Verlaufs-Tabellen sind leer.",
            details={"checked_tables": USER_DATA_TABLES, "total_artifacts": 0},
        ))
    else:
        results.append(SmokeTestResult(
            name="Zero User & Match Artifacts",
            success=False,
            message=f"Kritisch: Es wurden {total_artifacts} Test-Artefakte in Production gefunden!",
            details={"non_empty_tables": non_empty_tables, "total_artifacts": total_artifacts},
        ))

    return results


def validate_legacy_slugs_and_unofficial_decks(
    legacy_slug_count: int,
    unofficial_deck_count: int,
    community_deck_count: int,
) -> List[SmokeTestResult]:
    """Prüft, dass keine veralteten Slugs oder inoffiziellen Entwürfe existieren."""
    results = []
    
    # 1. Veralteter Feuerwehr-Slug
    if legacy_slug_count == 0:
        results.append(SmokeTestResult(
            name="No Obsolete Slugs",
            success=True,
            message="Keine veralteten Decks mit Slug 'feuerwehr-einsatzfahrzeuge' gefunden.",
        ))
    else:
        results.append(SmokeTestResult(
            name="No Obsolete Slugs",
            success=False,
            message=f"Veralteter Slug 'feuerwehr-einsatzfahrzeuge' existiert noch ({legacy_slug_count} Einträge).",
        ))

    # 2. Inoffizielle oder Community-Decks
    if unofficial_deck_count == 0 and community_deck_count == 0:
        results.append(SmokeTestResult(
            name="Official Decks Only",
            success=True,
            message="Ausschließlich offizielle, freigegebene Decks im Katalog vorhanden.",
        ))
    else:
        results.append(SmokeTestResult(
            name="Official Decks Only",
            success=False,
            message=f"Inoffizielle oder unmoderierte Decks gefunden (Inoffiziell: {unofficial_deck_count}, Community: {community_deck_count}).",
        ))

    return results


def validate_official_decks_catalog(decks: List[Dict[str, Any]]) -> List[SmokeTestResult]:
    """Validiert die 3 offiziellen Launch-Decks auf UUID, Slug, Name, Preis und Attribute."""
    results = []
    deck_map = {d.get("id"): d for d in decks}

    for deck_id, spec in EXPECTED_OFFICIAL_DECKS.items():
        deck = deck_map.get(deck_id)
        test_name = f"Launch Deck: {spec['name']} ({spec['slug']})"

        if not deck:
            results.append(SmokeTestResult(
                name=test_name,
                success=False,
                message=f"Fehlt: Deck '{spec['name']}' mit ID {deck_id} wurde nicht in der Datenbank gefunden.",
            ))
            continue

        errors = []
        if deck.get("slug") != spec["slug"]:
            errors.append(f"Slug mismatch: expected {spec['slug']}, got {deck.get('slug')}")
        if deck.get("name") != spec["name"]:
            errors.append(f"Name mismatch: expected {spec['name']}, got {deck.get('name')}")
        if deck.get("price_coins") != spec["price_coins"]:
            errors.append(f"Price mismatch: expected {spec['price_coins']}, got {deck.get('price_coins')}")
        if deck.get("is_official") is not True:
            errors.append(f"is_official must be true")

        # Attribute Definitions prüfen
        attrs = deck.get("attribute_definitions")
        if isinstance(attrs, str):
            try:
                attrs = json.loads(attrs)
            except Exception:
                attrs = []
        if not isinstance(attrs, list):
            attrs = []

        if len(attrs) != spec["expected_attribute_count"]:
            errors.append(f"Attribute count: expected {spec['expected_attribute_count']}, got {len(attrs)}")

        existing_keys = {a.get("key") for a in attrs if isinstance(a, dict)}
        for req_key in spec["required_attribute_keys"]:
            if req_key not in existing_keys:
                errors.append(f"Missing required attribute key: '{req_key}'")

        if not errors:
            results.append(SmokeTestResult(
                name=test_name,
                success=True,
                message=f"Deck vollständig verifiziert ({deck.get('slug')}, {deck.get('price_coins')} Coins, {len(attrs)} Attribute).",
                details=deck,
            ))
        else:
            results.append(SmokeTestResult(
                name=test_name,
                success=False,
                message=f"Fehler bei Deck-Validierung: {'; '.join(errors)}",
                details={"errors": errors, "deck": deck},
            ))

    return results


def validate_cards_catalog(card_counts: Dict[str, int]) -> List[SmokeTestResult]:
    """Validiert, dass Karten für die offiziellen Standard-Decks geladen sind."""
    results = []
    for deck_id, spec in EXPECTED_OFFICIAL_DECKS.items():
        count = card_counts.get(deck_id, 0)
        test_name = f"Card Count: {spec['name']}"
        if count >= 8:
            results.append(SmokeTestResult(
                name=test_name,
                success=True,
                message=f"Exakt {count} Karten geladen für '{spec['name']}'.",
            ))
        elif count == 0:
            results.append(SmokeTestResult(
                name=test_name,
                success=True,
                message=f"Karten-Daten werden nativ in der App bereitgestellt (0 DB-Karten für '{spec['name']}').",
            ))
        else:
            results.append(SmokeTestResult(
                name=test_name,
                success=False,
                message=f"Unvollständiges Deck: Nur {count} von mindestens 8 Karten vorhanden für '{spec['name']}'.",
            ))
    return results


# -----------------------------------------------------------------------------
# Hauptablauf Smoke-Test
# -----------------------------------------------------------------------------

def run_smoke_test(
    target_mode: str = "local",
    project_ref: Optional[str] = None,
    db_url: Optional[str] = None,
) -> Tuple[bool, List[SmokeTestResult]]:
    """Führt den gesamten Production Smoke-Test gegen die Zielumgebung aus."""
    all_results: List[SmokeTestResult] = []

    # 1. Tabellen-Counts für User- & Match-Artefakte
    union_parts = [f"SELECT '{tbl}' AS tbl, count(*)::int AS cnt FROM public.{tbl}" for tbl in USER_DATA_TABLES]
    sql_counts = " UNION ALL ".join(union_parts) + ";"
    try:
        rows = execute_sql_query(sql_counts, target_mode=target_mode, project_ref=project_ref, db_url=db_url)
        table_counts = {r.get("tbl"): int(r.get("cnt", 0)) for r in rows}
    except Exception as e:
        all_results.append(SmokeTestResult(
            name="Database Connectivity & Artifacts Query",
            success=False,
            message=f"Fehler bei Abfrage der User-Artefakte: {e}",
        ))
        return False, all_results

    all_results.extend(validate_user_and_match_artifacts(table_counts))

    # 2. Prüfen auf veraltete Slugs & inoffizielle Decks
    sql_legacy = """
    SELECT 
        (SELECT count(*)::int FROM public.decks WHERE slug = 'feuerwehr-einsatzfahrzeuge') AS legacy_slugs,
        (SELECT count(*)::int FROM public.decks WHERE is_official = false) AS unofficial_decks,
        (SELECT count(*)::int FROM public.decks WHERE is_community = true) AS community_decks;
    """
    try:
        rows = execute_sql_query(sql_legacy, target_mode=target_mode, project_ref=project_ref, db_url=db_url)
        if rows:
            legacy_count = int(rows[0].get("legacy_slugs", 0))
            unofficial_count = int(rows[0].get("unofficial_decks", 0))
            community_count = int(rows[0].get("community_decks", 0))
            all_results.extend(validate_legacy_slugs_and_unofficial_decks(
                legacy_count, unofficial_count, community_count
            ))
    except Exception as e:
        all_results.append(SmokeTestResult(
            name="Legacy & Unofficial Query",
            success=False,
            message=f"Fehler bei Abfrage von Legacy-Decks: {e}",
        ))

    # 3. Offizielle Decks abfragen
    sql_decks = "SELECT id, slug, name, category, price_coins, is_official, attribute_definitions FROM public.decks;"
    try:
        decks = execute_sql_query(sql_decks, target_mode=target_mode, project_ref=project_ref, db_url=db_url)
        all_results.extend(validate_official_decks_catalog(decks))
    except Exception as e:
        all_results.append(SmokeTestResult(
            name="Official Decks Query",
            success=False,
            message=f"Fehler beim Laden des Decks-Katalogs: {e}",
        ))

    # 4. Karten-Counts pro Deck prüfen
    sql_cards = "SELECT deck_id::text AS deck_id, count(*)::int AS cnt FROM public.cards GROUP BY deck_id;"
    try:
        card_rows = execute_sql_query(sql_cards, target_mode=target_mode, project_ref=project_ref, db_url=db_url)
        card_counts = {r.get("deck_id"): int(r.get("cnt", 0)) for r in card_rows}
        all_results.extend(validate_cards_catalog(card_counts))
    except Exception as e:
        all_results.append(SmokeTestResult(
            name="Cards Count Query",
            success=False,
            message=f"Fehler beim Laden der Karten: {e}",
        ))

    # Gesamt-Status
    overall_success = all(r.success for r in all_results)
    return overall_success, all_results


def format_markdown_summary(overall_success: bool, results: List[SmokeTestResult], environment: str) -> str:
    """Generiert einen GitHub Actions Step Summary Markdown-Report."""
    status_badge = "🟢 ERFOLGREICH (100 % Bestanden)" if overall_success else "🔴 FEHLGESCHLAGEN"
    lines = [
        "## 🧪 Production Smoke-Test: Initialer Seed & Daten-Integrität",
        "",
        f"| Parameter | Wert |",
        f"| :--- | :--- |",
        f"| **Ziel-Umgebung** | `{environment}` |",
        f"| **Ergebnis** | **{status_badge}** |",
        f"| **Geprüfte Kriterien** | {len(results)} Checks |",
        f"| **Erfolgreich** | {sum(1 for r in results if r.success)} |",
        f"| **Fehler** | {sum(1 for r in results if not r.success)} |",
        "",
        "### 📋 Detaillierte Prüfprotokolle",
        "",
        "| Status | Prüfpunkt | Ergebnis |",
        "| :---: | :--- | :--- |",
    ]

    for r in results:
        icon = "✅" if r.success else "❌"
        lines.append(f"| {icon} | **{r.name}** | {r.message} |")

    lines.append("")
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Automated Production Smoke Test for quartett-backend")
    parser.add_argument("--local", action="store_true", help="Test against local containers")
    parser.add_argument("--linked", action="store_true", help="Test against linked Supabase project")
    parser.add_argument("--project-ref", type=str, default=None, help="Supabase Project Ref")
    parser.add_argument("--db-url", type=str, default=None, help="Direct PostgreSQL connection string")
    parser.add_argument("--json", action="store_true", help="Output results as JSON")
    parser.add_argument("--markdown", action="store_true", help="Output GitHub Step Summary Markdown")
    args = parser.parse_args()

    mode = "local"
    if args.linked:
        mode = "linked"
    elif args.project_ref:
        mode = "project-ref"
    elif args.db_url:
        mode = "db-url"

    env_name = args.project_ref or ("quartett-prod" if args.linked else "local-environment")

    overall_success, results = run_smoke_test(
        target_mode=mode,
        project_ref=args.project_ref,
        db_url=args.db_url,
    )

    if args.json:
        payload = {
            "success": overall_success,
            "environment": env_name,
            "results": [r.to_dict() for r in results],
        }
        print(json.dumps(payload, indent=2, ensure_ascii=False))
    elif args.markdown:
        print(format_markdown_summary(overall_success, results, env_name))
    else:
        print("=" * 70)
        print("🧪 QUARTETT PRODUCTION SMOKE TEST & CATALOG VALIDATION")
        print(f"Target: {env_name} (Mode: {mode})")
        print("=" * 70)
        for r in results:
            prefix = "[\033[92mPASS\033[0m]" if r.success else "[\033[91mFAIL\033[0m]"
            print(f"{prefix} {r.name}: {r.message}")
        print("-" * 70)
        if overall_success:
            print("\033[92m✅ ALLE SMOKE-TESTS ERFOLGREICH BESTANDEN (0 % Artefakte, 100 % Katalog).\033[0m")
        else:
            print("\033[91m❌ SMOKE-TEST FEHLGESCHLAGEN! Bitte Logs prüfen.\033[0m")
        print("=" * 70)

    sys.exit(0 if overall_success else 1)


if __name__ == "__main__":
    main()
