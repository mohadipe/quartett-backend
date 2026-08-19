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
│   └── backend_ci.yml        # Automatisierte pgTAP Tests bei GitHub Push
└── supabase/
    ├── config.toml           # Supabase CLI Konfiguration
    ├── migrations/           # SQL Tabellen, RLS Policies & RPC Funktionen
    │   ├── 20260819000001_initial_schema.sql
    │   ├── 20260819000002_rls_policies.sql
    │   └── 20260819000003_game_functions.sql
    ├── tests/database/       # pgTAP SQL Test-Suites
    │   ├── 01_rls_security_test.sql
    │   └── 02_triggers_and_rpc_test.sql
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

### 4. Remote Cloud Deployment:
```bash
npx supabase link --project-ref <your-project-id>
npx supabase db push
```
