# ☁️ quartett-backend

Backend- und Cloud-Infrastruktur Repository für die **Quartett & Supertrumpf App** (Supabase, PostgreSQL, Row Level Security, Realtime & Edge Functions).

---

## 🏛️ Architektur-Dokumentation
* 🔗 **[arc42 Architekturdokumentation (Kapitel 05 & 07)](https://github.com/mohadipe/quartett-project-repo/tree/main/docs/arc42)**
* 🔗 **[Sicherheit & RLS-Konzepte](https://github.com/mohadipe/quartett-project-repo/tree/main/docs/arc42/08_crosscutting_concepts/security_and_rls.md)**

---

## 🗄️ Struktur

```
quartett-backend/
└── supabase/
    ├── config.toml           # Supabase CLI Konfiguration
    ├── migrations/           # SQL Tabellen, RLS Policies & RPC Funktionen
    │   ├── 20260819000001_initial_schema.sql
    │   ├── 20260819000002_rls_policies.sql
    │   └── 20260819000003_game_functions.sql
    ├── functions/            # Edge Functions (IAP Belegprüfung & Matchmaking)
    └── seed.sql              # Initialer Decks- und Karten-Katalog
```

---

## 🚀 Lokale Entwicklung mit Supabase CLI

### 1. Lokale Docker-Instanz starten:
```bash
supabase start
```

### 2. Migrationen anwenden & Seed-Daten laden:
```bash
supabase db reset
```

### 3. Remote Cloud Deployment:
```bash
supabase link --project-ref <your-project-id>
supabase db push
```
