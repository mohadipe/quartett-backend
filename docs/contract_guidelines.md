# Contract-Facade-Layer Richtlinien für Entwickler & KI-Agenten

**Dokument:** `quartett-backend/docs/contract_guidelines.md`  
**Referenz:** [arc42 Kapitel 8.12 (Multi-Stage & Contract-Versioning)](https://github.com/mohadipe/quartett-project-repo/blob/main/docs/arc42/08_crosscutting_concepts/multi_stage_and_environment_strategy.md)  
**Status:** Verbindlicher Standard für `quartett-backend` und `quartett-app`  

---

## 🎯 1. Kontext & Zielsetzung

In der Quartett-Architektur deployt das Backend (`quartett-backend`) binnen Sekunden direkt auf PostgreSQL/Supabase, während das Frontend (`quartett-app`) über den Google Play Store ausgerollt wird und Reviews sowie verzögerte Nutzer-Updates Tage bis Wochen dauern.

Wenn im Backend eine neue Version `B2` ausgerollt wird, befinden sich auf den Geräten der Nutzer noch ältere App-Versionen `F1`. 

> [!IMPORTANT]
> **Das oberste Ziel:** Alte App-Versionen (`F1`) dürfen niemals durch ein Backend-Release (`B2`) abstürzen oder inkompatibel werden.

Zur Entkopplung kommunizieren Frontend und Backend über den **Contract-Facade-Layer**.

---

## 📐 2. Namenskonventionen

### 2.1 Facade-Views (`v1_*`)
Alle Datenbankabfragen (`SELECT`, `INSERT`, `UPDATE`, `DELETE`) der App erfolgen ausschließlich über versionierte Facade-Views:

| Ressourcen-Bereich | Primäre Facade-View | Alias-View (Kompatibilität) | Physische Basistabelle |
| :--- | :--- | :--- | :--- |
| **Spielerprofile** | `public.v1_player_profiles` | `public.v1_profiles` | `public.profiles` |
| **Katalog-Decks** | `public.v1_catalog_decks` | `public.v1_decks` | `public.decks` |
| **Community-Decks (UGC)** | `public.community_decks` | - | `public.decks` |
| **Karten** | `public.v1_cards` | `public.v1_deck_cards` | `public.cards` |
| **Nutzer-Inventar** | `public.v1_user_inventory_decks` | - | `public.user_inventory_decks` |
| **Matches (Lobby/Live)**| `public.v1_matches` | - | `public.matches` |
| **Match-Historie** | `public.v1_match_history` | - | `public.match_history` |
| **Erfolge** | `public.v1_user_achievements` | - | `public.user_achievements` |
| **Kosmetik-Inventar** | `public.v1_user_cosmetics` | - | `public.user_cosmetics` |
| **Deck-Bewertungen** | `public.v1_deck_reviews` | - | `public.deck_reviews` |
| **Tagesaufgaben** | `public.v1_daily_quests` | - | `public.daily_quests` |
| **Freundschaften** | `public.v1_friendships` | - | `public.friendships` |
| **Kaufbelege** | `public.v1_purchase_receipts` | - | `public.purchase_receipts` |
| **App-Versions-Policy** | `public.v1_system_app_policies` | - | `public.system_app_policies` |

### 2.2 Versionierte RPC-Funktionen (`*_v1`)
Alle serverseitigen Stored Procedures tragen ein Versionssuffix `_v1`:

| RPC-Funktion (v1 Standard) | Alias-Wrapper | Beschreibung |
| :--- | :--- | :--- |
| `check_app_version_v1(...)` | `check_app_version` | Prüft Client-Version gegen Policy (Update-Pflicht/Wartung) |
| `health_check_v1()` | `health_check` | Schlanker Healthcheck zur Prüfung von DB-Status & Backend-Version |
| `claim_reward_v1(...)` | `claim_match_reward_v1`, `rpc_claim_match_reward_v1` | Match-Belohnung verbuchen (XP, Level, Coins) |
| `purchase_cosmetic_v1(...)` | `rpc_purchase_cosmetic_v1` | Kosmetik-Gegenstand atomar erwerben |
| `merge_guest_data_v1(...)` | `rpc_merge_guest_data_v1` | Gast-Daten nach Login migrieren |
| `get_or_create_daily_quests_v1(...)`| `rpc_get_or_create_daily_quests_v1` | 3 Quests des Tages laden oder initialisieren |
| `claim_daily_quest_v1(...)` | `rpc_claim_daily_quest_v1` | Einzelne Tagesaufgabe einlösen |
| `claim_daily_bonus_v1(...)` | `rpc_claim_daily_bonus_v1` | Bonus für alle 3 Quests einlösen (+Streak) |
| `join_lobby_v1(...)` | `rpc_join_lobby_v1` | Match-Lobby atomar via Raumcode beitreten |

---

## 🛡️ 3. Verbindliche Regeln für Entwickler & KI-Agenten

### Regel 1: Expand & Contract (Nur additiv erweitern!)
* Physische Tabellen dürfen **nur erweitert** werden (`ADD COLUMN`, neue Tabellen).
* Neue Spalten müssen entweder ein `DEFAULT` besitzen oder `NULL` erlauben.
* Solange ein Vertrag (z. B. `v1`) aktiv ist, dürfen Spalten der physischen Tabelle **niemals gelöscht oder umbenannt** werden.

### Regel 2: Explizite Spaltenauswahl in Facade-Views
* Facade-Views dürfen auf Basistabellen kein `SELECT *` verwenden, wenn sich Spalten ändern können.
* Jede Facade-View definiert ihre Spalten explizit:
  ```sql
  CREATE OR REPLACE VIEW public.v1_player_profiles WITH (security_invoker = true) AS
  SELECT id, username, avatar_url, coins, xp, level, ...
  FROM public.profiles;
  ```
* Wird eine physische Tabelle später um ein Feature `B2` erweitert (`ALTER TABLE profiles ADD COLUMN battle_pass_tier INT;`), bleibt der Vertrag `v1` davon unberührt und liefert weiterhin exakt die von `F1` erwarteten Felder.

### Regel 3: Row Level Security via `security_invoker = true`
* Alle Facade-Views müssen zwingend mit `WITH (security_invoker = true)` erstellt werden.
* Dadurch wertet PostgreSQL die RLS-Policies der zugrunde liegenden physischen Tabellen mit den Rechten des authentifizierten Clients (`auth.uid()`) aus.

### Regel 4: Unversionierte Legacy-Wrapper beibehalten
* Für bestehende Endpunkte bleiben unversionierte Stored Procedures (`rpc_claim_match_reward`, `rpc_purchase_cosmetic` etc.) als Adapter erhalten, die intern auf die Version `_v1` verweisen.

### Regel 5: Testpflicht vor jedem Merge (pgTAP Contract-Regressionstests)
* Jede Änderung am Backend muss durch die pgTAP-Testsuite abgesichert sein.
* Dedizierte Contract-Regressionstests in `supabase/tests/contracts/`:
  1. `test_contract_v1.sql`: Prüft alle 15 Facade-Views, exakten Spaltenprojektionen (`columns_are`), Datentypen (`col_type_is`), 15 versionierten RPC-Funktionen (`has_function`, `function_returns`), `security_invoker=true` und F1-Client Runtime-Interaktionen.
  2. `test_contract_v2.sql`: Prüft additive Schema-Erweiterungen (Expand-Pattern), Multi-Contract Coexistenz (`v1` + `v2` parallel) sowie **Negativ-Tests** (Abweisung von Pflichtfeldern ohne Default via 23502, Postgres-Blockade von DROP COLUMN via 2BP01 und ALTER TYPE via 0A000, Typvalidierung via 22P02, lückenlose RLS-Absicherung).
* **100 % aller pgTAP-Tests müssen lokal und in der GitHub Actions CI (PR, Staging- und Production-Deploy) grün sein!**

---

## 🚪 4. Contract Retirement (Ausmusterung alter Versionen)

1. **Prüfung:** Ein Vertrag `v1` darf erst ausgemustert werden, wenn die minimale unterstützte App-Version im Play Store (`min_supported_version` in `system_app_policies`) den Vertrag `v1` nicht mehr benötigt.
2. **Migration:** Erst danach werden `v1_*`-Views und `*_v1`-Funktionen per regulärer Migration aus der Datenbank entfernt.
