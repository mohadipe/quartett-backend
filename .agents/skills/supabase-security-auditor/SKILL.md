---
name: supabase-security-auditor
description: >-
  Führt automatisierte Sicherheits-, RLS- und pgTAP-Prüfungen für das Supabase PostgreSQL Backend durch.
  Verwende diesen Skill immer, wenn SQL-Migrationen geändert, neue Datenbanktabellen angelegt,
  RLS-Policies geprüft oder Backend-Sicherheitstests in quartett-backend ausgeführt werden.
---

# 🛡️ Supabase Security & RLS Auditor Skill

Dieser Skill stellt sicher, dass alle PostgreSQL-Tabellen, Stored Procedures (RPC) und Sicherheitsrichtlinien im `quartett-backend` den höchsten Sicherheitsstandards genügen und keine Datenlecks zulassen.

---

## 🔍 1. Die 4 Pflicht-Prüfpunkte (Security Matrix)

Bei jedem Audit werden 4 Sicherheitsbereiche überprüft:

1. **Row Level Security (RLS) Pflicht:**
   - Jede Tabelle im Schema `public` MUSS explizit mit `ALTER TABLE public.<tabelle> ENABLE ROW LEVEL SECURITY;` abgesichert sein.
   - Es darf keine Tabelle ohne RLS geben.
2. **Mandantentrennung & Gast-Account Isolation:**
   - Tabellen mit personenbezogenen Daten (`profiles`, `user_inventory_decks`, `purchase_receipts`, `match_history`) müssen Policies haben, die Schreib- und Lesezugriffe strikt auf `auth.uid() = user_id` beschränken.
3. **Sichere Stored Procedures (`SECURITY DEFINER`):**
   - Funktionen, die als `SECURITY DEFINER` laufen (z. B. `rpc_claim_match_reward`, `rpc_claim_iap_purchase`), müssen:
     - Zu Beginn prüfen: `IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Nicht authentifiziert'; END IF;`
     - Ausschließlich `auth.uid()` als Identifikator verwenden (niemals eine vom Client übergebene User-ID ungeprüft als Zielkonto akzeptieren!).
4. **Lückenlose pgTAP-Testabdeckung:**
   - Jede neue Tabelle, RLS-Policy und Stored Procedure muss in `supabase/tests/database/` durch automatisierte pgTAP-Tests abgedeckt sein.

---

## 🛠️ 2. Ausführungs-Workflow

1. **Automatischer RLS-Check:**
   Führe das Skript aus:
   ```bash
   bash .agents/skills/supabase-security-auditor/scripts/audit_rls.sh
   ```
2. **Lokale pgTAP-Testsuite ausführen:**
   ```bash
   npx supabase test db
   ```
3. **Audit-Report generieren:**
   Erstelle einen kompakten Statusbericht über geschützte Tabellen, aktive Policies und bestandene Tests.
