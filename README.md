# ☁️ quartett-backend

Backend- und Cloud-Infrastruktur Repository für die **Quartett & Supertrumpf App** (Supabase, PostgreSQL, Row Level Security, Realtime & Edge Functions).

---

## 🏛️ Architektur-Dokumentation
* 🔗 **[arc42 Architekturdokumentation (Kapitel 05 & 07)](https://github.com/mohadipe/quartett-project-repo/tree/main/docs/arc42)**
* 🔗 **[Sicherheit & RLS-Konzepte](https://github.com/mohadipe/quartett-project-repo/tree/main/docs/arc42/08_crosscutting_concepts/security_and_rls.md)**
* 🔗 **[Test-Strategie & CI/CD](https://github.com/mohadipe/quartett-project-repo/tree/main/docs/arc42/08_crosscutting_concepts/testing_and_ci_cd.md)**

---

## 🗄️ Struktur

```
quartett-backend/
├── .github/workflows/
│   ├── backend_ci.yml        # Automatisierte pgTAP Tests bei Pull Request & Push
│   ├── deploy_backend.yml    # CI/CD Deployment-Pipeline für Staging & Production
│   └── release_backend.yml   # Automatisierte Versionierung & Release-Pipeline
├── scripts/
│   ├── generate_backend_summary.sh     # RLS & Testabdeckungs-Report
│   └── generate_release_changelog.py   # SemVer Bumping & Conventional Changelog Generator
├── tests/
│   ├── test_deploy_backend_workflow.py    # Testsuite für die CI/CD Pipeline
│   ├── test_generate_release_changelog.py # Testsuite für Versionierung & Changelog
│   └── test_release_backend_workflow.py   # Testsuite für den Release-Workflow
└── supabase/
    ├── config.toml           # Supabase CLI Konfiguration
    ├── migrations/           # SQL Tabellen, RLS Policies & RPC Funktionen
    │   ├── 20260819000001_initial_schema.sql
    │   ├── 20260819000002_rls_policies.sql
    │   └── 20260819000003_game_functions.sql
    ├── tests/database/       # pgTAP SQL Test-Suites
    │   ├── 01_rls_security_test.sql
    │   ├── 02_triggers_and_rpc_test.sql
    │   └── 04_official_decks_and_seeds_test.sql
    ├── functions/            # Edge Functions (IAP Belegprüfung & Matchmaking)
    └── seed.sql              # Initialer Decks- und Karten-Katalog
```

---

## 🚀 Lokale Entwicklung mit Supabase CLI

### 1. Lokale Docker-Instanz starten:
```bash
npx supabase start
```

### 2. Automatisierte Tests ausführen (pgTAP):
```bash
npx supabase test db
```

### 3. Migrationen anwenden & Seed-Daten laden:
```bash
npx supabase db reset
```

---

## 🚀 Automatisierte CI/CD Deployment-Pipeline (`deploy_backend.yml`)

Das Backend wird über GitHub Actions vollautomatisiert und unabhängig vom Frontend deployt:

### 🟡 Staging (`quartett-stage`)
* **Trigger:** Automatischer Push auf den `main`-Branch ODER manueller Start via `workflow_dispatch` mit Umgebung `staging`.
* **Ablauf:**
  1. Supabase CLI Setup & Container-Start.
  2. Ausführung der vollständigen pgTAP-Testsuite (`supabase test db`).
  3. Verifikation der RLS-Sicherheitsabdeckung.
  4. Bei erfolgreichen Tests: Automatisches Aufspielen aller Migrationen via `supabase db push --project-ref $SUPABASE_PROJECT_REF_STAGING`.
  5. Step Summary im GitHub Actions Run mit Status der angewendeten Migrationen.

### 🔴 Production (`quartett-prod`)
* **Trigger:** Git-Tag `backend-v*` (z. B. `backend-v0.2.0`) ODER manueller Start via `workflow_dispatch` mit Umgebung `production`.
* **Ablauf:**
  1. Supabase CLI Setup & Container-Start.
  2. Ausführung der vollständigen pgTAP-Testsuite (`supabase test db`).
  3. **Automatisiertes Backup:** Vollständiger Schema- & Daten-Dump der Produktionsdatenbank vor Anwendung jeglicher Migrationen.
  4. **Artifact-Archivierung:** Speicherung des Backups als GitHub Actions Run Artifact mit 90 Tagen Aufbewahrungsdauer.
  5. **Sicheres Deployment:** Aufspielen aller offenen Migrationen via `supabase db push --project-ref $SUPABASE_PROJECT_REF_PROD`.
  6. Detaillierte Step Summary mit Backup- und Migrationsstatus.

### 🚀 Automatisierter Release- & Versionierungs-Workflow (`release_backend.yml`)

Für Backend-Releases steht ein dedizierter GitHub Actions Workflow zur Verfügung, der Releases semantisch versioniert, Release Notes generiert, Git-Tags setzt und nahtlos das Production Deployment anstößt:

* **Trigger:** Manueller Start via `workflow_dispatch` auf `main`.
* **Parameter:**
  - `bump_type`: Versionssprung (`patch`, `minor`, `major`, `auto` [Conventional Commits Erkennung], `custom`).
  - `custom_version`: Spezifische Zielversion (falls `bump_type = custom`).
  - `custom_notes`: Optionale individuelle Release Notes.
  - `trigger_deploy`: Automatisches Anstoßen von `deploy_backend.yml` auf Production (Standard: `true`).
* **Ablauf:**
  1. **Safety Gate:** Ausführung der pgTAP-Datenbanktests (`supabase test db`) und Python-Workflow-Tests (`python3 -m unittest discover tests`).
  2. **SemVer Bumping:** Ermittlung des letzten Tags (`backend-v*`) und Berechnung der neuen Version (`0.9.1`, `0.10.0`, etc.).
  3. **Changelog & Release Notes:** Automatisierte Kategorisierung von Commits nach Conventional Commits (Datenbank, Edge Functions, RLS, Features, Fixes) und Auflistung geänderter Migrationsdateien.
  4. **Git Tagging:** Erstellung und Push des annotierten Tags `backend-vX.Y.Z`.
  5. **GitHub Release:** Veröffentlichung des offiziellen GitHub Releases mit Changelog.
  6. **Production Deployment Trigger:** Automatisches Triggern der `deploy_backend.yml` Pipeline für das neue Tag mit `environment=production`.

### 🔐 Erforderliche GitHub Secrets & Variablen
| Secret / Variable | Beschreibung |
| :--- | :--- |
| `SUPABASE_ACCESS_TOKEN` | Supabase Personal Access Token für die CLI |
| `SUPABASE_PROJECT_REF_STAGING` | Projekt-Referenz-ID für Staging (`quartett-stage`) |
| `SUPABASE_DB_PASSWORD_STAGING` | Datenbankpasswort für die Staging-Instanz |
| `SUPABASE_PROJECT_REF_PROD` | Projekt-Referenz-ID für Production (`quartett-prod`) |
| `SUPABASE_DB_PASSWORD_PROD` | Datenbankpasswort für die Production-Instanz |
