#!/usr/bin/env bash
# Automatischer Schnell-Check für RLS-Aktivierung in Supabase SQL-Migrationen

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
MIGRATIONS_DIR="$REPO_DIR/supabase/migrations"

echo "=== 🛡️ Supabase RLS & Migration Security Audit ==="
echo "Untersuche Migrationen in: $MIGRATIONS_DIR"

TABLES_CREATED=$(grep -h -i "CREATE TABLE" "$MIGRATIONS_DIR"/*.sql | sed -E 's/.*CREATE TABLE (IF NOT EXISTS )?public\.([a-zA-Z0-9_]+).*/\2/i' | sort -u)
RLS_ENABLED=$(grep -h -i "ENABLE ROW LEVEL SECURITY" "$MIGRATIONS_DIR"/*.sql | sed -E 's/.*ALTER TABLE (IF EXISTS )?public\.([a-zA-Z0-9_]+) ENABLE ROW LEVEL SECURITY.*/\2/i' | sort -u)

MISSING_RLS=0

echo ""
echo "Gefundene Tabellen und RLS-Status:"
for tbl in $TABLES_CREATED; do
    if echo "$RLS_ENABLED" | grep -qx "$tbl"; then
        echo "  ✅ public.$tbl -> RLS ist AKTIV"
    else
        echo "  ❌ public.$tbl -> WARNUNG: Kein 'ENABLE ROW LEVEL SECURITY' gefunden!"
        MISSING_RLS=$((MISSING_RLS + 1))
    fi
done

echo ""
if [ $MISSING_RLS -eq 0 ]; then
    echo "🎉 Perfekt: Alle $TABLES_CREATED Tabellen sind mit Row Level Security (RLS) geschützt!"
    exit 0
else
    echo "⚠️ FEHLER: $MISSING_RLS Tabelle(n) ohne explizite RLS gefunden!"
    exit 1
fi
